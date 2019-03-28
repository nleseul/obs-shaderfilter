
// Selective Color shader by Charles Fettinger for obs-shaderfilter plugin 3/2019
//https://github.com/Oncorporation/obs-shaderfilter
uniform float cutoffR = 0.40;
uniform float cutoffG = 0.025;
uniform float cutoffB = 0.25;
uniform float cutoffY = 0.25;
uniform float acceptanceAmplification = 5.0;

uniform bool showR = true;
uniform bool showG = true;
uniform bool showB = true;
uniform bool showY = true;
uniform string notes = "defaults: .4,.03,.25,.25, 5.0, true,true, true, true. cuttoff higher = less color, 0 = all 1 = none";

float4 mainImage(VertData v_in) : TARGET
{
	float PI = 3.1415926535897932384626433832795;//acos(-1);
	float4 color = image.Sample(textureSampler, v_in.uv);

	float luminance = (color.r + color.g + color.b)/3;
	float4 gray = {luminance,luminance,luminance, 1};

	float redness		= max ( min ( color.r - color.g , color.r - color.b ) / color.r , 0);
	float greenness		= max ( min ( color.g - color.r , color.g - color.b ) / color.g , 0);
	float blueness		= max ( min ( color.b - color.r , color.b - color.g ) / color.b , 0);
	
	float rgLuminance = (color.r*1.4 + color.g*0.6)/2;
	float rgDiff = abs(color.r-color.g)*1.4;

 	float yellowness = 0.1 + rgLuminance * 1.2 - color.b - rgDiff;

	float4 accept;
	accept.r  = showR * (redness - cutoffR);
	accept.g  = showG * (greenness - cutoffG);
	accept.b  = showB * (blueness - cutoffB);
	accept[3] = showY * (yellowness - cutoffY);

	float acceptance = max (accept.r, max(accept.g, max(accept.b, max(accept[3],0))));
	float modAcceptance = min (acceptance * acceptanceAmplification, 1);

	float4 result;
	result = modAcceptance * color + (1.0-modAcceptance) * gray;
	//	result = float4(redness, greenness,blueness,1);

	return result;
}