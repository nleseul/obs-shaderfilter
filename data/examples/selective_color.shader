// Selective Color shader by Charles Fettinger for obs-shaderfilter plugin 3/2019
//https://github.com/Oncorporation/obs-shaderfilter
//updated 4/13/2020: take into account the opacity/alpha of input image		-thanks Skeletonbow for suggestion

uniform float cutoff_Red = 0.40;
uniform float cutoff_Green = 0.025;
uniform float cutoff_Blue = 0.25;
uniform float cutoff_Yellow = 0.25;
uniform float acceptance_Amplifier = 5.0;

uniform bool show_Red = true;
uniform bool show_Green = true;
uniform bool show_Blue = true;
uniform bool show_Yellow = true;
uniform string notes = "defaults: .4,.03,.25,.25, 5.0, true,true, true, true. cuttoff higher = less color, 0 = all 1 = none. Valid Background Types: 0 = Grey, 1 = Luma, 2 = White, 3 = Black, 4 = Transparent, 5 = Background Color ";
uniform int background_type = 0;

float4 mainImage(VertData v_in) : TARGET
{
	const float PI		= 3.1415926535897932384626433832795;//acos(-1);
	const float3 coefLuma = float3(0.2126, 0.7152, 0.0722);
	float4 color		= image.Sample(textureSampler, v_in.uv);

	float luminance 	= dot(coefLuma, color.rgb);	
	float4 gray			= float4(luminance, luminance, luminance, 1.0);

	 [branch] if (background_type == 0)
	 {
	 	luminance		= (color.r + color.g + color.b) * 0.3333;
	 	gray 			= float4(luminance,luminance,luminance, 1.0);
	 }	 	
	 //[branch] if (background_type == 1)
	 //{
	 //	gray 			= float4(luminance,luminance,luminance, 1.0);
	 //}
	 [branch] if (background_type == 2)
	 	gray 			= float4(1.0,1.0,1.0,1.0);
	 [branch] if (background_type == 3)
	 	gray 			= float4(0.0,0.0,0.0,1.0);
	 [branch] if (background_type == 4)
	 	gray.a 			=  0.01;
	 [branch] if (background_type == 5)
	 	gray 			= color;

	float redness		= max ( min ( color.r - color.g , color.r - color.b ) / color.r , 0);
	float greenness		= max ( min ( color.g - color.r , color.g - color.b ) / color.g , 0);
	float blueness		= max ( min ( color.b - color.r , color.b - color.g ) / color.b , 0);
	
	float rgLuminance	= (color.r*1.4 + color.g*0.6)/2;
	float rgDiff		= abs(color.r-color.g)*1.4;

 	float yellowness	= 0.1 + rgLuminance * 1.2 - color.b - rgDiff;

	float4 accept;
	accept.r			= show_Red * (redness - cutoff_Red);
	accept.g			= show_Green * (greenness - cutoff_Green);
	accept.b			= show_Blue * (blueness - cutoff_Blue);
	accept[3]			= show_Yellow * (yellowness - cutoff_Yellow);

	float acceptance	= max (accept.r, max(accept.g, max(accept.b, max(accept[3],0))));
	float modAcceptance	= min (acceptance * acceptance_Amplifier, 1);

	float4 result = color;
	if (result.a > 0) {
		result		= modAcceptance * color + (1.0 - modAcceptance) * gray;
		//result.a 		*= gray.a;
	}

	return result;
}
