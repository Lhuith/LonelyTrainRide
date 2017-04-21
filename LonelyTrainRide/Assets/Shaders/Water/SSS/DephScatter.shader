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
		_Grow("SSS Skin Thickness", Float) = 1.0
	}

SubShader
	{

	Pass
		{ 
			Tags { "LightMode" = "ForwardBase" }
			Cull Off 
			//Blend DstColor Zero 

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
			    o.Dist = length(UnityObjectToClipPos(v.vertex));
				 
				return o;
			}
			 
			fixed4 frag (v2f i) : SV_Target
			{
				return float4(i.Dist.xyz, 1.0);
			}
			ENDCG

			}
		Pass
		{ 
			Tags {  "LightMode" = "ForwardBase" }
			Cull Off 
			Blend DstColor Zero 
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
				//_Object2Light
				//_Light2World
			uniform sampler2D _CameraDepthTexture;
			uniform float4 _LightColor0;
			uniform float _sigma_t;
			 
			uniform sampler2D _ScatterTex;

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float4 fragPos : TEXCOORD1;
				float4 wPos : TEXCOORD2;
				float3 normal: NORMAL;
				float3 tangent : TANGENT;
				float3 tangentDir : TEXCOORD3;
				float3 normalDir : TEXCOORD4;
				float3 viewDir : TEXCOORD5;
				float4 lightDir : TEXCOORD6;
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

				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
				o.fragPos = v.vertex;
				o.wPos = mul(unity_WorldToObject, v.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				i.tangentDir = normalize(mul(unity_WorldToObject, half4(i.tangent.xyz, 0.0)));
				//dyno = tex2Dlod(_DynamicTex, fixed4(v.texcoord.xy, 0.0,0.0));
				i.normalDir = normalize(mul(unity_WorldToObject, half4(i.normal, 0.0)));
				i.viewDir = normalize(_WorldSpaceCameraPos.xyz - i.wPos.xyz);

				half3 fragmentToLightSource = _WorldSpaceLightPos0.xyz - i.wPos.xyz;
				i.lightDir = fixed4(
				normalize(lerp(_WorldSpaceLightPos0.xyz, fragmentToLightSource, _WorldSpaceLightPos0.w)),
				lerp(1.0, 1.0 / length(fragmentToLightSource), _WorldSpaceLightPos0.w));

				fixed nDotl = dot(i.normalDir, i.lightDir.xyz);
				fixed pDotl = dot(i.wPos, -i.lightDir.xyz);
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);

					//unity_WorldToLight
				//_Object2Light
				//_Light2World
			//_LightProjectionMatrix
				float si = trace(i.vertex, _LightProjectionMatrix, unity_WorldToLight , _CameraDepthTexture);
				float4 SSS = float4(0,0,0,0);
				float ex = exp(-si * _sigma_t); 
				SSS = (ex, ex, ex, ex) ;
				return SSS * _Color;
			}
			ENDCG

		} 

	}
	//Fallback "Specular"
}
