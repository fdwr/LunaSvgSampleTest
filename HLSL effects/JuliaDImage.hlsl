Texture2D InputTexture : register(t0);

static const float frequency <float low=0; float high=100;> /// density of bumps
	= 20;
static const float cim <float low=-2; float high=2;> /// complex imaginary constant
	= -0.125;
static const float cre <float low=-2; float high=2;> /// complex real constant
	= .377;//.388158;
static const float bailOut <float low=0; float high=30;> /// bail out value (stop unnecessary calculation, 4 default)
	= 4;
static const float iterationsMax <int low=1; int high=200;> /// max iterations (30 default)
	= 60;//130;
static const float embossAmplitude <float low=0; float high=3;> /// amount of embossing effect
	= .02;//.4;


// Use a linear sampler
SamplerState LinearSampler : register(s0);

cbuffer constants : register(b0)
{
    float spiralStrength : packoffset(c0.x);
    float2 angleFrequency : packoffset(c0.y);
    float2 center : packoffset(c1);
};

float4 TwistedSwirlPixelShader(
    float4 pos      : SV_POSITION,
    float4 posScene : SCENE_POSITION,
    float4 uv0      : TEXCOORD0
    ) : SV_Target
{
	// calculate lighting (using Phong's normal per pixel, not Gouraud)
	const float4 posLight0 = float4( 10., 15., 10., 0);
	float4 normal = float4(0.5, 0.5, 0.7, 0);
	float diffuse = dot( normalize(posLight0 - pos + float4(center, 0, 0)), normal );
	diffuse += sin((pos.x - 256) * frequency / 500 ) * sin((pos.y - 256) * frequency / 500) * .2;

	// calculate julia set

	// z = [x,y], c = [creal, cimag]
	float zre = (pos.y - 256) / 512; // initialize z real
	float zim = (pos.x - 256) / 512; // initialize z imaginary

	float bailOutSqrd = bailOut * bailOut;
	float zrs=0, zis=0;
	int iterations = 0;
	for (; iterations < iterationsMax && zrs + zis <= bailOutSqrd; iterations++) {
		// z = z^2 + c
		zrs = zre * zre;
		zis = zim * zim;
		float zri = 2.0 * zre * zim;
		//zre = zrs - zis + cre;
		//zim = zri + cim;
		zre = zrs - zis + center.y / 2000;
		zim = zri + center.x / 2000;
	}

	// use iteration count as intensity
	float magnitude = sqrt(zre*zre + zim*zim);
	float maglog = log(magnitude);
	float mu;
	// log( x<0 ) is bad, and really large numbers multiplied are bad too :)
	if (maglog <= 1) { // || infinite(maglog))
		mu = iterations - maglog*10;// log(log(e)) = 0
	} else {
		//const float ln2 = 0.69314718055994530941723212145818;
		mu = iterations + 1 - log2(maglog);
	}

	diffuse += mu * embossAmplitude;

	// calculate coloration
	const float3 colorSurface = float3(1,0,0);
	const float3 colorAmbient = float3(.1,.1,.3);
	const float3 colorSpecular = float3(0,1,0);
	float3 color = colorSurface * diffuse
		+ colorAmbient
		+ colorSpecular * diffuse * diffuse;
	return float4(color , 1);//- mu * embossAmplitude);
}



/*
Try the following:

-1325
93.5

-1312
90



cool:
141
-1503


also neat:
-276
-1550


bright:
47
618

spiral:
-984
630

*/
