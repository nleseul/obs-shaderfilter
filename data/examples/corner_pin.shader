// Corner Pin shader by rmanky
// --- --- ---
// Adapted from https://www.iquilezles.org/www/articles/ibilinear/ibilinear.htm
// and this Shadertoy example https://www.shadertoy.com/view/lsBSDm

uniform float _DRx;
uniform float _DRy;
uniform float _DLx;
uniform float _DLy;
uniform float _TLx;
uniform float _TLy;
uniform float _TRx;
uniform float _TRy;

float cross2d(float2 a, float2 b)
{
	return (a.x * b.y) - (a.y * b.x);
}

float2 invBilinear(float2 p)
{
    float2 a = float2(_TLx / 1000.0, _TLy / 1000.0);
    float2 b = float2(1.0 - (_TRx / 1000.0), _TRy / 1000.0);
    float2 c = float2(1.0 - (_DRx / 1000.0), 1.0 - (_DRy / 1000.0));
    float2 d = float2(_DLx / 1000.0, 1.0 - (_DLy / 1000.0));
	
    float2 e = b-a;
    float2 f = d-a;
    float2 g = a-b+c-d;
    float2 h = p-a;
	
    float k2 = cross2d( g, f );
    float k1 = cross2d( e, f ) + cross2d( h, g );
    float k0 = cross2d( h, e );
    
    float k2u = cross2d( e, g );
    float k1u = cross2d( e, f ) + cross2d( g, h );
    float k0u = cross2d( h, f);    
   
    float v1, u1, v2, u2;
    
    if (abs(k2) < 0.0001) 
    {
        v1 = -k0 / k1;
        u1 = (h.x - f.x*v1)/(e.x + g.x*v1);
    } 
    else if (abs(k2u) < 0.0001) 
    {
        u1 = k0u / k1u;
        v1 = (h.y - e.y*u1)/(f.y + g.y*u1);
    } 
    else 
    {
        float w = k1*k1 - 4.0*k0*k2;

        if( w<0.0 ) return float2(-1.0, -1.0);

        w = sqrt( w );

        v1 = (-k1 - w)/(2.0*k2);
        v2 = (-k1 + w)/(2.0*k2);
        u1 = (-k1u - w)/(2.0*k2u);
        u2 = (-k1u + w)/(2.0*k2u);
    }
    bool  b1 = v1>0.0 && v1<1.0 && u1>0.0 && u1<1.0;
    bool  b2 = v2>0.0 && v2<1.0 && u2>0.0 && u2<1.0;
    
    float2 res = float2(-1.0, -1.0);

    if( b2 ) return float2( u2, v2 );
    if( b1 ) return float2( u1, v1 );
	
    return float2(-1.0, -1.0);
}

float4 mainImage(VertData v_in) : TARGET
{
    return image.Sample(textureSampler, invBilinear(v_in.uv));
}
