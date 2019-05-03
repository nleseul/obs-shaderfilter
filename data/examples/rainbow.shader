// Rainbow shader by Charles Fettinger for obs-shaderfilter plugin 3/2019
// https://github.com/Oncorporation/obs-shaderfilter
uniform float Saturation = 0.8; //<Range(0.0, 1.0)>
uniform float Luminosity = 0.5; //<Range(0.0, 1.0)>
uniform float Spread = 3.8; //<Range(0.5, 10.0)>
uniform float Speed = 2.4; //<Range(-10.0, 10.0)>
uniform float Alpha_Percentage = 100; //<Range(0.0,100.0)>
uniform bool Vertical;
uniform bool Rotational;
uniform float Rotation_Offset = 0.0; //<Range(0.0, 6.28318531)>
uniform bool Apply_To_Image;
uniform bool Replace_Image_Color;
uniform string Notes = "Spread is wideness of color and is limited between .25 and 10. Edit at your own risk";

float hueToRGB(float v1, float v2, float vH) {
	vH = frac(vH);
	if ((6.0 * vH) < 1.0) return (v1 + (v2 - v1) * 6.0 * vH);
	if ((2.0 * vH) < 1.0) return (v2);
	if ((3.0 * vH) < 2.0) return (v1 + (v2 - v1) * ((0.6666666666666667) - vH) * 6.0);
	return clamp(v1, 0.0, 1.0);
}

float4 HSLtoRGB(float4 hsl) {
	float4 rgb = float4(0.0, 0.0, 0.0, hsl.w);
	float v1 = 0.0;
	float v2 = 0.0;
	
	if (hsl.y == 0) {
		rgb.xyz = hsl.zzz;
	}
	else {
		
		if (hsl.z < 0.5) {
			v2 = hsl.z * (1 + hsl.y);
		}
		else {
			v2 = (hsl.z + hsl.y) - (hsl.y * hsl.z);
		}
		
		v1 = 2.0 * hsl.z - v2;
		
		rgb.x = hueToRGB(v1, v2, hsl.x + (0.3333333333333333));
		rgb.y = hueToRGB(v1, v2, hsl.x);
		rgb.z = hueToRGB(v1, v2, hsl.x - (0.3333333333333333));
		
	}
	
	return rgb;
}

float4 mainImage(VertData v_in) : TARGET
{
	float2 lPos = (v_in.uv * uv_scale + uv_offset)/ clamp(Spread, 0.25, 10.0);
	float time = (elapsed_time * clamp(Speed, -5.0, 5.0)) / clamp(Spread, 0.25, 10.0);	

	//set colors and direction
	float hue = (-1 * lPos.x) / 2.0;

	if (Rotational && (Vertical == false))
	{
		float timeWithOffset = time + Rotation_Offset;
		float sine = sin(timeWithOffset);
		float cosine = cos(timeWithOffset);
		hue = (lPos.x * cosine + lPos.y * sine) * 0.5;
	}

	if (Vertical && (Rotational == false))
	{
		hue = (-1 * lPos.y) * 0.5;
	}	

	hue += time;
	hue = frac(hue);
	float4 hsl = float4(hue, clamp(Saturation, 0.0, 1.0), clamp(Luminosity, 0.0, 1.0), 1.0);
	float4 rgba = HSLtoRGB(hsl);
	
	if (Apply_To_Image)
	{
		float4 color = image.Sample(textureSampler, v_in.uv);
		float4 original_color = color;
		float4 luma = dot(color,float4(0.30, 0.59, 0.11, 1.0));
		if (Replace_Image_Color)
			color = luma;
		rgba = lerp(original_color, rgba * color,clamp(Alpha_Percentage *.01 ,0,1.0));
		
	}
	return rgba;
}
