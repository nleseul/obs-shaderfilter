uniform float Alpha = 100.0;
uniform float Amount = 0.05;
uniform float Scale = 5.1;
uniform float Offset = 1.0;
uniform string notes = "Change Offset, Scale and Amount";

float rand(vec2 co)
{
	float2 v1 = float2(92.,80.);
	float2 v2 = float2(41.,62.);
	return fract(sin(dot(co.xy ,v1)) + cos(dot(co.xy ,v2)) * Scale);
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
