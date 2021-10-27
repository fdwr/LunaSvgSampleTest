// Dwayne Robinson
// CS519 - HW6
// Created GLSL on 2006-05-10
// Converted to HSLS 2007-06-03


float waveFreq0 <int low=0; int high=100;>
	= 2;
float waveFreq1 <int low=0; int high=100;>
	= 3;
float waveFreq2 <int low=0; int high=100;>
	= 6;
float waveAmp0 <int low=0; int high=10;>
	= .7;
float waveAmp1 <int low=0; int high=10;>
	= .6;
float waveAmp2 <int low=0; int high=10;>
	= .4;
float waveTime0 <int low=-2; int high=2;>
	= 0;
float waveTime1 <int low=-2; int high=2;>
	= -1;
float waveTime2 <int low=-2; int high=2;>
	= .92;
float waveOrigX0 <int low=-1; int high=1;>
	= -.5;
float waveOrigY0 <int low=-1; int high=1;>
	= -1.1;
float waveOrigX1 <int low=-1; int high=1;>
	= -1.1;
float waveOrigY1 <int low=-1; int high=1;>
	= .4;
float waveOrigX2 <int low=-1; int high=1;>
	= 1.1;
float waveOrigY2 <int low=-1; int high=1;>
	= .9;
float userTime <int low=0; int high=2;>
	= 0;
float Time <int low=0; int high=1000000;> = 0;
float reflectivity <int low=0; int high=1;>
	= .6;
float4 Color
	= float4(0,.5,.5,1);


shared float4x4 World;
shared float4x4 View;
shared float4x4 Projection;

texture CubeMap;
samplerCUBE CubeMapSampler = sampler_state
{
   Texture   = (CubeMap);
   //ADDRESSU  = CLAMP;
   //ADDRESSV  = CLAMP;
   MAGFILTER = LINEAR;
   MINFILTER = LINEAR;
   MIPFILTER = LINEAR;
};


struct VS_INPUT
{
	float4 pos:    POSITION;
	float3 normal: NORMAL;
	//float2 st:     TEXCOORD;
};


struct VS_OUTPUT
{
	float4 pos:     POSITION;
	//float4 color: COLOR;
	//float2 st:    TEXCOORD0;
	float3 posMc: TEXCOORD0; // model coords
	float3 posWc: TEXCOORD1; // world coords
	float3 normal: TEXCOORD2; // surface normal wc
	float3 reflectWc: TEXCOORD3; // reflection vector world coords
};



VS_OUTPUT VertexShader(VS_INPUT In)
{
	VS_OUTPUT Out;

	float4x4 worldView = mul(World, View);
	//colorSurface = float3(Color);
	Out.posMc = In.pos.xyz;
	Out.posWc = mul(In.pos, worldView).xyz;
	//float3 normalMc = normalize(gl_Normal);
	Out.normal = normalize( mul(In.normal, worldView) );
	Out.reflectWc = -reflect( Out.posWc, Out.normal );
	Out.pos = mul( In.pos, mul(worldView, Projection));
	
    return Out;
}


float4 PixelShader(VS_OUTPUT In) : COLOR
{ 
	float time = userTime;
	if (time <= 0) time = Time;

	const float3 posLight0 = float3( -10, -10, 7 );
	const float PI2 = 3.14159 * 2.;

	// zero for initial values
	float height = 0.;
	float3 slope = float3(0,0,0);

	{
		float3 offset = float3(In.posMc.x - waveOrigX0, In.posMc.y - waveOrigY0, 0);
		float radius = length(offset);
		if (radius <= time-waveTime0) {
			float period = PI2 * ((radius-time) * waveFreq0);
			float waveAmp = waveAmp0;
			if (radius > 1.) waveAmp = waveAmp / (radius * radius);
			height += cos(period) * waveAmp0;
			slope += normalize(offset) * -sin(period) * waveAmp;
		}
	}

	{
		float3 offset = float3(In.posMc.x - waveOrigX1, In.posMc.y - waveOrigY1, 0);
		float radius = length(offset);
		if (radius <= time-waveTime1) {
			float period = PI2 * ((radius-time) * waveFreq1);
			float waveAmp = waveAmp1;
			if (radius > 1.) waveAmp = waveAmp / (radius * radius);
			height += cos(period) * waveAmp;
			slope += normalize(offset) * -sin(period) * waveAmp;
		}
	}

	{
		float3 offset = float3(In.posMc.x - waveOrigX2, In.posMc.y - waveOrigY2, 0);
		float radius = length(offset);
		if (radius <= time-waveTime2) {
			float period = PI2 * ((radius-time) * waveFreq2);
			float waveAmp = waveAmp2;
			if (radius > 1.) waveAmp = waveAmp / (radius * radius);
			height += cos(period) * waveAmp;
			slope += normalize(offset) * -sin(period) * waveAmp;
		}
	}
	float3 reflectWcMod = In.reflectWc + slope * .5; // modulate reflection
	slope.xy = slope.yx;
	slope.x = -slope.x;

	float diffuse = dot( normalize(posLight0 - In.posWc), In.normal + slope * .5);

	// calculate coloration
	//const float3 colorSurface = float3(1,0,0);
	float3 colorReflect = texCUBE( CubeMapSampler, reflectWcMod );
	const float3 colorAmbient = float3(.1,.1,.2);
	const float3 colorSpecular = float3(0,1.,0);
	float3 color = lerp(Color * diffuse, colorReflect, reflectivity)
		+ colorAmbient
		+ pow(diffuse,20) * colorSpecular;
	return float4(color, 1);
}


technique Default {
	pass Single_Pass
	{
        //AlphaBlendEnable = false;
        //ZEnable = true;
        //ZWriteEnable = true;
        //CullMode = None;
	
		VertexShader = compile vs_2_0 VertexShader();
		PixelShader  = compile ps_3_0 PixelShader();
	}
}
