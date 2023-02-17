uniform float speed = 0.5;

float4 mainImage(VertData v_in) : TARGET
{
	float4 color = image.Sample(textureSampler, v_in.uv);
	float t = elapsed_time * speed;
	return float4(color.r, color.g, color.b, color.a * (1 + sin(t)) / 2);
}
