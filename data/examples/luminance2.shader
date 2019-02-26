// Luminance Filter 2 by Charles Fettinger (https://github.com/Oncorporation)
// added intended options from code that was added to OBS Studio
uniform float4 color;
uniform float lumaMax;
uniform float lumaMin;
uniform float lumaMaxSmooth;
uniform float lumaMinSmooth;
uniform bool invertImageColor;
uniform bool invertAlphaChannel;

float4 InvertColor(float4 rgba_in)
{	
	rgba_in.r = 1.0 - rgba_in.r;
	rgba_in.g = 1.0 - rgba_in.g;
	rgba_in.b = 1.0 - rgba_in.b;
	rgba_in.a = 1.0 - rgba_in.a;
	return rgba_in;
}

float4 mainImage(VertData v_in) : TARGET
{

	float4 rgba = image.Sample(textureSampler, v_in.uv);
	if (invertImageColor)
	{
		rgba = InvertColor(rgba);
	}
	float luminance = dot(rgba * color ,float3(0.299,0.587,0.114));

	//intensity = min(max(intensity,minIntensity),maxIntensity);
	float clo = smoothstep(lumaMin, lumaMin + lumaMinSmooth, luminance);
	float chi = 1. - smoothstep(lumaMax - lumaMaxSmooth, lumaMax, luminance);

	float amask = clo * chi;

	if (invertAlphaChannel)
	{
		amask = 1.0 - amask;
	}	
	rgba *= color;
	rgba.a = clamp(amask,0.0,1.0);
	return rgba;
}
