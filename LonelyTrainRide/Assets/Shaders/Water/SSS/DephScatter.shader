// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Eugene/SubSurface/DephScatter"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_ScatterTex("Scatter Trace", 2D) = "white"{}
		_sigma_t("Depth Value", Range(-100, 100)) = 5.0
		_Color("Color", Color) = (1,1,1,1)
		_Growth("SSS Skin Thickness", Float) = 1.0
	}

SubShader
	{

	Pass
		{ 
			Tags { "LightMode" = "ForwardBase" }
			Cull Off 

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			uniform sampler2D _ScatterTex;
			uniform float _Growth;

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float4 wPos : TEXCOORD1;
				float3 Dist : TEXCOORD2;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _Color;
									

			v2f vert (appdata_full v)
			{
				v2f o;

				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
				o.wPos = mul(unity_WorldToObject, v.vertex);

			    float4 P = v.vertex;
			    P.xyz += v.normal * _Growth;  // scale vertex along normal
			    o.Dist = length(UnityObjectToClipPos(P));
				 
				return o;
			}
			 
			fixed4 frag (v2f i) : SV_Target
			{
				return float4(i.Dist.xyz/ 500, 1.0);
			}
			ENDCG

			}
		Pass
		{ 
			Tags {  "LightMode" = "ForwardBase" }
			Cull Off 
						Blend One One
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "ScatterTrace.cginc"
			 
			uniform float4x4 _Light2World;
			uniform float4x4 _LightProjectionMatrix;
			uniform float4x4 _Object2Light;
			uniform float4x4 unity_WorldToLight;
			uniform sampler2D _CameraDepthTexture;
			uniform float4 _LightColor0;
			uniform float _sigma_t;
			uniform float _Growth;
			uniform sampler2D _ScatterTex;

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float4 fragPos : TEXCOORD1;
				float4 wPos : TEXCOORD2;
				float3 normal: NORMAL;
				float3 tangent : TANGENT;
				float3 tangentDir : TEXCOORD3;
				float3 normalDir : TEXCOORD4;
				float4 lightDir : TEXCOORD6;
				float4 mvPos : TEXCOORD7;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _Color;
									

			v2f vert (appdata_full v)
			{
				v2f o;
				o.tangent = v.tangent;
				o.normal = v.normal;
				o.wPos =  mul(unity_ObjectToWorld, v.vertex);
				o.mvPos = mul(UNITY_MATRIX_MV,v.vertex);
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
				o.fragPos = v.vertex;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				i.tangentDir = normalize(mul(unity_WorldToObject, half4(i.tangent.xyz, 0.0)));
				//dyno = tex2Dlod(_DynamicTex, fixed4(v.texcoord.xy, 0.0,0.0));
				i.normalDir = normalize(mul(unity_WorldToObject, half4(i.normal, 0.0)));
				//i.viewDir = normalize(_WorldSpaceCameraPos.xyz - i.wPos.xyz);

				half3 fragmentToLightSource = (_WorldSpaceLightPos0.xyz - i.fragPos.xyz);
				i.lightDir = fixed4(
				normalize(lerp(_WorldSpaceLightPos0.xyz, fragmentToLightSource, _WorldSpaceLightPos0.w)),
				lerp(.0, 1.0 / length(fragmentToLightSource), _WorldSpaceLightPos0.w));



				fixed3 h = normalize(i.lightDir.xyz + i.fragPos);

				fixed nDotl = dot(i.normalDir, i.lightDir.xyz);
				fixed pDotl = dot((i.fragPos.xyz), i.lightDir.xyz);
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				float si = trace((i.fragPos), _LightProjectionMatrix, _Light2World , _CameraDepthTexture) * pDotl * _Growth;	
				//si = mul(unity_ObjectToWorld, si);

				float ex = exp(-si * _sigma_t ); 
				float3 SSS = (ex, ex, ex);
				SSS *= ex;
				return float4(SSS,1.0) * _Color; 
			}
			ENDCG

		} 

	}
	//Fallback "Specular"
}
