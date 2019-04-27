// Burn shader by Charles Fettinger (https://github.com/Oncorporation)  4/2019
// for use with obs-shaderfilter 1.0

float4 mod(float4 x, float4 y)
{
	return x - y * floor(x / y);
}
float4 mod289(float4 x)
{
	return x - floor(x / 289.0) * 289.0;
}
float4 permute(float4 x)
{
	return mod289(((x * 34.0) + 1.0) * x);
}
float4 taylorInvSqrt(float4 r)
{
	return (float4)1.79284291400159 - r * 0.85373472095314;
}
float2 fade(float2 t) {
	return t * t* t* (t * (t * 6.0 - 15.0) + 10.0);
}
// Classic Perlin noise
float cnoise(float2 P)
{
	float4 Pi = floor(P.xyxy) + float4(0.0, 0.0, 1.0, 1.0);
	float4 Pf = frac(P.xyxy) - float4(0.0, 0.0, 1.0, 1.0);
	Pi = mod289(Pi); // To avoid truncation effects in permutation
	float4 ix = Pi.xzxz;
	float4 iy = Pi.yyww;
	float4 fx = Pf.xzxz;
	float4 fy = Pf.yyww;
	float4 i = permute(permute(ix) + iy);
	float4 gx = frac(i / 41.0) * 2.0 - 1.0;
	float4 gy = abs(gx) - 0.5;
	float4 tx = floor(gx + 0.5);
	gx = gx - tx;
	float2 g00 = float2(gx.x, gy.x);
	float2 g10 = float2(gx.y, gy.y);
	float2 g01 = float2(gx.z, gy.z);
	float2 g11 = float2(gx.w, gy.w);
	float4 norm = taylorInvSqrt(float4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11)));
	g00 *= norm.x;
	g01 *= norm.y;
	g10 *= norm.z;
	g11 *= norm.w;
	float n00 = dot(g00, float2(fx.x, fy.x));
	float n10 = dot(g10, float2(fx.y, fy.y));
	float n01 = dot(g01, float2(fx.z, fy.z));
	float n11 = dot(g11, float2(fx.w, fy.w));
	float2 fade_xy = fade(Pf.xy);
	float2 n_x = lerp(float2(n00, n01), float2(n10, n11), fade_xy.x);
	float n_xy = lerp(n_x.x, n_x.y, fade_xy.y);
	return 2.3 * n_xy;
}
// Classic Perlin noise, periodic variant
float pnoise(float2 P, float2 rep)
{
	float4 Pi = floor(P.xyxy) + float4(0.0, 0.0, 1.0, 1.0);
	float4 Pf = frac(P.xyxy) - float4(0.0, 0.0, 1.0, 1.0);
	Pi = mod(Pi, rep.xyxy); // To create noise with explicit period
	Pi = mod289(Pi);        // To avoid truncation effects in permutation
	float4 ix = Pi.xzxz;
	float4 iy = Pi.yyww;
	float4 fx = Pf.xzxz;
	float4 fy = Pf.yyww;
	float4 i = permute(permute(ix) + iy);
	float4 gx = frac(i / 41.0) * 2.0 - 1.0;
	float4 gy = abs(gx) - 0.5;
	float4 tx = floor(gx + 0.5);
	gx = gx - tx;
	float2 g00 = float2(gx.x, gy.x);
	float2 g10 = float2(gx.y, gy.y);
	float2 g01 = float2(gx.z, gy.z);
	float2 g11 = float2(gx.w, gy.w);
	float4 norm = taylorInvSqrt(float4(dot(g00, g00), dot(g01, g01), dot(g10, g10), dot(g11, g11)));
	g00 *= norm.x;
	g01 *= norm.y;
	g10 *= norm.z;
	g11 *= norm.w;
	float n00 = dot(g00, float2(fx.x, fy.x));
	float n10 = dot(g10, float2(fx.y, fy.y));
	float n01 = dot(g01, float2(fx.z, fy.z));
	float n11 = dot(g11, float2(fx.w, fy.w));
	float2 fade_xy = fade(Pf.xy);
	float2 n_x = lerp(float2(n00, n01), float2(n10, n11), fade_xy.x);
	float n_xy = lerp(n_x.x, n_x.y, fade_xy.y);
	return 2.3 * n_xy;
}

uniform texture2d Burn_Gradient = "burngradient.png";
uniform float Speed = 0.33;
uniform float Gradient_Adjust = 0.85;
uniform float Dissolve_Value = 1.43;
uniform bool Animated;
uniform bool Apply_to_Channel;
uniform bool Apply_Smoke = true;
uniform float Smoke_Horizonal_Speed = 0.3;
uniform float Smoke_Vertical_Speed = 0.17;
uniform int Iterations = 4;
uniform string Notes = "Animate refers to the burn effect. Speed is general and is reversed with negative numbers. Gradient Adjust is the width of the burn gradient. Use the burngradient.png. Dissolve Value is important. Apply Smoke adds the scrolling smoke.";

float4 mainImage(VertData v_in) : TARGET
{
	float4 color = image.Sample(textureSampler, v_in.uv);
	float4 smoke = float4(1.0,1.0,1.0,1.0);
	float4 result = smoke;
	float t = elapsed_time * Speed;
	float cycle = 1 - max((sin(t) * 2) - 1, 0); //create a negative cycle time as a delay
	float2 dir = float2(Smoke_Horizonal_Speed, Smoke_Vertical_Speed);
	//float largestDistance = sqrt(pow(uv_size.x, 2) + pow(uv_size.y, 2));

	float perlin = 0.5;
	float smoke_perlin = 0;
	float scale = 1;
	float w = 0.5;	

	for (int i = 0; i < Iterations; i++) {
		//float2 coord = v_in.uv * scale;// (v_in.uv + t * dir)* scale;
		float2 coord = (v_in.uv + t * (dir * .1)) * scale;
		float2 period = scale * dir;
		perlin += pnoise(coord, period) * w;
		if (Apply_Smoke)
			smoke_perlin += cnoise((v_in.uv + t * dir) * scale) * w * .5;

		scale *= 2.0;
		w *= 0.5;
	}

	//float toPoint = abs(length(v_in.uv - (v_in.uv * .5)) / ((1.0001 - t) * largestDistance));
	if (!Animated)
		cycle = 1;
	float d = clamp(((Dissolve_Value * cycle + perlin) ) - 1.0, -.01, 0.99);
	float overOne = saturate(d * Gradient_Adjust);
	float4 burn = Burn_Gradient.Sample(textureSampler, float2(overOne, 0.5));

	if (Apply_to_Channel) {
		result =  color * burn;
	}
	else {
		result = float4(perlin, perlin, perlin, 1.0) * burn;
	}	

	if (smoke_perlin > 0) {
		smoke *= smoke_perlin;
		if (result.a <= 0.04)
			result = float4(smoke.rgb, smoke_perlin);
		result += smoke;
	}

	return result;
}