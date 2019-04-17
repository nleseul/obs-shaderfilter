uniform float4x4 ViewProj;
uniform texture2d image;

uniform float elapsed_time;
uniform float2 uv_offset;
uniform float2 uv_scale;
uniform float2 uv_pixel_interval;
uniform float rand_f;
uniform float2 uv_size;

uniform float Alpha = 100.0;
uniform float Amount = 0.05;
uniform float Scale = 5.1;
uniform float Offset = 1.0;
uniform string notes = "Change Offset, Scale and Amount";

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

float rand(vec2 co)
{
	float2 v1 = float2(92.,80.);
	float2 v2 = float2(41.,62.);
	return fract(sin(dot(co.xy ,v1)) + cos(dot(co.xy ,v2)) * Scale);
}

VertData mainTransform(VertData v_in)
{
	VertData vert_out;
	vert_out.pos = mul(float4(v_in.pos.xyz, 1.0), ViewProj);
	vert_out.uv  = v_in.uv * uv_scale + uv_offset;
	return vert_out;
}

float4 mainImage(VertData v_in) : TARGET
{

	float3 tc = float3(1.0,0,0);
	
	if (v_in.uv.x < (Offset + 0.005))
	{
		//float2 rand = float2(rand(v_in.uv.yx),rand(v_in.uv.yx));
		//tc = image.Sample(textureSampler, v_in.uv + (rand*Amount)).rgb;
		tc = image.Sample(textureSampler, v_in.uv + (rand_f*Amount*Scale)).rgb;
	}
	else
	{
		tc = image.Sample(textureSampler, v_in.uv).rgb;
	}
	return float4(tc,(Alpha * 0.01));
}

technique Draw
{
	pass
	{
		vertex_shader = mainTransform(v_in);
		pixel_shader  = mainImage(v_in);
	}
}