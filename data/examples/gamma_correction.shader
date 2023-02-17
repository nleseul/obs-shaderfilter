// Gamma Correction shader by Charles Fettinger for obs-shaderfilter plugin 4/2019
//https://github.com/Oncorporation/obs-shaderfilter

uniform float Red = 2.2;
uniform float Green= 2.2;
uniform float Blue = 2.2;
uniform string notes = "Modify Colors to correct for gamma, use equal values for general correction."

float4 mainImage(VertData v_in) : TARGET
{  
	float3 gammaRGB = float3(clamp(Red,0.1,10.0),clamp(Green,0.1,10.0),clamp(Blue,0.1,10.0));
	float4 color = image.Sample(textureSampler, v_in.uv);
		color.rgb = pow(color.rgb, 1.0 / gammaRGB);	
	return color;
}