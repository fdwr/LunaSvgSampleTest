// Dwayne Robinson
// CS519 - HW5
// Created GLSL on 2006-05-06
// Converted to HSLS 2007-06-03

//#define UseSt

shared float4x4 World;
shared float4x4 View;
shared float4x4 Projection;

uniform float size <float low=0.01; float high=10;>
	= 1;
uniform float frequency <float low=0; float high=100;> /// density of bumps
	= 20;
uniform float cim <float low=-2; float high=2;> /// complex imaginary constant
	= -0.125;
uniform float cre <float low=-2; float high=2;> /// complex real constant
	= .377;//.388158;
uniform float bailOut <float low=0; float high=30;> /// bail out value (stop unnecessary calculation, 4 default)
	= 4;
uniform float iterationsMax <int low=1; int high=200;> /// max iterations (30 default)
	= 130;//60;
uniform float embossAmplitude <float low=0; float high=3;> /// amount of embossing effect
	= .01;//.4;
uniform float embossDistance <float low=0; float high=.1;> /// distance between gradient sample points
	= .002;//.005;


struct VS_INPUT
{
	float4 pos:    POSITION;
	float3 normal: NORMAL;
	float2 st:     TEXCOORD;
};


struct VS_OUTPUT
{
	float4 pos:     POSITION0;
	float3 posMc:   TEXCOORD0;
	float3 posWc:   TEXCOORD1;
	float2 st:      TEXCOORD2;
	float3 normal:  TEXCOORD3;
};


VS_OUTPUT VertexShader(VS_INPUT In)
{
	VS_OUTPUT Out;
	
	// pass on position and normal for pixel shader
	Out.st = In.st;
	Out.normal = In.normal;
	float4x4 worldView = mul(World, View);
	Out.posMc = In.pos / size;
	//Out.posMc = ( In.pos + float4(0,0,-1.4,0) ) / size;
	Out.posWc = mul(In.pos, worldView);
	Out.pos = mul(In.pos, mul(worldView, Projection));
	return Out;
}

float4 PixelShader(VS_OUTPUT In) : COLOR
{
	// calculate lighting (using Phong's normal per pixel, not Gouraud)
	const float3 posLight0 = float3( 10., 15., 10. );
	//const float3 posLight1 = float3( -5., -10., -10. );
	float diffuse = dot( normalize(posLight0 - In.posWc), In.normal );
	diffuse += sin(In.posMc.x * frequency) * sin(In.posMc.z * frequency) * .1;

	// calculate julia set

	// z = [x,y], c = [creal, cimag]
	#ifdef UseSt
		float zre = In.st.x; // initialize z real
		float zim = In.st.y; // initialize z imaginary
	#else
		float zre = In.posMc.z; // initialize z real
		float zim = In.posMc.x; // initialize z imaginary
	#endif
	float bailOutSqrd = bailOut * bailOut;
	float zrs=0, zis=0;
	int iterations = 0;
	for (; iterations < iterationsMax && zrs + zis <= bailOutSqrd; iterations++) {
		// z = z^2 + c
		zrs = zre * zre;
		zis = zim * zim;
		float zri = 2.0 * zre * zim;
		zre = zrs - zis + cre;
		zim = zri + cim;
	}
	
	// use iteration count as intensity
	float magnitude = sqrt(zre*zre + zim*zim);
	float maglog = log(magnitude);
	float mu;
	// log( x<0 ) is bad, and really large numbers multiplied are bad too :)
	if (maglog <= 1) { // || infinite(maglog)) {
		mu = 0;//iterations; // log(log(e)) = 0
	} else {
		//const float ln2 = 0.69314718055994530941723212145818;
		mu = iterations + 1 - log2(maglog);
	}


#if false
	// do second pass to get gradient
	#ifdef UseSt
		zre = In.st.x - embossDistance; // initialize z real
		zim = In.st.y + embossDistance; // initialize z imaginary
	#else
		zre = In.posMc.z - embossDistance; // initialize z real
		zim = In.posMc.x + embossDistance; // initialize z imaginary
	#endif
	iterations = 0;
	zrs=0, zis=0;
	for (; iterations < iterationsMax && zrs + zis <= bailOutSqrd; iterations++) {
		// z = z^2 + c
		zrs  = zre * zre;
		zis  = zim * zim;
		float zri = 2.0 * zre * zim;
		zre = zrs - zis + cre;
		zim = zri + cim;
	}

	// use iteration count as intensity
	magnitude = sqrt(zre*zre + zim*zim);
	maglog = log(magnitude);
	float mu2;
	// log( x<0 ) is bad, and really large numbers multiplied are bad too :)
	if (maglog <= 1) { // || infinite(maglog)) {
		mu2 = 0;//iterations; // log(log(e)) = 0
	} else {
		//const float ln2 = 0.69314718055994530941723212145818;
		mu2 = iterations + 1 - log2(maglog);
	}

	// emboss by cheap gradient (only uses two points)
	float diffuseDif = log2(abs(mu2-mu)+1) * embossAmplitude;
	if (mu2 < mu) diffuseDif = -diffuseDif;
	diffuse += diffuseDif;
#endif
	diffuse += mu * embossAmplitude;

	// calculate coloration
	const float3 colorSurface = float3(1,0,0);
	const float3 colorAmbient = float3(.1,.1,.3);
	const float3 colorSpecular = float3(0,1,0);
	float3 color = colorSurface * diffuse
		+ colorAmbient
		+ diffuse * diffuse * colorSpecular;
	return float4(color , 1);//- mu * embossAmplitude);
}


technique Default {
	pass Single_Pass
	{
        AlphaBlendEnable = true;
        //ZEnable = true;
        //ZWriteEnable = true;
        //CullMode = None;
	
		VertexShader = compile vs_2_0 VertexShader();
		PixelShader  = compile ps_3_0 PixelShader();
	}
}
