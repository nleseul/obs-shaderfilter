// Drunk shader by Charles Fettinger  (https://github.com/Oncorporation)  2/2019
uniform float4x4 color_matrix;


uniform int glow_percent = 10;
uniform int blur = 1;
uniform int min_brightness= 27;
uniform int max_brightness = 100;
uniform int pulse_speed_percent = 0;
uniform bool Apply_To_Alpha_Layer = true;
uniform float4 glow_color;
uniform bool ease;
uniform bool glitch;
uniform string notes ="'drunk refers to the bad blur effect of using 4 coordinates to blur. 'blur' - the distance between the 4 copies (recommend 1-4)";


// Gaussian Blur
float Gaussian(float x, float o) {
	const float pivalue = 3.1415926535897932384626433832795;
	return (1.0 / (o * sqrt(2.0 * pivalue))) * exp((-(x * x)) / (2 * (o * o)));
}


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

float4 InternalGaussianPrecalculated(float2 p_uv, float2 p_uvStep, int p_radius,
  texture2d p_image, float2 p_imageTexel,
  texture2d p_kernel, float2 p_kernelTexel) {
	float4 l_value = p_image.Sample(pointClampSampler, p_uv)
		* kernel.Sample(pointClampSampler, float2(0, 0)).r;
	float2 l_uvoffset = float2(0, 0);
	for (int k = 1; k <= p_radius; k++) {
		l_uvoffset += p_uvStep;
		float l_g = p_kernel.Sample(pointClampSampler, p_kernelTexel * k).r;
		float4 l_p = p_image.Sample(pointClampSampler, p_uv + l_uvoffset) * l_g;
		float4 l_n = p_image.Sample(pointClampSampler, p_uv - l_uvoffset) * l_g;
		l_value += l_p + l_n;
	}
	return l_value;
}

float4 mainImage(VertData v_in) : TARGET
{
	const float2 offsets[4] = 
	{
		-0.05,  0.066,
		-0.05, -0.066,
		0.05, -0.066,
		0.05,  0.066
	};

	// convert input for vector math
	float blur_amount = (float)blur /100;
	float glow_amount = (float)glow_percent * 0.1;
	float speed = (float)pulse_speed_percent * 0.01;	
	float luminance_floor = float(min_brightness) * 0.01;
	float luminance_ceiling = float(max_brightness) * 0.01;

	float4 color = image.Sample(textureSampler, v_in.uv);
	float4 temp_color = color;
	bool glitch_on = glitch;

	//circular easing variable
	float t = 1 + sin(elapsed_time * speed);
	float b = 0.0; //start value
	float c = 2.0; //change value
	float d = 2.0; //duration

	//if(color.a <= 0.0) color.rgb = float3(0.0,0.0,0.0);
	float4 glitch_color = glow_color;

	for (int n = 0; n < 4; n++){			
		//blur sample
		b = BlurStyler(t,0,c,d,ease);
		float4 ncolor = image.Sample(textureSampler, v_in.uv + (blur_amount * b) * offsets[n]) ;

		//test for rand_f color
		if (glitch) {			
			glitch_color = float4(glow_color.rgb * rand_f,glow_color.a);
			if ((color.r == rand_f) || (color.g == rand_f) || (color.b == rand_f))
			{
				glitch_on = true;
			}			
		}	

		float intensity = dot(ncolor * 1 ,float3(0.299,0.587,0.114));
		if (((intensity >= luminance_floor) && (intensity <= luminance_ceiling)) || // test luminance
			((color.r == glow_color.r) && (color.g == glow_color.g) && (color.b == glow_color.b)) || //test for chosen color
			glitch_on) //test for rand color
		{
			//glow calc
			if (ncolor.a > 0.0  || Apply_To_Alpha_Layer == false)
			{
				ncolor.a = clamp(ncolor.a * glow_amount, 0.0, 1.0);
				//temp_color = max(temp_color,ncolor) * glow_color ;//* ((1-ncolor.a) + color * ncolor.a);
				//temp_color += (ncolor * float4(glow_color.rbg, glow_amount));

				// use temp_color as floor, add glow, use highest alpha of blur pixels, then multiply by glow color
				// max is used to simulate addition of vector texture color
				temp_color = float4(max(temp_color.rgb, ncolor.rgb * (glow_amount * (b / 2))),  // color effected by glow over time
					max(temp_color.a, (glow_amount * (b / 2))))  // alpha affected by glow over time
					* (glitch_color * (b / 2)); // glow color affected by glow over time
			}
		}
	}
	// grab lighter color
	return max(color,temp_color);
}

