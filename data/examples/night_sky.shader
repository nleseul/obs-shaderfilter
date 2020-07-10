// Night Sky shader by Charles Fettinger for obs-shaderfilter plugin 6/2020 v.65
// https://github.com/Oncorporation/obs-shaderfilter
//https://www.shadertoy.com/view/3tfXRM Simple Night Sky - coverted from and updated

uniform string notes = "add notes here";

uniform float speed = 20.0;
uniform bool Include_Clouds = true;
uniform bool Include_Moon = true;
uniform int center_width_percentage = 50;
uniform int center_height_percentage = 50;
uniform float Alpha_Percentage = 95; //<Range(0.0,100.0)>
uniform bool Apply_To_Image = false;
uniform bool Replace_Image_Color = false;
uniform int number_stars = 20; //<Range(0.0,100.0)>

uniform float4 SKY_COLOR = { 0.027, 0.151, 0.354, 1.0 };
uniform float4 STAR_COLOR = { 0.92, 0.92, 0.14, 1.0 };
uniform float4 LIGHT_SKY = { 0.45, 0.61, 0.98, 1.0 };
uniform float SKY_LIGHTNESS = .3;

 // Moon
uniform float4 MOON_COLOR = { .4, .25, 0.25, 1.0 };
uniform float moon_size = 0.18;
uniform float moon_bump_size = 0.14;
uniform float Moon_Position_x = -0.6;
uniform float Moon_Position_y = -0.3;

#define PI 3.1416

//Noise functions from https://www.youtube.com/watch?v=zXsWftRdsvU
float noise11(float p) {
	return frac(sin(p*633.1847) * 9827.95);
}
    
float noise21(float2 p) {
	return frac(sin(p.x*827.221 + p.y*3228.8275) * 878.121);
}

float2 noise22(float2 p) {
	return frac(float2(sin(p.x*9378.35), sin(p.y*75.589)) * 556.89);
}

//From https://codepen.io/Tobsta/post/procedural-generation-part-1-1d-perlin-noise
float cosineInterpolation(float a, float b, float x) {
    float ft = x * PI;
    float f = (1. - cos(ft)) * .5;
    return a * (1. - f) + b * f;
}

float smoothNoise11(float p, float dist) {
    float prev = noise11(p-dist);
    float next = noise11(p+dist);
       
    return cosineInterpolation(prev, next, .5);
}

float smoothNoise21(float2 uv, float cells) {
	float2 lv = frac(uv*cells);
    float2 id = floor(uv*cells);
    
    //smoothstep function: maybe change it later!
    lv = lv*lv*(3.-2.*lv);
    
    float bl = noise21(id);
    float br = noise21(id+float2(1.,0.));
    float b = lerp(bl, br, lv.x);
    
    float tl = noise21(id+float2(0.,1.));
    float tr = noise21(id+float2(1.,1.));
    float t = lerp(tl, tr, lv.x);
    
    return lerp(b, t, lv.y);
}

float2 smoothNoise22(float2 uv, float cells) {
	float2 lv = frac(uv*cells);
    float2 id = floor(uv*cells);    
    
    lv = lv*lv*(3.-2.*lv);
    
    float2 bl = noise22(id);
    float2 br = noise22(id+float2(1.,0.));
    float2 b = lerp(bl, br, lv.x);
    
    float2 tl = noise22(id+float2(0.,1.));
    float2 tr = noise22(id+float2(1.,1.));
    float2 t = lerp(tl, tr, lv.x);
    
    return lerp(b, t, lv.y);
}

float valueNoise11(float p) {
	float c = smoothNoise11(p, 0.5);
    c += smoothNoise11(p, 0.25)*.5;
    c += smoothNoise11(p, 0.125)*.25;
    c += smoothNoise11(p, 0.0625)*.125;
    
    return c /= .875;
}

float valueNoise21(float2 uv) {
	float c = smoothNoise21(uv, 4.);
    c += smoothNoise21(uv, 8.)*.5;
    c += smoothNoise21(uv, 16.)*.25;
    c += smoothNoise21(uv, 32.)*.125;
    c += smoothNoise21(uv, 64.)*.0625;
    
    return c /= .9375;
}

float2 valueNoise22(float2 uv) {
	float2 c = smoothNoise22(uv, 4.);
    c += smoothNoise22(uv, 8.)*.5;
    c += smoothNoise22(uv, 16.)*.25;
    c += smoothNoise22(uv, 32.)*.125;
    c += smoothNoise22(uv, 64.)*.0625;
    
    return c /= .9375;
}

float3 points(float2 p, float2 uv, float3 color, float size, float blur) {
	float dist = distance(p, uv);    
    return color*smoothstep(size, size*(0.999-blur), dist);
}

float mapInterval(float x, float a, float b, float c, float d) {
	return (x-a)/(b-a) * (d-c) + c;
}

float blink(float time, float timeInterval) {
    float halfInterval = timeInterval / 2.0;
    //Get relative position in the bucket
    float p = fmod(time, timeInterval);
    
    
    if (p <= timeInterval / 2.) {
    	return smoothstep(0., 1., p/halfInterval);
    } else {
        return smoothstep(1., 0., (p-halfInterval)/halfInterval);
    }
}

float3 sampleBumps(float2 p, float2 uv, float radius, float spin) {
	float dist = distance(p, uv);
	float3 BumpSamples =  float3(0.,0.,0.);
    
    if (dist < radius) {
    	float bumps =  (1.-valueNoise21(uv*spin))*.1;
    	BumpSamples = float3(bumps, bumps, bumps);
    }
    return  BumpSamples;
}

float4 mainImage(VertData v_in) : TARGET
{
	float4 rgba;// = image.Sample(textureSampler, v_in.uv);
	float alpha = clamp(Alpha_Percentage *.01 ,0,1.0);
	float2 center_pixel_coordinates = float2(((float)center_width_percentage * 0.01), ((float)center_height_percentage * 0.01));
	float2 st = v_in.uv* uv_scale;
	float2 toCenter = center_pixel_coordinates - st;

    // Normalized pixel coordinates (from 0 to 1)
    float2 uv = v_in.uv;
    float2 ouv = uv;
    uv -= .5;
    uv.x *= uv_size.x/uv_size.y;
    
    float2 seed = toCenter / uv_size.xy;
    
    float time = elapsed_time + seed.x*speed;
        
    //float3 col = float3(0.0);
    //float m = valueNoise21(uv);    
	float3 col = lerp(SKY_COLOR.rgb, LIGHT_SKY.rgb, ouv.y-SKY_LIGHTNESS);
    
    col *= SKY_LIGHTNESS - (1.-ouv.y);
    
    //Add clouds
    if (Include_Clouds)
    {
	    float2 timeUv = uv;
	    timeUv.x += time*.1;
	    timeUv.y += valueNoise11(timeUv.x+.352)*.01;
	    float cloud = valueNoise21(timeUv);
	    col += cloud*.1;
    }

    //Add stars in the top part of the scene
    float timeInterval = speed *.5; //5.0
    float timeBucket = floor(time / timeInterval);  

    float2 moonPosition = float2(-1000, -1000);
    if (Include_Moon)
    {   
    	moonPosition = float2(Moon_Position_x, Moon_Position_y);
	    col += points(moonPosition, uv, MOON_COLOR.rgb,moon_size, 0.3);
	    // Moon bumps
	    col += sampleBumps(moonPosition, uv, moon_bump_size, 9. + fmod(time*.1,9));
    }

    for (float i = 0.; i < clamp(number_stars,0,100); i++) {
	    float2 starPosition = float2(i/10., i/10.);
        
        starPosition.x = mapInterval(valueNoise11(timeBucket + i*827.913)-.4, 0., 1., 0.825, -0.825);
        starPosition.y = mapInterval(valueNoise11(starPosition.x)-.3, 0., 1., 0.445, -0.445);
	    
        float starIntensity = blink(time+ (rand_f * i), timeInterval );
        //Hide stars that are behind the moon
        if (distance(starPosition, moonPosition) > moon_size) {
        	col += points(starPosition, uv, STAR_COLOR.rgb, 0.001, 0.0)*clamp(starIntensity-.1, 0.0, 1.0)*10.0;
        	col += points(starPosition, uv, STAR_COLOR.rgb, 0.009, 3.5)*starIntensity*3.0;
        }
    }
	//col = float3(blink(time, timeInterval));
	rgba = float4(col,alpha);

    // Output to screen
	if (Apply_To_Image)
	{
		float4 color = image.Sample(textureSampler, v_in.uv);
		float4 original_color = color;
		float4 luma = dot(color.rgb,float3(0.299,0.587,0.114));
		if (Replace_Image_Color)
			color = luma;
		rgba = lerp(original_color, rgba * color,alpha);
		
	}
	return rgba;
}
