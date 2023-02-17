//fire shader modified by Charles Fettinger for use with obs-shaderfilter 07/20 v.6
// https://github.com/Oncorporation/obs-shaderfilter plugin
// https://www.shadertoy.com/view/MtcGD7 original version

//v.5
// flicker
// flame type
// apply to image 
// replace image color
// speed
// flame size
// alpha
// invert direction/position


//Section to converting GLSL to HLSL - can delete
#define vec2 float2
#define vec3 float3
#define vec4 float4
#define ivec2 int2
#define ivec3 int3
#define ivec4 int4
#define mat2 float2x2
#define mat3 float3x3
#define mat4 float4x4
#define fract frac
#define mix lerp
//#define iTime float

/*
**Shaders have these variables pre loaded by the plugin**
**this section can be deleted**

uniform float4x4 ViewProj;
uniform texture2d image;

uniform float elapsed_time;
uniform float2 uv_offset;
uniform float2 uv_scale;
uniform float2 uv_pixel_interval;
uniform float2 uv_size;
uniform float rand_f;
uniform float rand_instance_f;
uniform float rand_activation_f;
uniform int loops;
uniform float local_time;
*/
uniform int Alpha_Percentage = 90; //<Range(0.0,100.0)>
uniform int Speed = 100;
uniform int Flame_Size = 70;
uniform int Fire_Type = 1;

uniform bool Invert <
	string name = "Invert";
> = false;
uniform float lumaMin = 0.01;
uniform float lumaMinSmooth = 0.04;
uniform bool Apply_To_Image;
uniform bool Replace_Image_Color;
uniform bool Apply_To_Specific_Color;
uniform float4 Color_To_Replace;
uniform string Notes = "Luma cuts reveals background, flame size is percentage screen size, Alpha Percentage adjusts color";

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float rand(vec2 n)
{
    return fract(sin(cos(dot(n, vec2(12.9898, 12.1414)))) * 83758.5453);
    //return sin(rand_f, n);
}

float noise(vec2 n)
{
    const vec2 d = vec2(0.0, 1.0);
    vec2 b = floor(n), f = smoothstep(vec2(0.0, 0.0), vec2(1.0, 1.0), fract(n));
    return mix(mix(rand(b), rand(b + d.yx), f.x), mix(rand(b + d.xy), rand(b + d.yy), f.x), f.y);
}

float fbm(vec2 n)
{
    float total = 0.0, amplitude = 1.0;
    for (int i = 0; i < 5; i++)
    {
        total += noise(n) * amplitude;
        n += n * 1.7;
        amplitude *= 0.47;
    }
    return total;
}

float4 mainImage(VertData v_in) : TARGET
{
    float2 iResolution = uv_scale;
    float flame_size = clamp((float)Flame_Size * .01,-5,5);

    // inverting direction is logically inverted to allow the bottom up to be normal
    float fire_base = (v_in.uv.y / iResolution.y);
    float2 fire_pix = v_in.uv.xy + float2(flame_size -1,0);
    float direction = -1.0 * clamp((float)Speed*.01,-5,5);        
    if (!Invert)
    {
        direction *= -1.0;
        fire_base = 1 - fire_base;
        fire_pix = 1 - fire_pix;
    }    
    float iTime = direction * elapsed_time;
    
    const vec3 c1 = vec3(0.5, 0.0, 0.1);
    const vec3 c2 = vec3(0.9, 0.1, 0.0);
    const vec3 c3 = vec3(0.2, 0.1, 0.7);
    const vec3 c4 = vec3(1.0, 0.9, 0.1);
    const vec3 c5 = vec3(0.1, 0.1, 0.1);
    const vec3 c6 = vec3(0.9, 0.9, 0.9);

    vec2 speed = vec2(1.2, 0.1) * clamp((float)Speed*.01,-5,5);
    float shift = 1.327 * (1/flame_size) - sin(iTime * 2.0) / 2.4;
    float alpha = saturate((float)Alpha_Percentage * .01);
    
    //change the constant term for all kinds of cool distance versions,
    //make plus/minus to switch between 
    //ground fire and fire rain!
    float dist = 3.5 - sin(iTime * 0.4) / 1.89;
    
    vec2 p = fire_pix * dist / iResolution.xx;
    p.x -= iTime / 1.1;
    float3 black = float3(0,0,0);
    vec3 fire;

    if (Fire_Type == 1)
    {
        //fire version 1 larger and more volume
        float q = fbm(p - iTime * 0.01 + 1.0 * sin(iTime) / 10.0);
        float qb = fbm(p - iTime * 0.002 + 0.1 * cos(iTime) / 5.0);
        float q2 = fbm(p - iTime * 0.44 - 5.0 * cos(iTime) / 7.0) -6.0;
        float q3 = fbm(p - iTime * 0.9 - 10.0 * cos(iTime) / 30.0) -4.0;
        float q4 = fbm(p - iTime * 2.0 - 20.0 * sin(iTime) / 20.0) +2.0;
        q = (q + qb - .4 * q2 - 2.0 * q3 + .6 * q4) / 3.8;

        vec2 r = vec2(fbm(p + q / 2.0 - iTime* speed.x - p.x - p.y),
        	fbm(p - q - iTime* speed.y)) ;
        vec3 c = mix(c1, c2, fbm(p + r)) + mix(c3, c4, r.x) - mix(c5, c6, r.y);
        fire = vec3(c * max(cos(shift * fire_base) - (rand_f *.05),0.05));

        fire += .05;
        fire.r *= .8;
        vec3 hsv = rgb2hsv(fire);
        hsv.y *= hsv.z * 1.1;
        hsv.z *= hsv.y * 1.13;
        hsv.y = (2.2 - hsv.z * .9) * 1.20;
        fire = hsv2rgb(hsv);        
    }
    else
    {
        // fire version 0 - smaller and more whisps
        p += (rand_f *.01);
        float q = fbm(p - iTime * 0.3+1.0*sin(iTime+0.5)/2.0);
        float qb = fbm(p - iTime * 0.4+0.1*cos(iTime)/2.0);
        float q2 = fbm(p - iTime * 0.44 - 5.0*cos(iTime)/2.0) - 6.0;
        float q3 = fbm(p - iTime * 0.9 - 10.0*cos(iTime)/15.0)-4.0;
        float q4 = fbm(p - iTime * 1.4 - 20.0*sin(iTime)/14.0)+2.0;
        q = (q + qb - .4 * q2 -2.0*q3  + .6*q4)/3.8;

        vec2 r = vec2(fbm(p + q /2.0 + iTime * speed.x - p.x - p.y), 
        	fbm(p + q - iTime * speed.y)) * shift;
        vec3 c = mix(c1, c2, fbm(p + r)) + mix(c3, c4, r.x) - mix(c5, c6, r.y);
        //fire = vec3(1.0/(pow(c+1.61,vec3(4.0,4.0,4.0))) * max(cos(shift * fire_base),0));
        
        fire = vec3(1.0,.2,.05)/(pow((r.y+r.y)* max(.0,p.y)+0.1, 4.0)) ;//* max(.1,(cos(shift * fire_base)));
        fire += (black*0.01*pow((r.y+r.y)*.65,5.0)+0.055)*mix( vec3(.9,.4,.3),vec3(.7,.5,.2), v_in.uv.y);
        fire = fire/(1.0+max(black,fire));
    }
    float4 rgba = vec4(fire.x, fire.y, fire.z, alpha);
	
	// remove dark areas per user
	float luma_fire = dot(rgba.rgb,float3(0.299,0.587,0.114));
	float luma_min_fire = smoothstep(lumaMin, lumaMin + lumaMinSmooth, luma_fire);
	rgba.a = clamp(luma_min_fire,0.0,alpha);
    
    float4 color;
    float4 original_color;
    if (Apply_To_Image)
    {
        color = image.Sample(textureSampler, v_in.uv);
        original_color = color;
        if (color.a > 0.0)
        {    
            float4 luma = dot(color, float4(0.30, 0.59, 0.11, color.a));
            if (Replace_Image_Color)
                color = luma;            
            rgba = lerp(original_color, lerp(original_color,rgba * color,rgba.a), alpha);
        }
        else
        {
            rgba = color;
        }
		
    }
    if (Apply_To_Specific_Color)
    {
        color = image.Sample(textureSampler, v_in.uv);
        original_color = color;
        color = (distance(color.rgb, Color_To_Replace.rgb) <= 0.075) ? rgba : color;
        rgba = lerp(original_color, color, alpha);
    }
    return rgba;
}



