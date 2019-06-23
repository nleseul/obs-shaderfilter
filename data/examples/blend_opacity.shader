// opaicty blend shader by Charles Fettinger for obs-shaderfilter plugin 3/2019
//https://github.com/Oncorporation/obs-shaderfilter
uniform bool Vertical;
uniform bool Rotational;
uniform float Rotation_Offset = 0.0; //<Range(0.0, 6.28318531)>
uniform float Opacity_Start_Percent = 0.0;
uniform float Opacity_End_Percent = 100.0;
uniform float Spread = 0.5; //<Range(0.5, 10.0)>
uniform float Speed = 0.0; //<Range(-10.0, 10.0)>
uniform bool Apply_To_Alpha_Layer = true;
uniform string Notes = "Spread is wideness of opacity blend and is limited between .25 and 10. Edit at your own risk. Invert Start and End to Reverse effect.";

float4 mainImage(VertData v_in) : TARGET
{
	const float PI = 3.14159265f;//acos(-1);


	float4 color = image.Sample(textureSampler, v_in.uv);
	float luminance = dot(color, float3(0.299, 0.587, 0.114));
	float4 gray = {luminance,luminance,luminance, 1};

	float2 lPos = (v_in.uv * uv_scale + uv_offset) / clamp(Spread, 0.25, 10.0);
	float time = (elapsed_time * clamp(Speed, -5.0, 5.0)) / clamp(Spread, 0.25, 10.0);
	float dist = distance(v_in.uv , (float2(0.99, 0.99) * uv_scale + uv_offset));

	if (color.a > 0.0 || Apply_To_Alpha_Layer == false)
	{
		//set opacity and direction
		float opacity = (-1 * lPos.x) * 0.5;

		if (Rotational && (Vertical == false))
		{
			float timeWithOffset = time + Rotation_Offset;
			float sine = sin(timeWithOffset);
			float cosine = cos(timeWithOffset);
			opacity = (lPos.x * cosine + lPos.y * sine) * 0.5;
		}

		if (Vertical && (Rotational == false))
		{
			opacity = (-1 * lPos.y) * 0.5;
		}

		opacity += time;
		opacity = frac(opacity);
		color.a = lerp(Opacity_Start_Percent * 0.01, Opacity_End_Percent * 0.01, clamp(opacity, 0.0, 1.0));
	}
	return color;
}


