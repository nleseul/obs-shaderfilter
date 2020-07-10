//fire shader modified by Charles Fettinger for use with obs-shaderfilter 07/20 v.01
// https://github.com/Oncorporation/obs-shaderfilter plugin
// https://www.shadertoy.com/view/MtcGD7 original version

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
uniform string notes = "add notes here";

uniform bool Invert_Direction <
	string name = "Invert Direction";
> = true;

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
    //return rand_f;
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
    //float4 rgba = image.Sample(textureSampler, v_in.uv);
    float2 iResolution = 1 - v_in.uv  +  float2( .99, 1.15);
    float iTime = elapsed_time;
    
    const vec3 c1 = vec3(0.5, 0.0, 0.1);
    const vec3 c2 = vec3(0.9, 0.1, 0.0);
    const vec3 c3 = vec3(0.2, 0.1, 0.7);
    const vec3 c4 = vec3(1.0, 0.9, 0.1);
    const vec3 c5 = vec3(0.1, 0.1, 0.1);
    const vec3 c6 = vec3(0.9, 0.9, 0.9);

    vec2 speed = vec2(1.2, 0.1);
    float shift = 1.327 - sin(iTime * 2.0) / 2.4;
    float alpha = 1.0;
    
    //change the constant term for all kinds of cool distance versions,
    //make plus/minus to switch between 
    //ground fire and fire rain!
    float dist = 3.5 - sin(iTime * 0.4) / 1.89;
    
    vec2 p = v_in.uv.xy * dist / iResolution.xx;
    p.x -= iTime / 1.1;
    float q = fbm(p - iTime * 0.01 + 1.0 * sin(iTime) / 10.0);
    float qb = fbm(p - iTime * 0.002 + 0.1 * cos(iTime) / 5.0);
    float q2 = fbm(p - iTime * 0.44 - 5.0 * cos(iTime) / 7.0) -6.0;
    float q3 = fbm(p - iTime * 0.9 - 10.0 * cos(iTime) / 30.0) -4.0;
    float q4 = fbm(p - iTime * 2.0 - 20.0 * sin(iTime) / 20.0) +2.0;
    q = (q + qb - .4 * q2 - 2.0 * q3 + .6 * q4) / 3.8;
    vec2 r = vec2(fbm(p + q / 2.0 - iTime* speed.x - p.x - p.y),
    fbm(p - q - iTime* speed.y));
    vec3 c = mix(c1, c2, fbm(p + r)) + mix(c3, c4, r.x) - mix(c5, c6, r.y);
    vec3 color = vec3(c * cos(shift * 1 - v_in.uv.y / iResolution.y));
    color += .05;
    color.r *= .8;
    vec3 hsv = rgb2hsv(color);
    hsv.y *= hsv.z * 1.1;
    hsv.z *= hsv.y * 1.13;
    hsv.y = (2.2 - hsv.z * .9) * 1.20;
    color = hsv2rgb(hsv);
    
    return vec4(color.x, color.y, color.z, alpha);
}



