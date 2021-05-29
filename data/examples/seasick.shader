// Seasick - an effect for OBS Studio
//
uniform string notes = "Seasick - from the game Snavenger\n\n(available on Google Play/Amazon Fire)";
uniform float amplitude = 0.03;
uniform float speed = 1.0;
uniform float frequency = 6.0;
uniform float opacity = 0.5;

float4 mainImage(VertData v_in) : TARGET
{
	float2 pulse = sin(elapsed_time*speed - frequency * v_in.uv);
	float2 coord = v_in.uv + amplitude * float2(pulse.x, -pulse.y);
	return image.Sample(textureSampler, coord) * opacity;
}
