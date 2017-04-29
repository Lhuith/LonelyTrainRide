Shader "Eugene/SSS/Old/DephScatter" {
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_ScatterTex("Scatter Trace", 2D) = "white" {}
		_sigma_t("Depth Value", Range(-100, 100)) = 5.0
		_Color("Color", Color) = (1,1,1,1)
		_Growth("SSS Skin Thickness", Float) = 1.0
	}

SubShader
	{
		Pass 
		{ 
			Tags { "LightMode" = "ForwardBase"}
			Cull Off 
			Blend One One
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Lighting.cginc"
			#include "Trace.cginc"
			#pragma multi_compile_fwdbase
			#define UNITY_SHADER_NO_UPGRADE 
			  
			uniform float4x4 _Light2World;
			uniform float4x4 unity_LightToWorld;
			uniform float4x4 unity_WorldToLight;
			uniform float4x4 unity_ObjectToLight;

			uniform sampler2D _CameraDepthTexture;
			uniform float _sigma_t;
			uniform float _Growth;
			uniform sampler2D _ScatterTex;
			uniform sampler2D _LightTexture0;
			uniform float4 objSpaceLightPos;
			 
			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _Color;
									
			struct v2f
			{
				float4 pos : SV_POSITION;
				float3 normal: NORMAL;
				float3 tangent : TANGENT;
				float2 uv : TEXCOORD0;
				float4 fragPos : TEXCOORD1;
				float4 wPos : TEXCOORD2;
				float3 tangentDir : TEXCOORD3;
				float3 normalDir : TEXCOORD4;
				float4 lightDir : TEXCOORD5;
				float4 mvPos : TEXCOORD6;
				float4 Dist : TEXCOORD7;
				float3 viewDir : TEXCOORD8;
				//LIGHTING_COORDS(10,11)
			};

			v2f vert (appdata_full v)
			{
				v2f o;
				o.pos =  mul(UNITY_MATRIX_MVP, v.vertex);
				o.tangent = v.tangent;
				o.normal = v.normal;
				o.wPos =  mul(unity_ObjectToWorld, v.vertex);
				o.mvPos = mul(UNITY_MATRIX_V, v.vertex);
			
				o.uv = v.texcoord;
				o.fragPos = v.vertex;
				o.normalDir = normalize(mul(unity_WorldToObject, half4(v.normal, 0.0)));
				o.viewDir = normalize(_WorldSpaceCameraPos.xyz - o.wPos.xyz);

				float4 P = v.vertex;
				P.xyz += v.normal * _Growth;  // scale vertex along normal
				o.Dist = length(UnityObjectToClipPos(P));
				 
				//TRANSFER_VERTEX_TO_FRAGMENT(o);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				i.tangentDir = normalize(mul(unity_WorldToObject, half4(i.tangent.xyz, 0.0)));
				//dyno = tex2Dlod(_DynamicTex, fixed4(v.texcoord.xy, 0.0,0.0));
	
				//i.viewDir = normalize(_WorldSpaceCameraPos.xyz - i.wPos.xyz);

				float4 lightPos = mul(i.wPos, unity_WorldToLight);

				half3 fragmentToLightSource = (_WorldSpaceLightPos0 - i.wPos.xyz);
				half3 distance = length(fragmentToLightSource);
				i.lightDir = fixed4(
				normalize(lerp(_WorldSpaceLightPos0.xyz, fragmentToLightSource, _WorldSpaceLightPos0.w)),
				lerp(.0, 1.0 / length(fragmentToLightSource), _WorldSpaceLightPos0.w));



				//fixed3 h = normalize(i.lightDir.xyz + i.wPos);

				fixed nDotl = dot(i.normalDir, i.lightDir.xyz);				
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);

				float3 objSpaceLightPos = mul(unity_WorldToLight, _WorldSpaceLightPos0).xyz;

				float zDist = dot(_WorldSpaceCameraPos - i.wPos, UNITY_MATRIX_V[2].xyz);
				float fadeDist = UnityComputeShadowFadeDistance(i.wPos, zDist);

				float si = ComputeSSS(i.normalDir, i.lightDir, i.viewDir);	
				si = mul(unity_ObjectToWorld, si);

				float ex = exp((-si) * _sigma_t); 
				float ex2 = si;
				float4 SSS = float4(ex, ex, ex, ex);
				SSS *= ex;
				return float4(1,1,1,1);// ( i.Dist.z) * (SSS/_Growth * _Color * _LightColor0); 
			
			}

			ENDCG

		} 

	}
	//Fallback "Specular"
}
