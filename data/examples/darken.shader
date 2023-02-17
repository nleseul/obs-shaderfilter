uniform float Opacity_Percentage = 100.0;
uniform float Fill_Percentage = 100.0;
uniform string Notes = "Simulates a photo editing darken layer blending mode. Fill percentage is the interior alpha and Opacity is the layer alpha.";

float4 mainImage(VertData v_in) : TARGET
{
	float4 other = { 1.0, 1.0, 1.0, 1.0 };
	float4 base = image.Sample(textureSampler, v_in.uv);
	float luminance = dot(color, float3(0.299, 0.587, 0.114));
	float4 gray = { luminance,luminance,luminance, 1 };

	return min(base,other);
}
