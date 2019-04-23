// Glass shader by Charles Fettinger for obs-shaderfilter plugin 4/2019
//https://github.com/Oncorporation/obs-shaderfilter

uniform float Alpha_Percent = 100.0;
uniform float Offset_Amount = 0.8;
uniform int xSize = 8;
uniform int ySize = 8;
uniform int Reflection_Offset = 2;
uniform bool Horizontal_Border;
uniform float Border_Offset = 0.5;
uniform float4 Border_Color = {.8,.5,1.0,1.0};
uniform float4 Glass_Color;
uniform string notes = "xSize, ySize are for distortion. Offset Amount and Reflection Offset change glass properties. Alpha is Opacity of overlay.";



float4 mainImage(VertData v_in) : TARGET
{
	

	int xSubPixel = (v_in.uv.x * uv_size.x) % clamp(xSize,1,100);
	int ySubPixel = (v_in.uv.y * uv_size.y) % clamp(ySize,1,100);
	float2 offsets = {Offset_Amount * xSubPixel / uv_size.x, Offset_Amount * ySubPixel / uv_size.y};
	float2 uv = v_in.uv + offsets;
	float2 uv2 = {uv.x + (Reflection_Offset / uv_size.x),uv.y + (Reflection_Offset / uv_size.y)};

	float4 rgba = image.Sample(textureSampler, v_in.uv);
	float4 rgba_output = float4(rgba.rgb * Border_Color.rgb, rgba.a);
	rgba = image.Sample(textureSampler, uv);
	float4 rgba_glass = image.Sample(textureSampler, uv2);
	
	float uv_compare = v_in.uv.x;
	if (Horizontal_Border)
		uv_compare = v_in.uv.y;

	if (uv_compare < (Border_Offset - 0.005))
	{
			rgba_output = (rgba + rgba_glass) *.5 * Glass_Color;
	}
	else if (uv_compare >= (Border_Offset + 0.005))
	{
		rgba_output = image.Sample(textureSampler, v_in.uv);
	}
	return lerp(rgba,rgba_output,(Alpha_Percent * 0.01));
}
