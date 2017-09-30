uniform float4 borderColor;
uniform bool bar;

float4 mainImage(VertData v_in) : TARGET
{
    //float4 borderColor = float4(0, 1, 0, 1);
    
    if (v_in.uv.x < 0 || v_in.uv.x > 1 || v_in.uv.y < 0 || v_in.uv.y > 1)
    {
        return borderColor;
    }
    else
    {
        return image.Sample(textureSampler, v_in.uv);
    }
}
