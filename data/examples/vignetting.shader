uniform	float innerRadius = 0.9;
uniform	float outerRadius = 1.5;
uniform	float opacity = 0.8;
uniform string notes = "inner radius will always be shown, outer radius is the falloff";

float4 mainImage(VertData v_in) : TARGET
{
	float PI = 3.1415926535897932384626433832795;//acos(-1);

	float4 c0 = image.Sample(textureSampler, v_in.uv);
	float verticalDim = 0.5 + sin (v_in.uv.y * PI) * 0.9 ;
	
	float xTrans = (v_in.uv.x * 2) - 1;
	float yTrans = 1 - (v_in.uv.y * 2);
	
	float radius = sqrt(pow(xTrans, 2) + pow(yTrans, 2));

	float subtraction = max(0, radius - innerRadius) / max((outerRadius - innerRadius), 0.01);
	float factor = 1 - subtraction;

	float4 vignetColor = c0 * factor;
	vignetColor *= verticalDim;

	vignetColor *= opacity;
	c0 *= 1-opacity;

	float4 output = c0 + vignetColor;	
	
	return output;
}
