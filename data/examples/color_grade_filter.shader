// Color Grade Filter by Charles Fettinger for obs-shaderfilter plugin 4/2020
//https://github.com/Oncorporation/obs-shaderfilter
//OBS messed up the LUT system, this is basically the old LUT system

uniform string notes = "Choose LUT, Default LUT amount is 100, scale = 100, offset = 0. Valid values: -200 to 200";

uniform texture2d lut;
uniform int lut_amount_percent = 100;
uniform int lut_scale_percent = 100;
uniform int lut_offset_percent = 0;


float4 mainImage(VertData v_in) : TARGET
{
	float lut_amount = clamp((float)lut_amount_percent *.01, -2.0, 2.0);
	float lut_scale = clamp((float)lut_scale_percent *.01,-2.0, 2.0);
	float lut_offset = clamp((float)lut_offset_percent *.01,-2.0, 2.0);

	float4 textureColor = image.Sample(textureSampler, v_in.uv);
	const float3 coefLuma = float3(0.2126, 0.7152, 0.0722);
	float lumaLevel = dot(coefLuma, textureColor);
	float blueColor = lumaLevel;//textureColor.b * 63.0;

	float2 quad1;
	quad1.y = floor(floor(blueColor) / 8.0);
	quad1.x = floor(blueColor) - (quad1.y * 8.0);

	float2 quad2;
	quad2.y = floor(ceil(blueColor) / 8.0);
	quad2.x = ceil(blueColor) - (quad2.y * 8.0);

	float2 texPos1;
	texPos1.x = (quad1.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
	texPos1.y = (quad1.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);

	float2 texPos2;
	texPos2.x = (quad2.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
	texPos2.y = (quad2.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);

	float4 newColor1 = lut.Sample(textureSampler, texPos1);
	newColor1.rgb = newColor1.rgb * lut_scale + lut_offset;
	float4 newColor2 = lut.Sample(textureSampler, texPos2);
	newColor2.rgb = newColor2.rgb * lut_scale + lut_offset;
	float4 luttedColor = lerp(newColor1, newColor2, frac(blueColor));

	float4 final_color = lerp(textureColor, luttedColor, lut_amount);
	return float4(final_color.rgb, textureColor.a);
}