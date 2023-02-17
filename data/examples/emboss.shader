// Spotlight By Charles Fettinger (https://github.com/Oncorporation)  4/2019
uniform bool Use_Color;
uniform bool Apply_To_Alpha_Layer = true;

float4 mainImage(VertData v_in) : TARGET
{

	float dx = 1 / uv_size.x;
	float dy = 1 / uv_size.y;

	float4 c0 = image.Sample(textureSampler, v_in.uv);
	if (c0.a > 0.0 || Apply_To_Alpha_Layer == false)
	{
		float4 c1 = image.Sample(textureSampler, v_in.uv + float2(-dx, -dy));
		float4 c2 = image.Sample(textureSampler, v_in.uv + float2(0, -dy));
		float4 c4 = image.Sample(textureSampler, v_in.uv + float2(-dx, 0));
		float4 c6 = image.Sample(textureSampler, v_in.uv + float2(dx, 0));
		float4 c8 = image.Sample(textureSampler, v_in.uv + float2(0, dy));
		float4 c9 = image.Sample(textureSampler, v_in.uv + float2(dx, dy));

		c0 = (-c1 - c2 - c4 + c6 + c8 + c9);
		c0 = (c0.r + c0.g + c0.b) / 3 + 0.5;

		if (Use_Color)
		{
			float4 rgba = image.Sample(textureSampler, v_in.uv);
			return (0.5 * rgba) + c0;
		}
	}
	return c0;
}
