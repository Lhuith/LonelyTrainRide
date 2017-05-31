Shader "Unlit/UnderWater_Mask"
{
	Properties
	{
		_MainTex ("tex2D", 2D) = "white" {}
		_WaterMaskingTex("Water Masker", 2D) = "white" {}
		_SkyMaskingTex("Sky Masker", 2D) = "white" {}
		_DepthScatterEffects("DepthScatter Texture", 2D) = "white" {}
	}
	SubShader
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D _WaterMaskingTex;
			float4 _WaterMaskingTex_ST;

			sampler2D _SkyMaskingTex;
			float4 _SkyMaskingTex_ST;

			sampler2D _DepthScatterEffects;
			float4 _DepthScatterEffects_ST;

			v2f vert (appdata_base v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
					 float4 main = tex2D(_MainTex, i.uv);
					 float4 water = tex2D(_WaterMaskingTex, i.uv);
					 float4 sky = tex2D(_SkyMaskingTex, i.uv);
			
					 float4 full = sky * water;
					 float4 scatter = tex2D(_DepthScatterEffects, i.uv ) * full;

				     return float4(scatter) + main;
			}
			ENDCG
		}
	}
}
