// zoom blur shader by Charles Fettinger for obs-shaderfilter plugin 3/2019
// https://github.com/Oncorporation/obs-shaderfilter
// https://github.com/dinfinity/mpc-pixel-shaders/blob/master/PS_Zoom%20Blur.hlsl 
//for Media Player Classic HC or BE
uniform int samples = 64;
uniform float magnitude = 0.5;
uniform string notes;


float4 mainImage(VertData v_in) : TARGET
{
	float PI = 3.1415926535897932384626433832795;//acos(-1);
	float4 c0 = image.Sample(textureSampler, v_in.uv);

	float xTrans = (v_in.uv.x*2)-1;
	float yTrans = 1-(v_in.uv.y*2);
	
	float angle = atan(yTrans/xTrans) + PI;
	if (sign(xTrans) == 1) {
		angle+= PI;
	}
	float radius = sqrt(pow(xTrans,2) + pow(yTrans,2));

	float2 currentCoord;
	float4 accumulatedColor = {0,0,0,0};

	float4 currentColor = image.Sample(textureSampler, currentCoord);
	accumulatedColor = currentColor;

	accumulatedColor = c0/samples;
	for(int i = 1; i< samples; i++) {
		float currentRadius ;
		// Distance to center dependent
		currentRadius = max(0,radius - (radius/1000 * i * magnitude));

		// Continuous;
		// currentRadius = max(0,radius - (0.0004 * i));

		currentCoord.x = (currentRadius * cos(angle)+1.0)/2.0;
		currentCoord.y = -1* ((currentRadius * sin(angle)-1.0)/2.0);

		float4 currentColor = image.Sample(textureSampler, currentCoord);
		accumulatedColor += currentColor/samples;
		
	}

	return accumulatedColor;
}