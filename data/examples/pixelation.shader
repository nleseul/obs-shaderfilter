// pixelation shader by Charles Fettinger for obs-shaderfilter plugin 3/2019
// with help from SkeltonBowTV
// https://github.com/Oncorporation/obs-shaderfilter
uniform float Target_Width = 320;
uniform float Target_Height = 180;
uniform string notes = "adjust width and height to your screen dimension";

float4 mainImage(VertData v_in) : TARGET
{
	float targetWidth = max(2.0, Target_Width);
	float targetHeight = max(2.0, Target_Height);
	const float PI = 3.14159265f;//acos(-1);
	float2 tex1;
	int pixelSizeX = uv_size.x / targetWidth;
	int pixelSizeY = uv_size.y / targetHeight;

	int pixelX = v_in.uv.x * uv_size.x;
	int pixelY = v_in.uv.y * uv_size.y;

	tex1.x = (((pixelX / pixelSizeX)*pixelSizeX) / uv_size.x) + (pixelSizeX / uv_size.x)/2;
	tex1.y = (((pixelY / pixelSizeY)*pixelSizeY) / uv_size.y) + (pixelSizeY / uv_size.y)/2;

	float4 c1 = image.Sample(textureSampler, tex1 );

	return c1;
}
