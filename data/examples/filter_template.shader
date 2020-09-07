//My shader modified by Me for use with obs-shaderfilter month/year v.02

//Section to converting GLSL to HLSL - can delete if unneeded
#define vec2 float2
#define vec3 float3
#define vec4 float4
#define ivec2 int2
#define ivec3 int3
#define ivec4 int4
#define mat2 float2x2
#define mat3 float3x3
#define mat4 float4x4
#define fract frac
#define mix lerp
#define iTime elapsed_time
#define iResolution uv_scale

/*
**Shaders have these variables pre loaded by the plugin**
**this section can be deleted**

struct VertData {
	float4 pos : POSITION;
	float2 uv  : TEXCOORD0;
};

uniform float4x4 ViewProj;
uniform texture2d image;

uniform float elapsed_time;
uniform float2 uv_offset;
uniform float2 uv_scale;
uniform float2 uv_pixel_interval;
uniform float2 uv_size;
uniform float rand_f;
uniform float rand_instance_f;
uniform float rand_activation_f;
uniform int loops;
uniform float local_time;
*/
uniform string notes = "add notes here";


float4 mainImage(VertData v_in) : TARGET
{
	return image.Sample(textureSampler, v_in.uv);
}

/*
**Shaders use the built in Draw technique**
**this section can be deleted**

technique Draw
{
	pass
	{
		vertex_shader = mainTransform(v_in);
		pixel_shader  = mainImage(v_in);
	}
}
*/
