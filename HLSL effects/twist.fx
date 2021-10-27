// Dwayne Robinson
// CS519 - HW4
// Created GLSL on 2006-04-28
// Converted to HSLS 2007-06-03

float Magnitude <float low=-1; float high=5;>
	= .2;
float Undulation <float low=0; float high=50;>
	= 20;
float Twist <float low=0; float high=50;>
	= 10;
float Frequency <float low=0; float high=50;>
	= 30;
float Density <float low=0; float high=1;>
	= 1;
float Blur <float low=0; float high=.5;> // poor variable name
	= .99;
float Time = 0;

float4 Color = float4(1,1,1,1);

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

texture Texture;
sampler2D TextureSampler = sampler_state
{
   Texture   = (Texture);
   ADDRESSU  = WRAP;//CLAMP;
   ADDRESSV  = WRAP;//CLAMP;
   MAGFILTER = LINEAR;
   MINFILTER = LINEAR;
   MIPFILTER = LINEAR;
};

struct VS_INPUT
{
	float4 pos:    POSITION;
	float3 normal: NORMAL;
	float2 st:     TEXCOORD;
};


struct VS_OUTPUT
{
	float4 pos:     POSITION;
	//float4 color: COLOR;
	float2 st:             TEXCOORD0;
	float3 reflectVector:  TEXCOORD1;
	float  lightIntensity: TEXCOORD2;
};


const float PI = 3.14159;


VS_OUTPUT VertexShader(VS_INPUT In)
{
	VS_OUTPUT Out;
	
	float4x4 worldView = mul(World, View);

	Out.st = In.st;
	float4 pos = In.pos;
	float3 normal = normalize( In.normal );

	// calc displacement using twist and undulation
	float strength = sin(
		Time 
		+ In.st.x * Twist * PI
		+ In.st.y * Undulation );
	float3 displacement = normal * Magnitude * strength * strength;
	pos += float4(displacement, 0);

	// calc lighting
	float3 LightPos = float3( 5., 10., 10. );
	float3 ECposition = mul(pos, worldView).xyz;
    Out.lightIntensity  = dot( normalize(LightPos - ECposition), normal );
	if (Out.lightIntensity < 0.3)
		Out.lightIntensity = 0.3;

	// calc reflection
	Out.reflectVector = -reflect( mul(pos, worldView).xyz, normal );

	// output vars
	Out.pos = mul(pos, mul(mul(World, View), Projection));
	//Out.color = Color;
	
    return Out;
}


float4 PixelShader(VS_OUTPUT In) : COLOR
{
	float sf = frac( In.st.x * Frequency );
	float tf = frac( In.st.y * Frequency );

	float4 colorInside = texCUBE( CubeMapSampler, In.reflectVector );

	float halfDensity = Density/2;
	float sp = smoothstep( 0.5-halfDensity-Blur, 0.5-halfDensity+Blur, sf )
	        - smoothstep( 0.5+halfDensity-Blur, 0.5+halfDensity+Blur, sf );
	float tp = smoothstep( 0.5-halfDensity-Blur, 0.5-halfDensity+Blur, tf )
	        - smoothstep( 0.5+halfDensity-Blur, 0.5+halfDensity+Blur, tf );
	float4 color = lerp( colorInside, Color, sp*tp ) * In.lightIntensity;
	color.a = 1;//.8;
	return color;
}

technique Default {
	pass Single_Pass
	{
        //AlphaBlendEnable = false;
        //ZEnable = true;
        //ZWriteEnable = true;
        CullMode = None;
	
		VertexShader = compile vs_2_0 VertexShader();
		PixelShader  = compile ps_2_0 PixelShader();
	}
}
