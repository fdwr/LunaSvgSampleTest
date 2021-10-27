//Input variables
shared float4x4 World;
shared float4x4 View;
shared float4x4 Projection;
//shared float4x4 worldViewProjection;
float  Alpha = 1;
float3 DiffuseColor: COLOR = float3(1,1,0);
float3 AmbientColor: COLOR = float3(0,0,1);
float3 DirectionalLight0: LIGHT = float3(1./2.5, 2./2.5, 1./2.5);

texture CubeMap
< 
    string type = "CUBE";
    //string name = "Cubemap texture";
>;
samplerCUBE CubeMapSampler = sampler_state
{
   Texture   = (CubeMap);
   ADDRESSU  = CLAMP;
   ADDRESSV  = CLAMP;
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
   float4 pos:      POSITION;
   float3 normal:   TEXCOORD0;
   //float3 posVc:  TEXCOORD1; 
   float4 color:    COLOR;
};


VS_OUTPUT VertexShader(VS_INPUT In)
{
	VS_OUTPUT Out;

	//Move to screen space
    float4x4 worldView = mul(World, View);
	float4x4 worldViewProjection = mul(worldView, Projection);
	float3 worldNormal = normalize(mul(In.normal, World));
	Out.normal = worldNormal;
	float3 color = DiffuseColor * abs(dot(worldNormal, DirectionalLight0)) + AmbientColor;
    Out.color = float4(color, Alpha);
    //Out.posVc = mul(In.pos, worldView);
	//float4x4 worldViewProjection = World * View * Projection; // must be the hadamard product?
	Out.pos = mul(In.pos, worldViewProjection);

    return Out;
}

float4 PixelShader(VS_OUTPUT In) : COLOR0
{
    //return float4(1,1,1,.5);
    //return texCUBE(CubeMapSampler, In.normal);
  	//float3 reflectVc = reflect( normalize(In.posVc), In.normal);
    
    return In.color * float4(.5,.5,.5,1) + texCUBE(CubeMapSampler, In.normal) * float4(1,1,1,0);
    //return In.color * float4(.5,.5,.5,1) + texCUBE(CubeMapSampler, reflectVc) * float4(1,1,1,0);
}

//--------------------------------------------------------------//
// Technique Section for Simple screen transform
//--------------------------------------------------------------//
technique Simple
{
   pass Single_Pass
   {
		VertexShader = compile vs_3_0 VertexShader();
		PixelShader  = compile ps_3_0 PixelShader();
   }

}
