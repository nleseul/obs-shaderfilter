// Single-pass gaussian blur - fast shader modified by Charles Fettinger for use with obs-shaderfilter 7/2020 v.01
// https://github.com/Oncorporation/obs-shaderfilter
// https://www.shadertoy.com/view/ltScRG Converted inspiration

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
#define iTime float

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

// 16x acceleration of https://www.shadertoy.com/view/4tSyzy
// by applying gaussian at intermediate MIPmap level.

uniform int samples = 16;
uniform int LOD = 2; // gaussian done on MIPmap at scale LOD

float gaussian(vec2 i)
{
	float sigma = (float(samples) * .25);
    return exp(-.5 * dot(i /= sigma, i)) / (6.28 * sigma * sigma);
}

vec4 blur(vec2 U, vec2 scale)
{
    vec4 O = vec4(0,0,0,0);
    int sLOD = (1 << LOD); // tile size = 2^LOD
    int s = samples / sLOD;
    
    for (int i = 0; i < s * s; i++)
    {
        vec2 d = vec2(i % s, i / s) * float(sLOD) - float(samples) * 0.5;
        O += gaussian(d) * image.SampleLevel(textureSampler, U + (scale * gaussian(d)), float(LOD));
        //O += gaussian(d) * image.Sample(textureSampler, U + i * d * float(LOD));
        //O += image.Sample(textureSampler, U + gaussian(d) * float(LOD));
    }
    
    return O / O.a;
}

float4 mainImage(VertData v_in) : TARGET
{
    float2 iResolution = uv_scale;//uv_size * uv_scale + uv_offset;
    //float2 iResolution = 1 - v_in.uv  +  1.0;
    //float4 rgba = image.SampleLevel(textureSampler, v_in.uv * uv_scale + uv_offset,4.0);
    return blur(v_in.uv / iResolution, 1.0 / iResolution);
    //return rgba;
}





