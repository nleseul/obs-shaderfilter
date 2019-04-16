// Correct video colorspace BT.601 [SD] to BT.709 [HD] for HD video input
// Use this shader only if BT.709 [HD] encoded video is incorrectly matrixed to full range RGB with the BT.601 [SD] colorspace.

float4 mainImage(VertData v_in) : TARGET
{
	float4 rgba = image.Sample(textureSampler, v_in.uv);; 
	//if (v_in.uv.x < 1120 && v_in.uv.y < 630) {
	//	return rgba; // this shader does not alter SD video
	//}
	float3 s1 = rgba.rgb;
	s1 = s1.rrr * float3(0.299, -0.1495 / 0.886, 0.5) + s1.ggg * float3(0.587, -0.2935 / 0.886, -0.2935 / 0.701) + s1.bbb * float3(0.114, 0.5, -0.057 / 0.701); // RGB to Y'CbCr, BT.601 [SD] colorspace
	return float4(s1.rrr + float3(0, -0.1674679 / 0.894, 1.8556) * s1.ggg + float3(1.5748, -0.4185031 / 0.894, 0) * s1.bbb,rgba.a); // Y'CbCr to RGB output, BT.709 [HD] colorspace
}
