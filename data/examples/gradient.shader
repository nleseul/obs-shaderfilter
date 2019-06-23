// gradient shader by Charles Fettinger for obs-shaderfilter plugin 3/2019
//https://github.com/Oncorporation/obs-shaderfilter
uniform float4 start_color = { 0.1, 0.3, 0.1, 1.0 };
uniform float start_step = 0.15;
uniform float4 middle_color = { 1.0, 1.0, 1.0, 1.0 };
uniform float middle_step = 0.4;
uniform float4 end_color = { 0.75, 0.75, 0.75, 1.0};
uniform float end_step = 0.9;
uniform int alpha_percent = 90;
uniform int pulse_speed = 0;
uniform bool ease;
uniform bool rotate_colors;
uniform bool Apply_To_Alpha_Layer = true;
uniform bool horizontal;
uniform bool vertical;
uniform int gradient_center_width_percentage = 50;
uniform int gradient_center_height_percentage = 50;
uniform string notes = "gradient center items will change the center location. Pulse Speed greater than 0 will animate. Easing seem to be too fast.";

float EaseInOutCircTimer(float t, float b, float c, float d) {
	t /= d / 2;
	if (t < 1) return -c / 2 * (sqrt(1 - t * t) - 1) + b;
	t -= 2;
	return c / 2 * (sqrt(1 - t * t) + 1) + b;
}

float BlurStyler(float t, float b, float c, float d, bool ease)
{
	if (ease) return EaseInOutCircTimer(t, 0, c, d);
	return t;
}

struct gradient
{
	float4 color;
	float step;
};


float4 mainImage(VertData v_in) : TARGET
{
	const float PI = 3.14159265f;//acos(-1);
	float speed = (float)pulse_speed * 0.01;
	float alpha = (float)alpha_percent * 0.01;
	
	//circular easing variable
	float t = sin(elapsed_time * speed) * 2 - 1;
	float b = 0.0; //start value
	float c = 2.0; //change value
	float d = 2.0; //duration

	float2 gradient_center = float2((float)gradient_center_width_percentage * 0.01,(float)gradient_center_height_percentage * 0.01);
	float4 color = image.Sample(textureSampler, v_in.uv);
	float luminance = dot(color, float3(0.299, 0.587, 0.114));
	float4 gray = {luminance,luminance,luminance, 1};

	// skip if (alpha is zero and only apply to alpha layer is true) 
	if (!(color.a <= 0.0 && Apply_To_Alpha_Layer == true))
	{
		b = BlurStyler(t, 0, c, d, ease);

		const int no_colors = 3;
		float4 s_color = start_color;
		float4 m_color = middle_color;
		float4 e_color = end_color;

		if (rotate_colors)
		{
			// get general time number between 0 and 4
			float tx = (b + 1) * 2;
			// 3 steps  c1->c2, c2->c3, c3->c1
			//when between 0 - 1 only c1 rises then falls

			if (tx <= 2.0)
			{
				s_color = lerp(start_color, middle_color, clamp((min(tx, 2.0) * 0.5) * 2, 0.0, 1.0));
				m_color = lerp(middle_color, end_color, clamp((min(tx, 2.0) * 0.5) * 2, 0.0, 1.0));
				e_color = lerp(end_color, start_color, clamp((min(tx, 2.0) * 0.5) * 2, 0.0, 1.0));
			}

			if ((tx >= 1.0) && (tx <= 3.0))
			{
				s_color = lerp(middle_color, end_color, clamp(((min(max(1.0, tx), 3.0) - 1) * 0.5) * 2, 0.0, 1.0));
				m_color = lerp(end_color, start_color, clamp(((min(max(1.0, tx), 3.0) - 1) * 0.5) * 2, 0.0, 1.0));
				e_color = lerp(start_color, middle_color, clamp(((min(max(1.0, tx), 3.0) - 1) * 0.5) * 2, 0.0, 1.0));
			}

			if (tx >= 2.0)
			{
				s_color = lerp(end_color, start_color, clamp(((min(2.0, tx) - 2) * 0.5) * 2, 0.0, 1.0));
				m_color = lerp(start_color, middle_color, clamp(((min(2.0, tx) - 2) * 0.5) * 2, 0.0, 1.0));
				e_color = lerp(middle_color, end_color, clamp(((min(2.0, tx) - 2) * 0.5) * 2, 0.0, 1.0));
			}

			if (tx < 0)
			{
				s_color = lerp(end_color, start_color, clamp(abs(max(1.0, tx)) * 2, 0.0, 1.0));
				m_color = lerp(start_color, middle_color, clamp(abs(max(1.0, tx)) * 2, 0.0, 1.0));
				e_color = lerp(middle_color, end_color, clamp(abs(max(1.0, tx)) * 2, 0.0, 1.0));
			}
		}

		float4 colors[no_colors] = { s_color, m_color, e_color };
		float step[no_colors] = { start_step, middle_step, end_step };

		float redness = max(min(color.r - color.g, color.r - color.b) / color.r, 0);
		float greenness = max(min(color.g - color.r, color.g - color.b) / color.g, 0);
		float blueness = max(min(color.b - color.r, color.b - color.g) / color.b, 0);

		float dist = distance(v_in.uv, gradient_center);
		if (horizontal && (vertical == false))
		{
			dist = distance(v_in.uv.y, gradient_center.y);
		}
		if (vertical && (horizontal == false))
		{
			dist = distance(v_in.uv.x, gradient_center.x);
		}

		float4 col = colors[0];
		for (int i = 1; i < no_colors; ++i) {
			col = lerp(col, colors[i], smoothstep(step[i - 1], step[i], dist));
		}
		col.a = clamp(alpha, 0.0, 1.0);
		if (Apply_To_Alpha_Layer == false)
			color.a = alpha;
		//	result = float4(redness, greenness,blueness,1);
		//color *= float4(col.r, col.g, col.b, clamp(dot(color, luminance)* alpha, 0.0, 1.0));
		//color.rgb += col * alpha;
		//color.a += clamp(1.0 - alpha, 0.0,1.0);
		///color.rgb *= (color.rgb * clamp(1.0- alpha, 0.0, 1.0)) + (col.rgb * clamp(alpha, 0.0, 1.0));
		//color = float4(max(color.r, col.r), max(color.g, col.g), max(color.b, col.b), clamp(dot(color, luminance) * alpha, 0.0, 1.0));
		color.rgb = lerp(color.rgb, col.rgb, clamp(alpha, 0.0, 1.0));
	}
	return color;

	
}
