uniform float sensitivity = 0.05;
uniform bool invert;
uniform float4 edge_color;
uniform bool edge_multiply;
uniform float4 non_edge_color;
uniform bool non_edge_multiply;
float4 mainImage(VertData v_in) : TARGET
{
	float4 color = image.Sample(textureSampler, v_in.uv);
	
	const float s = 3;
    const float hstep = uv_pixel_interval.x;
    const float vstep = uv_pixel_interval.y;
	
	float offsetx = (hstep * (float)s) / 2.0;
	float offsety = (vstep * (float)s) / 2.0;
	
	float4 lum = float4(0.30, 0.59, 0.11, 1);
	float samples[9];
	
	int index = 0;
	for(int i = 0; i < s; i++){
		for(int j = 0; j < s; j++){
			samples[index] = dot(image.Sample(textureSampler, float2(v_in.uv.x + (i * hstep) - offsetx, v_in.uv.y + (i * vstep) - offsety )), lum);
			index++;
		}
	}
	
	float vert = samples[2] + samples[8] + (2 * samples[5]) - samples[0] - (2 * samples[3]) - samples[6];
	float hori = samples[6] + (2 * samples[7]) + samples[8] - samples[0] - (2 * samples[1]) - samples[2];
	float4 col;
	
	float o = ((vert * vert) + (hori * hori));
	bool isEdge = o > sensitivity;
	if(invert){
		isEdge = !isEdge;
	}
	if (isEdge) {
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
	
	return col;
}
