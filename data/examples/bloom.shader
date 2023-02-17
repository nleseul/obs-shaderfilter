
// Bloom shader by Charles Fettinger for obs-shaderfilter plugin 3/2019
//https://github.com/Oncorporation/obs-shaderfilter

uniform int Angle_Steps = 5; //<range 1 - 20>
uniform int Radius_Steps = 9; //<range 0 - 20>
uniform float ampFactor = 2.0;
uniform string notes = "Steps limited in range from 0 to 20. Edit bloom.shader to remove limits at your own risk.";

float4 mainImage(VertData v_in) : TARGET
{
	float radiusSteps = clamp(Radius_Steps, 0, 20);
	float angleSteps = clamp(Angle_Steps, 1, 20);
	float PI = 3.1415926535897932384626433832795;//acos(-1);
	float minRadius = (0.0 * uv_pixel_interval.y);
	float maxRadius = (10.0 * uv_pixel_interval.y);

	float4 c0 = image.Sample(textureSampler, v_in.uv);
	float4 outputPixel = c0;
	float4 accumulatedColor = {0,0,0,0};

	int totalSteps = radiusSteps * angleSteps;
	float angleDelta = (2 * PI) / angleSteps;
	float radiusDelta = (maxRadius - minRadius) / radiusSteps;

	for (int radiusStep = 0; radiusStep < radiusSteps; radiusStep++) {
		float radius = minRadius + radiusStep * radiusDelta;

		for (float angle=0; angle <(2*PI); angle += angleDelta) {
			float2 currentCoord;

			float xDiff = radius * cos(angle);
			float yDiff = radius * sin(angle);
			
			currentCoord = v_in.uv + float2(xDiff, yDiff);
			float4 currentColor =image.Sample(textureSampler, currentCoord);
			float currentFraction = ((float)(radiusSteps+1 - radiusStep)) / (radiusSteps + 1);

			accumulatedColor +=   currentFraction * currentColor / totalSteps;
			
		}
	}

	outputPixel += accumulatedColor * ampFactor;

	return outputPixel;
}
