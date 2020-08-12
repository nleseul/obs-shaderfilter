// RGB Color Wheel shader by Charles Fettinger for obs-shaderfilter plugin 5/2020
// https://github.com/Oncorporation/obs-shaderfilter
uniform float speed = 2.0;
uniform float color_depth = 2.10;
uniform bool Apply_To_Image;
uniform bool Replace_Image_Color;
uniform bool Apply_To_Specific_Color;
uniform float4 Color_To_Replace;
uniform float Alpha_Percentage = 100; //<Range(0.0,100.0)>
uniform int center_width_percentage = 50;
uniform int center_height_percentage = 50;
uniform string notes = "add notes here";

float3 hsv2rgb(float3 c)
{
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
}

float4 mainImage(VertData v_in) : TARGET
{
	const float PI = 3.14159265f;//acos(-1);
	float PI180th = 0.0174532925; //PI divided by 180
	float4 rgba = image.Sample(textureSampler, v_in.uv);
	float2 center_pixel_coordinates = float2(((float)center_width_percentage * 0.01), ((float)center_height_percentage * 0.01) );
	float2 st = v_in.uv* uv_scale;
	float2 toCenter = center_pixel_coordinates - st ;
	float r = length(toCenter) * color_depth;
	float angle = atan2(toCenter.y ,toCenter.x );
	float angleMod = (elapsed_time * speed % 18) / 18;

	rgba.rgb = hsv2rgb(float3((angle / PI*0.5) + angleMod,r,1.0));

    float4 color;
    float4 original_color;
	if (Apply_To_Image)
	{
		color = image.Sample(textureSampler, v_in.uv);
		original_color = color;
		float4 luma = dot(color,float4(0.30, 0.59, 0.11, 1.0));
		if (Replace_Image_Color)
			color = luma;
		rgba = lerp(original_color, rgba * color,clamp(Alpha_Percentage *.01 ,0,1.0));
		
	}
    if (Apply_To_Specific_Color)
    {
        color = image.Sample(textureSampler, v_in.uv);
        original_color = color;
        color = (distance(color.rgb, Color_To_Replace.rgb) <= 0.075) ? rgba : color;
        rgba = lerp(original_color, color, clamp(Alpha_Percentage * .01, 0, 1.0));
    }

	return rgba;
}