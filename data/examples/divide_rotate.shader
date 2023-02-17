// divide and rotate shader for OBS Studio shaderfilter plugin
// originally from shadertoy (https://www.shadertoy.com/view/3sy3Dh)
// Modified by Charles Fettinger (https://github.com/Oncorporation)  10/2019

uniform texture2d iChannel0;
uniform int speed_percentage = 5; //<Range(-10.0, 10.0)>
uniform int alpha_percentage = 50; //<Range(0.0, 100.0)>
uniform bool Apply_To_Alpha_Layer = true;

uniform string notes = "add rotation and speed";


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

float4 mainImage(VertData v_in) : TARGET
{
 	float alpha = clamp((float)alpha_percentage * 0.01, 0.0, 1.0);
 	float speed = clamp((float)speed_percentage * 0.01, -10.0, 10.0);

	// Normalize coords
	//float2 uv = (v_in.uv * uv_scale + uv_offset);
	float2 uv = (float2(v_in.uv.x, (1 - v_in.uv.y)) * uv_scale + uv_offset) - .5 * (v_in.uv * uv_scale + uv_offset);// / v_in.uv.y;
	float2 mouse = (v_in.uv.xy - .5 * v_in.uv.xy) / v_in.uv.y;

	// Add some time rotation and offset
    float t = elapsed_time * speed;
    float2 time = float2(sin(t), cos(t));
    uv += time;

    // Imaginary component has to be mirrored for natural feeling rotation
    mouse.y *= -1.0;

	// Draw few layers of this to bend space
    float2 rot = cm(mouse, time);
        for (float i=1.0; i<=3.0; i++) {
        uv = iter(uv, rot, 1.5);
    }

    // Combine background with new image
    float4 background_color = image.Sample(textureSampler, v_in.uv);
    float4 col = iChannel0.Sample(textureSampler, uv);

    // Border
    if (uv.x == 0.0 && uv.y == 0.0) {
        col = float4(0,0,0,alpha);    
    } 

    // if not appling to alpha layer, set output alpha
	if (Apply_To_Alpha_Layer == false)
		col.a = alpha;

    //output color is combined with background image
	col.rgb = lerp(background_color.rgb,col.rgb,clamp(alpha, 0.0, 1.0));

	return col;
}