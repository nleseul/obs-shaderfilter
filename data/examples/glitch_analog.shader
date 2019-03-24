
// analog glitch shader by Charles Fettinger for obs-shaderfilter plugin 3/2019
//https://github.com/Oncorporation/obs-shaderfilter
uniform float scan_line_jitter_displacement; // (displacement, threshold)
uniform int scan_line_jitter_threshold_percent;
uniform float vertical_jump_amount;
uniform float vertical_speed;// (amount, speed)
uniform float horizontal_shake;
uniform float color_drift_amount;
uniform float color_drift_speed;// (amount, speed)
uniform int pulse_speed_percent = 0;
uniform int alpha_percent = 100;
uniform bool rotate_colors;
uniform string notes;


float nrand(float x, float y)
{
	float value = dot(float2(x, y), float2(12.9898 , 78.233 ));
	return frac(sin(value) * 43758.5453);
}

float4 mainImage(VertData v_in) : TARGET
{
	float speed = (float)pulse_speed_percent * 0.01;	
	float alpha = (float)alpha_percent * 0.01;
	float scan_line_jitter_threshold = (float)scan_line_jitter_threshold_percent /100;
	float u = v_in.uv.x;
	float v = v_in.uv.y;
	float t = sin(elapsed_time * speed) * 2 - 1;
	float4 rgba = image.Sample(textureSampler, v_in.uv);

	// Scan line jitter
	float jitter = nrand(v, t) * 2 - 1;
	jitter *= step(scan_line_jitter_threshold, abs(jitter)) * scan_line_jitter_displacement;

	// Vertical jump
	float jump = lerp(v, frac(v +  (t * vertical_speed)), vertical_jump_amount);

	// Horizontal shake
	float shake = ((t * (u + rand_f)/2) - 0.5) * horizontal_shake;

	//// Color drift
	float drift = sin(jump + color_drift_speed) * color_drift_amount;

	float2 src1 = float2(rgba.x, rgba.z) * clamp(frac(float2(u + jitter + shake, jump)), -10.0, 10.0);
	float2 src2 = float2(rgba.y, rgba.w) * frac(float2(u + jitter + shake + drift, jump));
	
	if(rotate_colors)
	{
		src1.x = lerp(src1.x, rgba.x, clamp(1 - sin(elapsed_time * speed),0.0,0.5));
		src2.x = lerp(src2.x, rgba.y, clamp(sin(elapsed_time * speed),0.0,0.5));
		src1.y = lerp(src1.y, rgba.z, clamp(1 - sin(elapsed_time * speed),0.0,0.5));
		
	}

	return float4(src1.x, src2.x, src1.y, alpha);
}