// Upgrade NOTE: replaced '_Projector' with 'unity_Projector'

// Upgrade NOTE: replaced '_Projector' with 'unity_Projector'

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

	//Pass
		//{ 
	//Tags { "LightMode" = "ForwardBase"}
	//Cull Off 
	////Blend One DstColor
	//CGPROGRAM
	//#pragma vertex vert
	//#pragma fragment frag
	//#include "UnityCG.cginc"
	//
	//uniform sampler2D _ScatterTex;
	//uniform float _Growth;
	//
	//struct v2f
	//{
	//	float4 vertex : SV_POSITION;
	//	float2 uv : TEXCOORD0;
	//	float4 wPos : TEXCOORD1;
	//	float3 Dist : TEXCOORD2;
	//};
	//
	//sampler2D _MainTex;
	//float4 _MainTex_ST;
	//float4 _Color;
	//						
	//
	//v2f vert (appdata_full v)
	//{
	//	v2f o;
	//
	//	o.vertex = UnityObjectToClipPos(v.vertex);
	//	o.uv = v.texcoord;
	//	o.wPos = mul(unity_WorldToObject, v.vertex);
	//
	//    float4 P = v.vertex;
	//    P.xyz += v.normal * _Growth;  // scale vertex along normal
	//    o.Dist = length(UnityObjectToClipPos(P));
	//	 
	//	return o;
	//}
	// 
	//fixed4 frag (v2f i) : SV_Target
	//{
	//	return float4(i.Dist.xyz / 500, 1.0) ;
	//}
	//ENDCG
	//
	//}
		Pass
		{ 
			Tags {  "LightMode" = "ForwardBase"}
			Cull Off
			//Blend One One
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "ScatterTrace.cginc"
			 

				//#define UNITY_SHADER_NO_UPGRADE

			uniform sampler2D _CameraDepthTexture;
			uniform float4 _LightColor0;
			uniform float _sigma_t;
			uniform float _Growth;
			uniform sampler2D _ScatterTex;

			uniform float4x4 unity_WorldToLight;
			uniform float4x4 _Light2World;
			float4x4 _Object2Light;

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 viewDir : TEXCOORD1;
				float4 fragPos : TEXCOORD2;
				float4 wPos : TEXCOORD3;
				float3 normalDir : TEXCOORD4;
				float4 lightDir : TEXCOORD5;
				float4 mvPos : TEXCOORD6;
				float4 depth : DEPTH;
				float3 normal : NORMAL;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			float4 _Color;
									

			v2f vert (appdata_full v)
			{
				v2f o;

				o.wPos =  mul(unity_ObjectToWorld, v.vertex);
				o.mvPos = mul(UNITY_MATRIX_MVP,v.vertex);
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = v.texcoord;
				o.fragPos = v.vertex;
				o.normal = v.normal;
				o.viewDir = normalize(_WorldSpaceCameraPos.xyz - o.wPos.xyz);
			
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{

				//i.tangentDir = normalize(mul(unity_WorldToObject, half4(i.tangent.xyz, 0.0)));
				//dyno = tex2Dlod(_DynamicTex, fixed4(v.texcoord.xy, 0.0,0.0));
				i.normalDir = normalize(mul(unity_WorldToObject, half4(i.normal, 0.0)));
				//i.viewDir = normalize(_WorldSpaceCameraPos.xyz - i.wPos.xyz);

				half3 fragmentToLightSource = _WorldSpaceLightPos0.xyz - i.fragPos.xyz;

				float atten = 1.0;

				i.lightDir = fixed4(
				normalize(lerp(_WorldSpaceLightPos0.xyz, fragmentToLightSource, _WorldSpaceLightPos0.w)),
				lerp(.0, 1.0 / length(fragmentToLightSource), _WorldSpaceLightPos0.w));

				fixed nDotl = dot(i.normalDir, i.lightDir.xyz);
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);

				//unity_WorldToLight
				//_Object2Light
				//_Light2World
				//_World2Light

				//float si = trace(i.fragPos, unity_WorldToLight,  _Object2Light0, _CameraDepthTexture) ;	


				
			   float4 texCoord = mul(-unity_WorldToLight, float4(i.fragPos.xyz, 1.0));
			
			  // get distance from light at entry point
			  
			  float d_i = (Linear01Depth( tex2Dproj(_CameraDepthTexture, UNITY_PROJ_COORD(texCoord)).r)) / 2;

			  // transform position to light space
			  
			   float4 Plight = mul(-unity_WorldToLight, float4(i.fragPos.xyz, 1.0));

			  // distance of this pixel from light (exit)
			  
			   float d_o = length(Plight);
						
			  // calculate depth 		  
			   float s = (d_o - d_i);

				float ex = exp((-s) * _sigma_t); 

				float3 diffuseReflection =  saturate(dot(i.normalDir, i.lightDir));
				float3 specularReflection = diffuseReflection * saturate(dot(reflect(-i.lightDir, i.normalDir), i.viewDir));

				float4 lightF = float4(specularReflection, 1.0);

				float4 SSS = float4(pow((float3(ex, ex, ex) * _Color.rgb), 4), 1) ;

				float4 depth = float4(d_i,d_i,d_i,1.0);
				
				return SSS;  
			}
			ENDCG

		} 

	}
	//Fallback "Specular"
}
