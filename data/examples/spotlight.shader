// Spotlight By Charles Fettinger (https://github.com/Oncorporation)  4/2019
uniform float Speed_Percent = 100.0; 
uniform float Focus_Percent = 15.0;
uniform bool Glitch;
uniform float4 Spotlight_Color;
uniform float Horizontal_Offset = 0.0;
uniform float Vertical_Offset = -0.5;
uniform string Notes = "use negative Focus Percent to create a shade effect, speed zero is a stationary spotlight";

float4 mainImage(VertData v_in) : TARGET
{
	float speed = Speed_Percent * 0.01;
	float focus = Focus_Percent;
	if (Glitch)
	{
		speed *= ((rand_f * 2) - 1) * 0.01;
		focus *= ((rand_f * 1.1) - 0.1);
	}

	float PI = 3.1415926535897932384626433832795;//acos(-1);
	float4 c0 = image.Sample( textureSampler, v_in.uv);
	float3 lightsrc = float3(sin(elapsed_time * speed * PI * 0.667) *.5 + .5 + Horizontal_Offset, cos(elapsed_time * speed * PI) *.5 + .5 + Vertical_Offset, 1);
	float3 light = normalize(lightsrc - float3( v_in.uv.x + (Horizontal_Offset * speed),  v_in.uv.y + (Vertical_Offset * speed), 0));
	c0 *= pow(dot(light, float3(0, 0, 1)), focus) * Spotlight_Color;

	return c0;
}