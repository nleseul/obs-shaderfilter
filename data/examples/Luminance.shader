uniform float4 color;
uniform float level;
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
	float intensity = dot(rgba * color ,float3(0.299,0.587,0.114));

	//intensity = min(max(intensity,minIntensity),maxIntensity);


	if (invertAlphaChannel)
	{
		intensity = 1.0 - intensity;
	}	
	rgba *= color;
	rgba.a = clamp((intensity * level),0.0,1.0);
	return rgba;
}