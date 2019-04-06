// Simple Gradient shader by Charles Fettinger for obs-shaderfilter plugin 3/2019
// https://github.com/Oncorporation/obs-shaderfilter

//lots of room to play here

uniform int speed_percentage = 240; //<Range(-10.0, 10.0)>
uniform int alpha_percentage = 100;
uniform string notes = "There are a lot of code items you can play with in the file /* */ delimit";

float4 mainImage(VertData v_in) : TARGET
{

	float4 background_color = image.Sample(textureSampler, v_in.uv);
	int no_colors = 4;
 	float3 colors[4] = {float3(1.0,0.0,0.0),float3(0.0,1.0,0.0),float3(0.0,0.0,1.0),float3(1.0,1.0,1.0)};
 	float alpha = (float)alpha_percentage * 0.01;
 	float speed = (float)speed_percentage * 0.01;

	float mx = max(uv_size.x , uv_size.y);
	//float2 uv = v_in.uv / mx;
	float3 rgb = float3(v_in.uv.x, v_in.uv.y, 0.10 + 0.85 * sin(elapsed_time * speed) );
	
/*	float dist = distance(v_in.uv, (float2(0.95,0.95) * uv_scale + uv_offset));
	for (int i = 0; i < no_colors; ++i) {
		rgb = lerp(rgb, colors[i], dist * 1.5);
	}
*/
//	float3 col = colors[0];
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


	return lerp(
	background_color,
	float4(rgb, 1.0)
	,alpha);

}

