// zoom blur shader by Charles Fettinger for obs-shaderfilter plugin 3/2019
// https://github.com/Oncorporation/obs-shaderfilter
// https://github.com/dinfinity/mpc-pixel-shaders/blob/master/PS_Zoom%20Blur.hlsl 
//for Media Player Classic HC or BE
uniform int samples = 32;
uniform float magnitude = 0.5;
uniform int speed_percent = 0;
uniform bool ease;
uniform bool glitch;
uniform string notes = "Speed Percent above zero will animate the zoom. Keep samples low to save power";

float EaseInOutCircTimer(float t,float b,float c,float d){
	t /= d/2;
	if (t < 1) return -c/2 * (sqrt(1 - t*t) - 1) + b;
	t -= 2;
	return c/2 * (sqrt(1 - t*t) + 1) + b;	
}

float Styler(float t,float b,float c,float d,bool ease)
{
	if (ease) return EaseInOutCircTimer(t,0,c,d);
	return t;
}

float4 mainImage(VertData v_in) : TARGET
{
	float speed = (float)speed_percent * 0.01;

	// circular easing variable
	float t = 1.0 + sin(elapsed_time * speed);
	float b = 0.0; //start value
	float c = 2.0; //change value
	float d = 2.0; //duration

	if (glitch) t = clamp(t + ((rand_f *2) - 1), 0.0,2.0);

	b = Styler(t, 0, c, d, ease);
	float sample_speed = max((float)samples * b, 1.0);

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

	accumulatedColor = c0/sample_speed;
	for(int i = 1; i< sample_speed; i++) {
		float currentRadius ;
		// Distance to center dependent
		currentRadius = max(0,radius - (radius/1000 * i * magnitude * b));

		// Continuous;
		// currentRadius = max(0,radius - (0.0004 * i));

		currentCoord.x = (currentRadius * cos(angle)+1.0)/2.0;
		currentCoord.y = -1* ((currentRadius * sin(angle)-1.0)/2.0);

		float4 currentColor = image.Sample(textureSampler, currentCoord);
		accumulatedColor += currentColor/sample_speed;
		
	}

	return accumulatedColor;
}
