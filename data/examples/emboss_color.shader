// Color Emboss shader by Charles Fettinger for obs-shaderfilter plugin 4/2019
//https://github.com/Oncorporation/obs-shaderfilter

uniform int Angle_Steps = 9; //<range 1 - 20>
uniform int Radius_Steps = 4; //<range 0 - 20>
uniform float ampFactor = 12.0;
uniform int Up_Down_Percent = 0;
uniform bool Apply_To_Alpha_Layer = true;
uniform string notes = "Steps limited in range from 0 to 20. Edit shader to remove limits at your own risk.";

float4 mainImage(VertData v_in) : TARGET
{
	float radiusSteps = clamp(Radius_Steps, 0, 20);
	float angleSteps = clamp(Angle_Steps, 1, 20);
	float PI = 3.1415926535897932384626433832795;//acos(-1);
	int totalSteps = (radiusSteps * angleSteps);
	float minRadius = (1 * uv_pixel_interval.y);
	float maxRadius = (6 * uv_pixel_interval.y);

	float angleDelta = ((2 * PI) / angleSteps);
	float radiusDelta = ((maxRadius - minRadius) / radiusSteps);
	float embossAngle = 0.25 * PI;

	float4 c0 = image.Sample(textureSampler, v_in.uv);
	float4 origColor = c0;
	float4 accumulatedColor = {0,0,0,0};

	if (c0.a > 0.0 || Apply_To_Alpha_Layer == false)
	{
		for (int radiusStep = 0; radiusStep < radiusSteps; radiusStep++) {
			float radius = minRadius + radiusStep * radiusDelta;

			for (float angle = 0; angle < (2 * PI); angle += angleDelta) {
				float2 currentCoord;

				float xDiff = radius * cos(angle);
				float yDiff = radius * sin(angle);

				currentCoord = v_in.uv + float2(xDiff, yDiff);
				float4 currentColor = image.Sample(textureSampler, currentCoord);
				float4 colorDiff = abs(c0 - currentColor);
				float currentFraction = ((float)(radiusSteps + 1 - radiusStep)) / (radiusSteps + 1);
				accumulatedColor += currentFraction * colorDiff / totalSteps * sign(angle - PI);;

			}
		}
		accumulatedColor *= ampFactor;

		c0 = lerp(c0 + accumulatedColor, c0 - accumulatedColor, (Up_Down_Percent * 0.01));
	}
	//return c0 + accumulatedColor; // down;
	//return c0 - accumulatedColor; // up
	return c0;
}
