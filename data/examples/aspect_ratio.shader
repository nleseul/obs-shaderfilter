uniform float4x4 ViewProj;
uniform texture2d image;

uniform float elapsed_time;
uniform float2 uv_offset;
uniform float2 uv_scale;
uniform float2 uv_pixel_interval;
uniform float rand_f;
uniform float2 uv_size;


// variables
uniform float4 borderColor = 00000000;
float targetaspect = 16.0f / 9.0f;
uniform string notes;

sampler_state textureSampler {
	Filter    = Linear;
	AddressU  = Border;
	AddressV  = Border;
	BorderColor = 00000000;
};

struct VertData {
	float4 pos : POSITION;
	float2 uv  : TEXCOORD0;
};

VertData mainTransform(VertData v_in)
{
	VertData vert_out;
	
	vert_out.pos = mul(float4(v_in.pos.xyz, 1.0), ViewProj);
	vert_out.uv  = v_in.uv * uv_scale + uv_offset;

	float2 hw = uv_scale;
	// determine the game window's current aspect ratio
	float windowaspect = hw.h / hw.w;

	// current viewport height should be scaled by this amount
	float scaleheight = windowaspect / targetaspect;


	// if scaled height is less than current height, add letterbox
	if (scaleheight < 1.0f)
	{
		Rect rect = camera.rect;

		rect.width = 1.0f;
		rect.height = scaleheight;
		rect.x = 0;
		rect.y = (1.0f - scaleheight) / 2.0f;

		camera.rect = rect;
	}
	else // add pillarbox
	{
		float scalewidth = 1.0f / scaleheight;

		Rect rect = camera.rect;

		rect.width = scalewidth;
		rect.height = 1.0f;
		rect.x = (1.0f - scalewidth) / 2.0f;
		rect.y = 0;

		camera.rect = rect;
	}
	return vert_out;
}

float4 mainImage(VertData v_in) : TARGET
{
	if (v_in.uv.x < 0 || v_in.uv.x > 1 || v_in.uv.y < 0 || v_in.uv.y > 1)
	{
		return borderColor;
	}
	else
	{
		return image.Sample(textureSampler, v_in.uv);
	}
}

technique Draw
{
	pass
	{
		vertex_shader = mainTransform(v_in);
		pixel_shader  = mainImage(v_in);
	}
}
