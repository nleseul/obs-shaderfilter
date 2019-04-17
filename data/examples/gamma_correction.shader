uniform float Red = 2.2;
uniform float Green= 2.2;
uniform float Blue = 2.2;
uniform string notes = "Modify Colors to correct for gamma, use equal values for general correction."

float4 mainImage(VertData v_in) : TARGET
{  
	float3 gammaRGB = float3(clamp(Red,0.1,10.0),clamp(Green,0.1,10.0),clamp(Blue,0.1,10.0));
	float4 color = image.Sample(textureSampler, v_in.uv);
	if (v_in.uv.x<0.50)
	{
		color.rgb = pow(color.rgb, 1.0 / gammaRGB);
	}
	return color;
}