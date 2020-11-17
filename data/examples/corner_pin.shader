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

float cross(float2 a, float2 b)
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
	
	float k2 = cross( g, f );
    float k1 = cross( e, f ) + cross( h, g );
    float k0 = cross( h, e );
	
	// if edges are parallel, use linear equation
	if( abs(k2)<0.001 )
    {
        float v = -k0/k1;
        float u  = (h.x*k1+f.x*k0) / (e.x*k1-g.x*k0);
        if( v>0.0 && v<1.0 && u>0.0 && u<1.0 ) {
			return float2( u, v );
		}
    }

	// otherwise, it's a quadratic
	float w = k1*k1 - 4.0*k0*k2;
	
	if( w < 0.0 ) {
		return float2(-1.0, -1.0);
	}
	
	w = sqrt( w );

	float ik2 = 0.5/k2;
	float v = (-k1 - w)*ik2; if( v<0.0 || v>1.0 ) v = (-k1 + w)*ik2;
	float u = (h.x - f.x*v)/(e.x + g.x*v);
	
	if( u<0.0 || u>1.0 || v<0.0 || v>1.0 ) {
		return float2(-1.0, -1.0);
	}
	return float2( u, v );
}

float4 mainImage(VertData v_in) : TARGET
{	
	return image.Sample(textureSampler, invBilinear(v_in.uv));
}