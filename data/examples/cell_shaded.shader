// Cell Shaded shader by Charles Fettinger for obs-shaderfilter plugin 3/2019
//https://github.com/Oncorporation/obs-shaderfilter

uniform int Angle_Steps = 5; //<range 1 - 20
uniform int Radius_Steps = 9; //<range 0 - 20
uniform float ampFactor = 2.0;

float4 mainImage(VertData v_in) : TARGET
{
	float radiusSteps = clamp(Radius_Steps, 0, 20);
	float angleSteps = clamp(Angle_Steps, 1, 20);
	float PI = 3.1415926535897932384626433832795;//acos(-1);
	int totalSteps = (radiusSteps * angleSteps);
	float minRadius = (3 * uv_pixel_interval.y);
	float maxRadius = (24 * uv_pixel_interval.y);

	float angleDelta = ((2 * PI) / angleSteps);
	float radiusDelta = ((maxRadius - minRadius) / radiusSteps);

	float4 c0 = image.Sample(textureSampler, v_in.uv);
	float4 origColor = c0;
	float4 accumulatedColor = {0,0,0,0};

	for (int radiusStep = 0; radiusStep < radiusSteps; radiusStep++) {
		float radius = minRadius + radiusStep * radiusDelta;

		for (float angle=0; angle <(2*PI); angle += angleDelta) {
			float2 currentCoord;

			float xDiff = radius * cos(angle);
			float yDiff = radius * sin(angle);
			
			currentCoord = v_in.uv + float2(xDiff, yDiff);
			float4 currentColor = image.Sample(textureSampler, currentCoord);
			float4 colorDiff = abs(c0 - currentColor);
			float currentFraction = ((float)(radiusSteps + 1 - radiusStep)) / (radiusSteps + 1);
			accumulatedColor +=  currentFraction * colorDiff / totalSteps;
			
		}
	}
	accumulatedColor *= ampFactor;

	return c0 - accumulatedColor; // Cell shaded style
}