uniform int glow_percent = 10;
uniform int blur = 1;
uniform int min_brightness= 27;
uniform int max_brightness = 100;
uniform int pulse_speed = 0;
uniform bool ease;
uniform string notes = "'ease' - makes the animation pause at the begin and end for a moment,'glow_percent' - how much brightness to add (recommend 0-100). 'blur' - how far should the glow extend (recommend 1-4).'pulse_speed' - (0-100). 'min/max brightness' - floor and ceiling brightness level to target for glows.";


float EaseInOutCircTimer(float t,float b,float c,float d){
	t /= d/2;
	if (t < 1) return -c/2 * (sqrt(1 - t*t) - 1) + b;
	t -= 2;
	return c/2 * (sqrt(1 - t*t) + 1) + b;	
}

float BlurStyler(float t,float b,float c,float d,bool ease)
{
	if (ease) return EaseInOutCircTimer(t,0,c,d);
	return t;
}

float4 mainImage(VertData v_in) : TARGET
{
	const float2 offsets[4] = 
	{
		-0.1,  0.125,
		-0.1, -0.125,
		0.1, -0.125,
		0.1,  0.125
	};

	// convert input for vector math
	float4 color = image.Sample(textureSampler, v_in.uv);
	float blur_amount = (float)blur /100;
	float glow_amount = (float)glow_percent * 0.01;
	float speed = (float)pulse_speed * 0.01;	
	float luminance_floor = float(min_brightness) /100;
	float luminance_ceiling = float(max_brightness) /100;

	if (color.a > 0.0)
	{
		//circular easing variable
		float t = 1 + sin(elapsed_time * speed);
		float b = 0.0; //start value
		float c = 2.0; //change value
		float d = 2.0; //duration

		// simple glow calc
		for (int n = 0; n < 4; n++) {
			b = BlurStyler(t, 0, c, d, ease);
			float4 ncolor = image.Sample(textureSampler, v_in.uv + (blur_amount * b) * offsets[n]);
			float intensity = dot(ncolor * 1, float3(0.299, 0.587, 0.114));
			if ((intensity >= luminance_floor) && (intensity <= luminance_ceiling))
			{
				ncolor.a = clamp(ncolor.a * glow_amount, 0.0, 1.0);
				color += (ncolor * (glow_amount * b));
			}
		}
	}
	return color;

}
