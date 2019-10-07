// divide and rotate shader for OBS Studio shaderfilter plugin
// originally from shadertoy (https://www.shadertoy.com/view/3sy3Dh)
// Modified by Charles Fettinger (https://github.com/Oncorporation)  10/2019


//default variables provided by system, not needed in shaders
//uniform float4x4 ViewProj;
//uniform texture2d image;

//uniform float elapsed_time;
//uniform float2 uv_offset;
//uniform float2 uv_scale;
//uniform float2 uv_pixel_interval;
//uniform float rand_f;
//uniform float2 uv_size;

uniform string notes = "change vec,vec2,vec3,vec4 to float,float2,float3,float4. change fract to fract, use internal time and uv values, use image.Sample instead of texture";

uniform texture2d iChannel0;
uniform float alpha = 0.75;

//sampler_state textureSampler {
//	Filter    = Linear;
//	AddressU  = Border;
//	AddressV  = Border;
//	BorderColor = 00000000;
//};

//struct VertData {
//	float4 pos : POSITION;
//	float2 uv  : TEXCOORD0;
//};


float2 cm(float2 a, float2 b) {
    return float2(a.x * b.x - a.y * b.y, a.x * b.y + a.y * b.x);
}

float2 iter(float2 uv, float2 rot, float scale) {
    float2 gv = frac(cm(uv, rot) * scale);
    float boundDist = 1. - max(abs(gv.x), abs(gv.y));
    float mask = step(.03, boundDist);
    gv *= mask;
    return gv;
}

float4 mainImage_initialconversion(VertData v_in) : TARGET
{
	// Normalize coords
    //float2 uv = (v_in.pos.xy - .5 * v_in.uv.xy) / v_in.uv.y; not needed we already create this for you    
    //float2 mouse = (iMouse.xy - .5 * v_in.uv.xy) / v_in.uv.y; we do not have mouse interaction
    float2 uv = v_in.uv;
    float2 mouse = (v_in.uv.xy - .5 * v_in.uv.xy) / v_in.uv.y;
    
    // Add some time rotation and offset
    float t = elapsed_time * .05;  //time is replaced with our standardized version
    float2 time = float2(sin(t), cos(t));
    uv += time;
    
    // Imaginary component has to be mirrored for natural feeling rotation
    mouse.y *= -1.0;
    
    // Draw few layers of this to bend space
    float2 rot = cm(mouse, time);
    for (float i=1.0; i<=3.0; i++) {
        uv = iter(uv, rot, 1.5);
    }
    

    //float3 col = texture(iChannel0, uv).rgb;  would convert to iChannel0.Sample()
    float4 col = image.Sample(textureSampler, v_in.uv);
    if (uv.x == 0.0 && uv.y == 0.0) {
        col = float4(0);    
    }        
    
	return float4(col.rgb,1.0);
}

float4 mainImage(VertData v_in) : TARGET
{
	// Normalize coords
	float2 uv = v_in.uv;
	//float2 uv = (v_in.pos.xy - .5 * v_in.uv.xy) / v_in.uv.y;
	float2 mouse = (v_in.uv.xy - .5 * v_in.uv.xy) / v_in.uv.y;

	// Add some time rotation and offset
    float t = elapsed_time * .05;
    float2 time = float2(sin(t), cos(t));
    uv += time;

    // Imaginary component has to be mirrored for natural feeling rotation
    mouse.y *= -1.0;

	// Draw few layers of this to bend space
    float2 rot = cm(mouse, time);
        for (float i=1.0; i<=3.0; i++) {
        uv = iter(uv, rot, 1.5);
    }

    //combine background with new image
    float4 rgba = image.Sample(textureSampler, v_in.uv);
    float4 col = iChannel0.Sample(textureSampler, uv);
    if (uv.x == 0.0 && uv.y == 0.0) {
        col = float4(0,0,0,alpha);    
    } 

    //return either alpha blended OBS scene or just selected image
    col.a = alpha;
    return lerp(rgba,col,(alpha));
	//return col;
}