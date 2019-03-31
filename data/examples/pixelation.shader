// pixelation shader by Charles Fettinger for obs-shaderfilter plugin 3/2019
// https://github.com/Oncorporation/obs-shaderfilter
uniform float targetWidth = 320;

float4 mainImage(VertData v_in) : TARGET
{
	const float PI = 3.14159265f;//acos(-1);
	float2 tex1;
	int pixelSize = uv_size.x / targetWidth;

	int pixelX = v_in.uv.x * uv_size.x;
	int pixelY = v_in.uv.y * uv_size.y;

	tex1.x = ((pixelX / pixelSize)*pixelSize) / uv_size.x;
	tex1.y = ((pixelY / pixelSize)*pixelSize) / uv_size.y;

	float4 c1 = image.Sample(textureSampler, tex1);

	return c1;
}