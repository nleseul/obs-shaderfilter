// Simple Gradient shader by Charles Fettinger for obs-shaderfilter plugin 3/2019
// https://github.com/Oncorporation/obs-shaderfilter

//lots of room to play here

uniform int speed_percentage = 240; //<Range(-100.0, 100.0)>
uniform int alpha_percentage = 90;
uniform bool Apply_To_Alpha_Layer = false;
uniform bool Lens_Flair = false;
uniform bool Animate_Lens_Flair = false;
uniform string notes = "This gradient is very basic from the top left corner. Red on horizontal, Green vertical, Blue Diagonal. Apply To Alpha Layer will add the gradient colors to the background. Lens Flair will brighten the scene from the bottom right. There is also a lot of unused code to play with in the shader file, delimted by /* ... */";

float4 mainImage(VertData v_in) : TARGET
{

	float4 background_color = image.Sample(textureSampler, v_in.uv);
	int no_colors = 4;
 	float3 colors[4] = {float3(1.0,0.0,0.0),float3(0.0,1.0,0.0),float3(0.0,0.0,1.0),float3(1.0,1.0,1.0)};
 	float alpha = (float)alpha_percentage * 0.01;
 	float speed = (float)speed_percentage * 0.01;

	float mx = max(uv_size.x , uv_size.y);
	//float2 uv = v_in.uv / mx;
	float3 rgb = background_color.rgb;

	// skip if (alpha is zero and only apply to alpha layer is true) 
	if (!(background_color.a <= 0.0 && Apply_To_Alpha_Layer == true))
	{
		rgb = float3(v_in.uv.x, v_in.uv.y, 0.10 + 0.85 * sin(elapsed_time * speed));
	}

	//create lens flare like effect
	if (Lens_Flair)
	{
		float2 lens_flair_coordinates = float2(0.95 ,0.95);
		if (Animate_Lens_Flair)
			lens_flair_coordinates *= float2(sin(elapsed_time * speed) ,cos(elapsed_time * speed));

		float dist = distance(v_in.uv, ( lens_flair_coordinates * uv_scale + uv_offset));
		for (int i = 0; i < no_colors; ++i) {
			rgb += lerp(rgb, colors[i], dist * 1.5) * 0.25;
		}
	}


	//float3 col = colors[0];
/*	for (int i = 1; i < no_colors; ++i) {
		float3 hole = float3(
			sin(1.5 - distance(v_in.uv.x / mx, colors[i].x / mx)  * 2.5 * speed),
			sin(1.5 - distance(v_in.uv.y / mx, colors[i].y / mx)  * 2.5 * speed),
			colors[i].z);
		rgb = lerp(rgb, hole, 0.1);
*/
/*		float3 hole = lerp(colors[i-1], colors[i], sin(elapsed_time * speed));
		col = lerp(col, hole, v_in.uv.x);
*/		
	//}
//	rgb = fflerp(rgb, col, 0.5);



	//try prepositioned colors with colors[] array timing
	//creates an animated color spotlight
/*	int color_index = int(sin(elapsed_time * speed) * no_colors);
	float3 start_color = colors[color_index];
	float3 end_color;
	if (color_index >= 0)
	{
		end_color = colors[color_index - 1];
	}
	else
	{
		end_color = colors[no_colors - 1];
	}

	rgb = smoothstep(start_color, end_color, distance(v_in.uv , sin(elapsed_time * speed * no_colors) * (float2(1.0,1.0) * uv_scale + uv_offset)));
*/

	if (Apply_To_Alpha_Layer == false)
	{
		return lerp(background_color,float4(rgb, 1.0),alpha);
	}
	else
	{
		return lerp(background_color,background_color * float4(rgb,1.0), alpha);
	}

}

