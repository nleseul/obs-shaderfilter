// Edge Detection for OBS Studio
// originally from Andersama (https://github.com/Andersama)
// Modified and improved my Charles Fettinger (https://github.com/Oncorporation)  1/2019
uniform float sensitivity = 0.05;
uniform bool invert_edge;
uniform float4 edge_color;
uniform bool edge_multiply;
uniform float4 non_edge_color;
uniform bool non_edge_multiply;
uniform bool alpha_channel;
uniform float alpha_level = 100;
uniform bool alpha_invert;
uniform float rand_f;

uniform string notes = "'sensativity' - 0.01 is max and will create the most edges. Increasing this value decreases the number of edges detected.  'edge non edge color' - the color to recolor vs the original image. 'edge or non edge multiply' - multiplies the color against the original color giving it a tint instead of replacing the color. White represents no tint. 'invert edge' - flips the sensativity and is great for testing and fine tuning. 'alpha channel' - use an alpha channel to replace original color with transparency. 'alpha_level' - transparency amount modifier where 1.0 = base luminance  (recommend 0.00 - 2.00). 'alpha_invert' - flip what is transparent from darks (default) to lights";

float4 mainImage(VertData v_in) : TARGET
{
	float4 color = image.Sample(textureSampler, v_in.uv);
	
	const float s = 3;
    const float hstep = uv_pixel_interval.x;
    const float vstep = uv_pixel_interval.y;
	
	float offsetx = (hstep * (float)s) / 2.0;
	float offsety = (vstep * (float)s) / 2.0;
	
	float4 lum = float4(0.30, 0.59, 0.11, 1 );
	float samples[9];
	
	int index = 0;
	for(int i = 0; i < s; i++){
		for(int j = 0; j < s; j++){
			samples[index] = dot(image.Sample(textureSampler, float2(v_in.uv.x + (i * hstep) - offsetx, v_in.uv.y + (j * vstep) - offsety )), lum);
			index++;
		}
	}
	
	float vert = samples[2] + samples[8] + (2 * samples[5]) - samples[0] - (2 * samples[3]) - samples[6];
	float hori = samples[6] + (2 * samples[7]) + samples[8] - samples[0] - (2 * samples[1]) - samples[2];
	float4 col;
	
	float o = ((vert * vert) + (hori * hori));
	bool isEdge = o > sensitivity;
	if(invert_edge){
		isEdge = !isEdge;
	}
	if(isEdge) {
		col = edge_color;
		if(edge_multiply){
			col *= color;
		}
	} else {
		col = non_edge_color;
		if(non_edge_multiply){
			col *= color;
		}
	}

	if (alpha_invert) {
		lum = 1.0 - lum;
	}

	if(alpha_channel){
		if (edge_multiply && isEdge) {
			return float4(col.r,col.g,col.b,clamp(dot(color,lum )* alpha_level,0.0,1.0));
		} else {
			// use max instead of multiply
			return float4(max(color.r, col.r),max(color.g,col.g),max(color.b, col.b),clamp(dot(color,lum ) * alpha_level,0.0,1.0));
		}
	} else {
		// col.a = col.a * alpha_level;
		return col;
	}
}
