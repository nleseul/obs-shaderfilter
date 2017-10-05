#include <obs-module.h>
#include <graphics/graphics.h>
#include <graphics/image-file.h>
#include <util/base.h>
#include <util/dstr.h>
#include <util/platform.h>

#include <float.h>
#include <limits.h>
#include <stdio.h>

static const char *effect_template_begin =
"\
uniform float4x4 ViewProj;\
uniform texture2d image;\
\
uniform float2 uv_offset;\
uniform float2 uv_scale;\
uniform float2 uv_pixel_interval;\
\
sampler_state textureSampler{\
	Filter = Linear;\
	AddressU = Border;\
	AddressV = Border;\
	BorderColor = 00000000;\
};\
\
struct VertData {\
	float4 pos : POSITION;\
	float2 uv : TEXCOORD0;\
};\
\
VertData mainTransform(VertData v_in)\
{\
	VertData vert_out;\
	vert_out.pos = mul(float4(v_in.pos.xyz, 1.0), ViewProj);\
	vert_out.uv = v_in.uv * uv_scale + uv_offset;\
	return vert_out;\
}\
\
";

static const char *effect_template_default_image_shader =
"\r\
float4 mainImage(VertData v_in) : TARGET\r\
{\r\
	return image.Sample(textureSampler, v_in.uv);\r\
}\r\
";

static const char *effect_template_end =
"\
technique Draw\
{\
	pass\
	{\
		vertex_shader = mainTransform(v_in);\
		pixel_shader = mainImage(v_in);\
	}\
}";

struct effect_param_data
{
	struct dstr name;
	enum gs_shader_param_type type;
	gs_eparam_t *param;

	gs_image_file_t *image;

	union
	{
		long long i;
		double f;
	} value;
};

struct shader_filter_data 
{

	obs_source_t *context;
	gs_effect_t *effect;

	gs_eparam_t *param_uv_offset;
	gs_eparam_t *param_uv_scale;
	gs_eparam_t *param_uv_pixel_interval;

	int expand_left;
	int expand_right;
	int expand_top;
	int expand_bottom;

	int total_width;
	int total_height;

	struct vec2 uv_offset;
	struct vec2 uv_scale;
	struct vec2 uv_pixel_interval;

	DARRAY(struct effect_param_data) stored_param_list;
};



static void shader_filter_reload_effect(struct shader_filter_data *filter)
{
	obs_data_t *settings = obs_source_get_settings(filter->context);

	const char *shader_text = NULL;

	if (obs_data_get_bool(settings, "from_file"))
	{
		const char *file_name = obs_data_get_string(settings, "shader_file_name");
		shader_text = os_quick_read_utf8_file(file_name);
	}
	else
	{
		shader_text = bstrdup(obs_data_get_string(settings, "shader_text"));
	}

	if (shader_text == NULL)
	{
		shader_text = "";
	}

	size_t effect_header_length = strlen(effect_template_begin);
	size_t effect_body_length = strlen(shader_text);
	size_t effect_footer_length = strlen(effect_template_end);
	size_t effect_buffer_total_size = effect_header_length + effect_body_length + effect_footer_length;

	if (filter->effect != NULL)
	{
		obs_enter_graphics();
		gs_effect_destroy(filter->effect);
		filter->effect = NULL;
		obs_leave_graphics();
	}

	bool use_template = !obs_data_get_bool(settings, "override_entire_effect");

	struct dstr effect_text = { 0 };

	if (use_template)
	{
		dstr_cat(&effect_text, effect_template_begin);
	}

	dstr_cat(&effect_text, shader_text);

	if (use_template)
	{
		dstr_cat(&effect_text, effect_template_end);
	}

	char *errors = NULL;

	obs_enter_graphics();
	filter->effect = gs_effect_create(effect_text.array, NULL, &errors);
	obs_leave_graphics();

	dstr_free(&effect_text);

	if (filter->effect == NULL)
	{
		blog(LOG_WARNING, "[obs-shaderfilter] Unable to create effect. Errors returned from parser:\n%s", (errors == NULL || strlen(errors) == 0 ? "(None)" : errors));
	}

	size_t param_count = filter->stored_param_list.num;
	for (size_t param_index = 0; param_index < param_count; param_index++)
	{
		struct effect_param_data *param = (filter->stored_param_list.array + param_index);
		if (param->image != NULL)
		{
			obs_enter_graphics();
			gs_image_file_free(param->image);
			obs_leave_graphics();

			bfree(param->image);
			param->image = NULL;
		}
	}

	da_free(filter->stored_param_list);
	da_init(filter->stored_param_list);
	size_t effect_count = gs_effect_get_num_params(filter->effect);
	for (size_t effect_index = 0; effect_index < effect_count; effect_index++)
	{
		gs_eparam_t *param = gs_effect_get_param_by_idx(filter->effect, effect_index);
		struct gs_effect_param_info info;
		gs_effect_get_param_info(param, &info);

		if (strcmp(info.name, "uv_offset") == 0)
		{
			filter->param_uv_offset = param;
		}
		else if (strcmp(info.name, "uv_scale") == 0)
		{
			filter->param_uv_scale = param;
		}
		else if (strcmp(info.name, "uv_pixel_interval") == 0)
		{
			filter->param_uv_pixel_interval = param;
		}
		else if (strcmp(info.name, "ViewProj") == 0 || strcmp(info.name, "image") == 0)
		{
			// Nothing.
		}
		else
		{
			struct effect_param_data *cached_data = da_push_back_new(filter->stored_param_list);
			dstr_copy(&cached_data->name, info.name);
			cached_data->type = info.type;
			cached_data->param = param;
		}
	}
}

static const char *shader_filter_get_name(void *unused)
{
	UNUSED_PARAMETER(unused);
	return obs_module_text("ShaderFilter");
}

static void *shader_filter_create(obs_data_t *settings, obs_source_t *source)
{
	UNUSED_PARAMETER(source);

	struct shader_filter_data *filter = bzalloc(sizeof(struct shader_filter_data));
	filter->context = source;

	da_init(filter->stored_param_list);

	obs_source_update(source, settings);

	shader_filter_reload_effect(filter);

	return filter;
}

static void shader_filter_destroy(void *data)
{
	struct shader_filter_data *filter = data;

	da_free(filter->stored_param_list);

	bfree(filter);
}

static bool shader_filter_from_file_changed(obs_properties_t *props,
	obs_property_t *p, obs_data_t *settings)
{
	bool from_file = obs_data_get_bool(settings, "from_file");

	obs_property_t *shader_text = obs_properties_get(props, "shader_text");
	obs_property_t *shader_file_name = obs_properties_get(props, "shader_file_name");

	obs_property_set_visible(shader_text, !from_file);
	obs_property_set_visible(shader_file_name, from_file);

	return true;
}

static bool shader_filter_reload_effect_clicked(obs_properties_t *props, obs_property_t *property, void *data)
{
	struct shader_filter_data *filter = data;

	shader_filter_reload_effect(filter);
	obs_source_update_properties(filter->context);
	obs_source_update(filter->context, NULL);

	// Note that it's important we not tell the window to refresh with the return
	// value here, as the window will already have been potentially recreated by
	// the update_properties signal sent to it above. 
	return false;
}

static const char *shader_filter_texture_file_filter =
	"Textures (*.bmp *.tga *.png *.jpeg *.jpg *.gif);;";

static obs_properties_t *shader_filter_properties(void *data)
{
	struct shader_filter_data *filter = data;

	struct dstr examples_path = { 0 };
	dstr_init(&examples_path);
	dstr_cat(&examples_path, obs_get_module_data_path(obs_current_module()));
	dstr_cat(&examples_path, "/examples");

	obs_properties_t *props = obs_properties_create();
	obs_properties_add_int(props, "expand_left", 
		obs_module_text("ShaderFilter.ExpandLeft"), 0, 9999, 1);
	obs_properties_add_int(props, "expand_right", 
		obs_module_text("ShaderFilter.ExpandRight"), 0, 9999, 1);
	obs_properties_add_int(props, "expand_top", 
		obs_module_text("ShaderFilter.ExpandTop"), 0, 9999, 1);
	obs_properties_add_int(props, "expand_bottom", 
		obs_module_text("ShaderFilter.ExpandBottom"), 0, 9999, 1);

	obs_properties_add_bool(props, "override_entire_effect",
		obs_module_text("ShaderFilter.OverrideEntireEffect"));

	obs_property_t *from_file = obs_properties_add_bool(props, "from_file",
		obs_module_text("ShaderFilter.LoadFromFile"));
	obs_property_set_modified_callback(from_file, shader_filter_from_file_changed);

	obs_properties_add_text(props, "shader_text", 
		obs_module_text("ShaderFilter.ShaderText"), OBS_TEXT_MULTILINE);

	obs_properties_add_path(props, "shader_file_name", 
		obs_module_text("ShaderFilter.ShaderFileName"), OBS_PATH_FILE, 
		NULL, examples_path.array);

	obs_properties_add_button(props, "reload_effect", obs_module_text("ShaderFilter.ReloadEffect"),
		shader_filter_reload_effect_clicked);

	size_t param_count = filter->stored_param_list.num;
	for (size_t param_index = 0; param_index < param_count; param_index++)
	{
		struct effect_param_data *param = (filter->stored_param_list.array + param_index);
		const char *param_name = param->name.array;

		switch (param->type)
		{
		case GS_SHADER_PARAM_BOOL:
			obs_properties_add_bool(props, param_name, param_name);
			break;
		case GS_SHADER_PARAM_FLOAT:
			obs_properties_add_float(props, param_name, param_name, FLT_MIN, FLT_MAX, 1);
			break;
		case GS_SHADER_PARAM_INT:
			obs_properties_add_int(props, param_name, param_name, INT_MIN, INT_MAX, 1);
			break;
		case GS_SHADER_PARAM_VEC4:
			obs_properties_add_color(props, param_name, param_name);

			// Hack to ensure we have a default...
			obs_data_set_default_int(obs_source_get_settings(filter->context), param_name, 0xff000000);
			break;
		case GS_SHADER_PARAM_TEXTURE:
			obs_properties_add_path(props, param_name, param_name, OBS_PATH_FILE, shader_filter_texture_file_filter, NULL);
			break;
		}
	}

	dstr_free(&examples_path);

	return props;
}

static void shader_filter_update(void *data, obs_data_t *settings)
{
	struct shader_filter_data *filter = data;

	// Get expansions. Will be used in the video_tick() callback.

	filter->expand_left = (int)obs_data_get_int(settings, "expand_left");
	filter->expand_right = (int)obs_data_get_int(settings, "expand_right");
	filter->expand_top = (int)obs_data_get_int(settings, "expand_top");
	filter->expand_bottom = (int)obs_data_get_int(settings, "expand_bottom");

	size_t param_count = filter->stored_param_list.num;
	for (size_t param_index = 0; param_index < param_count; param_index++)
	{
		struct effect_param_data *param = (filter->stored_param_list.array + param_index);
		const char *param_name = param->name.array;

		switch (param->type)
		{
		case GS_SHADER_PARAM_BOOL:
			param->value.i = obs_data_get_bool(settings, param_name);
			break;
		case GS_SHADER_PARAM_FLOAT:
			param->value.f = obs_data_get_double(settings, param_name);
			break;
		case GS_SHADER_PARAM_INT:
		case GS_SHADER_PARAM_VEC4: // Assumed to be a color.
			param->value.i = obs_data_get_int(settings, param_name);
			break;
		case GS_SHADER_PARAM_TEXTURE:
			if (param->image == NULL)
			{
				param->image = bzalloc(sizeof(gs_image_file_t));
			}
			else
			{
				obs_enter_graphics();
				gs_image_file_free(param->image);
				obs_leave_graphics();
			}

			gs_image_file_init(param->image, obs_data_get_string(settings, param_name));

			obs_enter_graphics();
			gs_image_file_init_texture(param->image);
			obs_leave_graphics();
			break;
		}
	}
}

static void shader_filter_tick(void *data, float seconds)
{
	struct shader_filter_data *filter = data;
	obs_source_t *target = obs_filter_get_target(filter->context);

	// Determine offsets from expansion values.
	int base_width = obs_source_get_base_width(target);
	int base_height = obs_source_get_base_height(target);

	filter->total_width = filter->expand_left
		+ base_width
		+ filter->expand_right;
	filter->total_height = filter->expand_top
		+ base_height
		+ filter->expand_bottom;

	filter->uv_scale.x = (float)filter->total_width / base_width;
	filter->uv_scale.y = (float)filter->total_height / base_height;

	filter->uv_offset.x = (float)(-filter->expand_left) / base_width;
	filter->uv_offset.y = (float)(-filter->expand_top) / base_height;

	filter->uv_pixel_interval.x = 1.0f / base_width;
	filter->uv_pixel_interval.y = 1.0f / base_height;

}

static void shader_filter_render(void *data, gs_effect_t *effect)
{
	UNUSED_PARAMETER(effect);

	struct shader_filter_data *filter = data;

	if (filter->effect != NULL)
	{
		if (!obs_source_process_filter_begin(filter->context, GS_RGBA,
			OBS_NO_DIRECT_RENDERING))
		{
			return;
		}

		if (filter->param_uv_scale != NULL)
		{
			gs_effect_set_vec2(filter->param_uv_scale, &filter->uv_scale);
		}
		if (filter->param_uv_offset != NULL)
		{
			gs_effect_set_vec2(filter->param_uv_offset, &filter->uv_offset);
		}
		if (filter->param_uv_pixel_interval != NULL)
		{
			gs_effect_set_vec2(filter->param_uv_pixel_interval, &filter->uv_pixel_interval);
		}

		size_t param_count = filter->stored_param_list.num;
		for (size_t param_index = 0; param_index < param_count; param_index++)
		{
			struct effect_param_data *param = (filter->stored_param_list.array + param_index);
			struct vec4 color;

			switch (param->type)
			{
			case GS_SHADER_PARAM_BOOL:
				gs_effect_set_bool(param->param, param->value.i);
				break;
			case GS_SHADER_PARAM_FLOAT:
				gs_effect_set_float(param->param, (float)param->value.f);
				break;
			case GS_SHADER_PARAM_INT:
				gs_effect_set_int(param->param, (int)param->value.i);
				break;
			case GS_SHADER_PARAM_VEC4:
				vec4_from_rgba(&color, (unsigned int)param->value.i);
				gs_effect_set_vec4(param->param, &color);
				break;
			case GS_SHADER_PARAM_TEXTURE:
				gs_effect_set_texture(param->param, (param->image ? param->image->texture : NULL));
				break;
			}
		}

		obs_source_process_filter_end(filter->context, filter->effect,
			filter->total_width, filter->total_height);
	}

}

static uint32_t shader_filter_getwidth(void *data)
{
	struct shader_filter_data *filter = data;

	return filter->total_width;
}

static uint32_t shader_filter_getheight(void *data)
{
	struct shader_filter_data *filter = data;

	return filter->total_height;
}

static void shader_filter_defaults(obs_data_t *settings)
{
	obs_data_set_default_string(settings, "shader_text", 
		effect_template_default_image_shader);
}

struct obs_source_info shader_filter = {
	.id             = "shader_filter",
	.type           = OBS_SOURCE_TYPE_FILTER,
	.output_flags   = OBS_SOURCE_VIDEO,
	.create         = shader_filter_create,
	.destroy        = shader_filter_destroy,
	.update         = shader_filter_update,
	.video_tick		= shader_filter_tick,
	.get_name       = shader_filter_get_name,
	.get_defaults   = shader_filter_defaults,
	.get_width      = shader_filter_getwidth,
	.get_height     = shader_filter_getheight,
	.video_render   = shader_filter_render,
	.get_properties = shader_filter_properties
};

OBS_DECLARE_MODULE()
OBS_MODULE_USE_DEFAULT_LOCALE("obs-shaderfilter", "en-US")

bool obs_module_load(void)
{
	obs_register_source(&shader_filter);

	return true;
}

void obs_module_unload(void)
{
}
