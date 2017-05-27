// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
// Upgrade NOTE: replaced 'unity_World2Shadow' with 'unity_WorldToShadow'

Shader "Custom/PostProcess" 
{	
	CGINCLUDE
	#include "UnityCG.cginc"
	#include "AutoLight.cginc"
		
	struct v2f 
	{
		float4 pos : SV_POSITION;
		half2 uv : TEXCOORD0;
		float4 cameraRay : TEXCOORD1;
	};
	
	UNITY_DECLARE_SHADOWMAP(MyShadowMap);
 	sampler2D LowResDepth;
 	sampler2D NoiseTexture;
 	
 	float4x4 InverseProjectionMatrix;
 	float4x4 InverseViewMatrix;

 	float4 LowResDepth_TexelSize;

	float FogDensity;
	float ScatteringCoeff;
	float ExtinctionCoeff;
	float3 ShadowedFogColour;
	
	float3 LightColour;
	float  LightIntensity;
	
	float3 TerrainSize;
				
	float MaxRayDistance;
					
	v2f vert( appdata_img v ) 
	{
		v2f o; 
		o.pos = UnityObjectToClipPos(v.vertex);
		o.uv = v.texcoord;
		
		//transform clip pos to view space
		float4 clipPos = float4( v.texcoord * 2.0 - 1.0, 1.0, 1.0);
		float4 cameraRay = mul(InverseProjectionMatrix, clipPos);
		o.cameraRay = cameraRay / cameraRay.w;
		
		return o;
	}
	
	#define NUM_SAMPLES 32
	#define NUM_SAMPLES_RCP (1.0/NUM_SAMPLES)
	
	#define GRID_SIZE 8
	#define GRID_SIZE_SQR_RCP (1.0/(GRID_SIZE*GRID_SIZE))
		
	float4 frag(v2f i) : SV_Target 
	{				
		// read low res depth and reconstruct world position
		float depth = SAMPLE_DEPTH_TEXTURE(LowResDepth, i.uv);
		
		//linearise depth		
		float lindepth = Linear01Depth (depth);
		
		//get view and then world positions		
		float4 viewPos = float4(i.cameraRay.xyz * lindepth,1);
		float3 worldPos = mul(InverseViewMatrix, viewPos).xyz;	
					
		//get the ray direction in world space, raymarching is towards the camera
		float3 rayDir = normalize(_WorldSpaceCameraPos.xyz-worldPos);
		float rayDistance = length(_WorldSpaceCameraPos.xyz-worldPos);
		
		//cap raymarching distance				
		rayDistance = min(rayDistance, MaxRayDistance);
		
		//calculate step size for raymarching
		float stepSize = rayDistance * NUM_SAMPLES_RCP;
		
		//raymarch from the world point to the camera
		float3 currentPos = worldPos.xyz;
				
		// Calculate the offsets on the ray according to the interleaved sampling pattern
		float2 interleavedPos = fmod( float2(i.pos.x, LowResDepth_TexelSize.w - i.pos.y), GRID_SIZE );		
		float rayStartOffset = ( interleavedPos.y * GRID_SIZE + interleavedPos.x ) * ( stepSize * GRID_SIZE_SQR_RCP ) ;
		currentPos += rayStartOffset * rayDir.xyz;
		
		float3 result = 0;
		
		//calculate weights for cascade split selection
		float4 viewZ = -viewPos.z; 
		float4 zNear = float4( viewZ >= _LightSplitsNear ); 
		float4 zFar = float4( viewZ < _LightSplitsFar ); 
		float4 weights = zNear * zFar; 
				
		float3 litFogColour = LightIntensity * LightColour;
		
		float transmittance = 1;
		
		for(int i = 0 ; i < NUM_SAMPLES ; i++ )
		{					
			float2 noiseUV = currentPos.xz / TerrainSize.xz;
			float noiseValue = saturate( 2 * tex2Dlod(NoiseTexture, float4(10*noiseUV + 0.5*_Time.xx, 0, 0)));
			
			//modulate fog density by a noise value to make it more interesting
			float fogDensity = noiseValue * FogDensity;

			float scattering =  ScatteringCoeff * fogDensity;
			float extinction = ExtinctionCoeff * fogDensity;
				
			//calculate shadow at this sample position
			float3 shadowCoord0 = mul(unity_WorldToShadow[0], float4(currentPos,1)).xyz; 
			float3 shadowCoord1 = mul(unity_WorldToShadow[1], float4(currentPos,1)).xyz; 
			float3 shadowCoord2 = mul(unity_WorldToShadow[2], float4(currentPos,1)).xyz; 
			float3 shadowCoord3 = mul(unity_WorldToShadow[3], float4(currentPos,1)).xyz;
			
			float4 shadowCoord = float4(shadowCoord0 * weights[0] + shadowCoord1 * weights[1] + shadowCoord2 * weights[2] + shadowCoord3 * weights[3],1); 
			 
			//do shadow test and store the result			
			float shadowTerm = UNITY_SAMPLE_SHADOW(MyShadowMap, shadowCoord);				
			
			//calculate transmittance
			transmittance *= exp( -extinction * stepSize);
		
			//use shadow term to lerp between shadowed and lit fog colour, so as to allow fog in shadowed areas
			float3 fColour = lerp(ShadowedFogColour, litFogColour, shadowTerm);
			
			//accumulate light
			result += (scattering * transmittance * stepSize) * fColour;

			//raymarch towards the camera
			currentPos += rayDir * stepSize;	
		}
						
		return float4(result, transmittance);		
	}
	
	ENDCG
	SubShader 
	{
		 Pass 
		 {
			  ZTest Always Cull Off ZWrite Off

			  CGPROGRAM
			  #pragma vertex vert
			  #pragma fragment frag
			  ENDCG
		  }
	}
	Fallback off
 }
