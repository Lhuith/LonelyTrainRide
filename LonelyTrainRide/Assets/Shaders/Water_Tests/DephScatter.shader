Shader "Unlit/DephScatter"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_ScatterTex("Scatter Trace", 2D) = "white"{}
		_sigma_t("Depth Value", Range(-100, 100)) = 5.0
	}

SubShader
	{
		Pass
		{ 
			Tags { "LightMode" = "ForwardBase" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			
			uniform float4x4 _Light2World;
			uniform float4x4 _LightProjectionMatrix;
			uniform float4x4 _Object2Light;
			uniform sampler2D _CameraDepthTexture;
			uniform float4 _LightColor0;
			uniform float _sigma_t;
			 
			uniform sampler2D _ScatterTex;
			struct appdata
			{ 
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float4 fragPos : TEXCOORD10;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.fragPos = v.vertex;
				return o;
			}
			
						
			   float trace(float4 P, uniform float4x4  lightTexMatrix, // to light texture space
			            uniform float4x4  lightMatrix,    // to light space
			            uniform sampler2D DepthTex
			            )
			{

				// translate the point into light space
                 float4 PointInLightSpace = mul(lightMatrix, P );

			  // transform point into light texture space
			  
			   float4 texCoord = mul(lightTexMatrix, P);
			
			  // get distance from light at entry point
			  
			 float d_i = Linear01Depth( tex2Dproj( DepthTex, UNITY_PROJ_COORD( texCoord ) ).r );

			  // transform position to light space
			  
			   float4 Plight = mul(lightMatrix, float4(P.xyz, 1.0));
			
			  // distance of this pixel from light (exit)
			  
			   float d_o = length(Plight);
			
			  // calculate depth 
			  
			   float s = d_o - d_i;
			  return s;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);

				float si = trace(i.fragPos, _Light2World, _Object2Light , _CameraDepthTexture);
				return exp(-si * _sigma_t) * _LightColor0;
			}
			ENDCG

		} 
	}
	//Fallback "Specular"
}
