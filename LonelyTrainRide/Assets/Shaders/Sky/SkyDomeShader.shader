// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Main/SkyDomeShader"
{
	Properties
	{
		//_SkyTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Tags {  "LightMode" = "ForwardBase" }
		Cull Off

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
	
	//uniform Texture2D _SkyTex;
	uniform sampler2D _SkyTex;
	uniform float4 _SkyTex_ST;

	struct v2f
	{
		float4 pos : POSITION;
		float4 tex : TEXCOORD0;
	};
	
	v2f vert(appdata_base v)
	{
		v2f o;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.tex = v.texcoord;
		return o;
	}

	fixed4 frag(v2f i) : SV_TARGET
	{
		return tex2D(_SkyTex, i.tex.xy * _SkyTex_ST.xy + _SkyTex_ST.zw);
	}



			ENDCG
		}
	}
}
