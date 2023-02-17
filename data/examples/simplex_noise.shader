// Simplex Noise shader by Charles Fettinger (https://github.com/Oncorporation)  5/2019
// for use with obs-shaderfilter 1.0
//based upon: https://www.shadertoy.com/view/XsX3zB

uniform float Snap_Percent = 7.5;
uniform float Speed_Percent = 2.5;
uniform float Resolution = 16.0;
uniform bool Fractal = false;
uniform bool Use_Alpha_Layer = false;
uniform float4 Fore_Color = {0.95,0.95,0.95, 1.0};
uniform float4 Back_Color = {0.75, 0.75, 0.75, 1.0};
uniform float Alpha_Percent = 100.0;
uniform string Notes = "Alpha Percentage applies to the shader, Use_Alpha_Layer applies effect with the image alpha layer, Resolution is the amount of detail of noise created.Fractal is a different algorithm. Snap Percent affects how many updates per second. Default values: 7.5%, 2.5%, 16.0, 100%";

float snap(float x, float snap)
{
	return snap * round(x / max(0.01,snap));
}

float3 random3(float3 co)
{
	float j = 4096.0 * sin(dot(co, float3(17.0, 59.4, 15.0)));
	float3 result;
	result.z = frac(512.0 * j);
	j *= .125;
	result.x = frac(512.0 * j);
	j *= .125;
	result.y = frac(512.0 * j);
	return result - 0.5;
}

/* 3d simplex noise */
float simplex3d(float3 p) {
	/* 1. find current tetrahedron T and it's four vertices */
	/* s, s+i1, s+i2, s+1.0 - absolute skewed (integer) coordinates of T vertices */
	/* x, x1, x2, x3 - unskewed coordinates of p relative to each of T vertices*/
	
	/* skew constants for 3d simplex functions */
	float F3 = 0.3333333;
	float G3 = 0.1666667;

	/* calculate s and x */
	float3 s = floor(p + dot(p, float3(F3,F3,F3)));
	float3 x = p - s + dot(s, float3(G3,G3,G3));

	/* calculate i1 and i2 */
	float3 e = step(float3(0.0,0.0,0.0), x - x.yzx);
	float3 i1 = e * (1.0 - e.zxy);
	float3 i2 = 1.0 - e.zxy * (1.0 - e);

	/* x1, x2, x3 */
	float3 x1 = x - i1 + G3;
	float3 x2 = x - i2 + 2.0 * G3;
	float3 x3 = x - 1.0 + 3.0 * G3;

	/* 2. find four surflets and store them in d */
	float4 w, d;

	/* calculate surflet weights */
	w.x = dot(x, x);
	w.y = dot(x1, x1);
	w.z = dot(x2, x2);
	w.w = dot(x3, x3);

	/* w fades from 0.6 at the center of the surflet to 0.0 at the margin */
	w = max(0.61 - w, 0.0);

	/* calculate surflet components */
	d.x = dot(random3(s), x);
	d.y = dot(random3(s + i1), x1);
	d.z = dot(random3(s + i2), x2);
	d.w = dot(random3(s + 1.0), x3);

	/* multiply d by w^4 */
	w *= w;
	w *= w;
	d *= w;

	/* 3. return the sum of the four surflets */
	return dot(d, float4(52.0, 52.0, 52.0, 52.0));
}


/* directional artifacts can be reduced by rotating each octave */
float simplex3d_fractal(float3 m3) {
	/* const matrices for 3d rotation */
	float3x3 rot1 = {
	-0.37, 0.36, 0.85,
	-0.14, -0.93, 0.34,
	0.92, 0.01, 0.4 };
	float3x3 rot2 = {
	-0.55, -0.39, 0.74,
	0.33, -0.91, -0.24,
	0.77, 0.12, 0.63 };
	float3x3 rot3 = {
	-0.71, 0.52, -0.47,
	-0.08, -0.72, -0.68,
	-0.7, -0.45, 0.56 };

	float3x1 m = {m3.x, m3.y, m3.z};
	
	return   0.5333333* simplex3d(m * rot1)
		+ 0.2666667 * simplex3d(2.0 * m * rot2)
		+ 0.1333333 * simplex3d(4.0 * m * rot3)
		+ 0.0666667 * simplex3d(8.0 * m);
}

float4 mainImage(VertData v_in) : TARGET
{
	float time = snap(elapsed_time, Snap_Percent * .01);
	float4 rgba = image.Sample(textureSampler, v_in.uv);
	float2 p = v_in.uv.xy +  float2( 0, -0.5);
	float3 p3 = float3(p, time * (Speed_Percent * 0.01));
	
	float pixel_alpha = 1.0;
	// apply to mainImage rgba
	if (Use_Alpha_Layer) {
		p3 *= rgba.rgb;
		pixel_alpha = rgba.a;
	}

	float value;

	if (Fractal) {
		value = simplex3d_fractal(p3 * (Resolution * 0.5) + (Resolution * 0.5));		
	}
	else {
		value = simplex3d(p3 * Resolution);
	}

	//soften color
	value = 0.5 + (0.5 * value);
	float intensity = dot(float4(float3(value, value, value), pixel_alpha), float3(0.299, 0.587, 0.114));

	//use intensity to apply foreground and background colors
	float4 r = lerp(float4(float3(value, value, value), pixel_alpha), Fore_Color, saturate(intensity));
	r = lerp(Back_Color, r, saturate(intensity));
	r.a = pixel_alpha;

	return  lerp(rgba, r, Alpha_Percent * 0.01);
}