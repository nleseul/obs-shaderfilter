// Hexagon shader by Charles Fettinger for obs-shaderfilter plugin 4/2019
//https://github.com/Oncorporation/obs-shaderfilter

uniform float4 Hex_Color;
uniform int Alpha_Percent = 100;
uniform float Quantity = 25;
uniform int Border_Width = 15;  // <- -15 to 85, -15 off top
uniform bool Blend;
uniform bool Equilateral;
uniform bool Zoom_Animate;
uniform int Speed_Percent = 100; 
uniform bool Glitch;
uniform float Distort_X = 1.0;
uniform float Distort_Y = 1.0;
uniform float Offset_X = 0.0;
uniform float Offset_Y = 0.0;
uniform string notes= "Tiles:equilateral: around 12.33,nonequilateral: square rootable number. Distort of 1 is normal.";


// 0 on edges, 1 in non_edge
float hex(float2 p) {
	float xyratio = 1;
	if (Equilateral)
		xyratio = uv_size.x /uv_size.y;

	// calc p 
	p.x = mul(p.x,xyratio);
	p.y += (floor(p.x) % 2.0)*0.5;
	p = abs(((p % 1.0) - 0.5));
	return abs(max(p.x*1.5 + p.y, p.y*2.0) -1);
}

float4 mainImage(VertData v_in) : TARGET
{
	float4 rgba 		= image.Sample(textureSampler, v_in.uv * uv_scale + uv_offset);
	float alpha 		= (float)Alpha_Percent * 0.01;	
	float quantity 		= sqrt(clamp(Quantity, 0.0, 100.0));
	float border_width	= clamp(float(Border_Width - 15), -15, 100) * 0.01;
	float speed 		= (float)Speed_Percent * 0.01;
	float time 		= (1 + sin(elapsed_time * speed))*0.5;
	if (Zoom_Animate)
		quantity 	*= time;

	// create a (pos)ition reference, hex radius and smoothstep out the non_edge
	float2 pos 		= float2(v_in.uv.x * max(0,Distort_X), (1 - v_in.uv.y) * max(0,Distort_Y)) * uv_scale + uv_offset + float2(Offset_X, Offset_Y);
	if (Glitch)
		quantity 	*= lerp(pos.x, pos.y, rand_f);
	float2 p 		= (pos * quantity); // number of hexes to be created
	float  r 		= (1.0 -0.7)*0.5;	// cell default radius
	float non_edge 		= smoothstep(0.0, r + border_width, hex(p)); // approach border become edge

	// make the border colorable - non_edge is scaled
	float4 color 		= float4(non_edge, non_edge,non_edge,1.0) ;
	if (non_edge < 1)
	{
		color = Hex_Color;
		color.a = alpha;
		if (Blend)
			color 		= lerp(rgba, color, 1 - non_edge);
		return lerp(rgba,color,alpha);
	}
	return lerp(rgba, color * rgba, alpha);
} 
