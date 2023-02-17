float4 mainImage(VertData v_in) : TARGET
{
	float4 rgba =image.Sample(textureSampler, v_in.uv);; 
	float3 s1 = rgba.rgb;
	s1 = float3(dot(float3(.2126, .7152, .0722), s1), dot(float3(-.1063/.9278, -.3576/.9278, .5), s1), dot(float3(.5, -.3576/.7874, -.0361/.7874), s1));
	return float4(s1.x + 1.402*s1.z, dot(s1, float3(1, -.202008 / .587, -.419198 / .587)), s1.x + 1.772*s1.y, rgba.a);
}