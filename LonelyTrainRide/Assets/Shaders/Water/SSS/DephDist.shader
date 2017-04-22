// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Eugene/SubSurface/DephDist"
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
			//Blend SrcAlpha OneMinusSrcAlpha

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
			    o.Dist = length(mul(UNITY_MATRIX_MV, P));
				 
				return o;
			}
			 
			fixed4 frag (v2f i) : SV_Target
			{
				return float4(i.Dist.xyz / 100 ,1.0);
			}
			ENDCG 

		} 
	}
	//Fallback "Specular"
}
