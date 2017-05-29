Shader "Unlit/UnderWater_Mask"
{
	Properties
	{
		_MainTex ("tex2D", 2D) = "white" {}
		_SparkleTex("SparklerTexture", 2D) = "white" {}
		_TrainAlphaTex("TrainAlphaTexture", 2D) = "white" {}
	}
	SubShader
	{
		Pass
		{
		//ZWrite off
		Stencil 
		{
			Ref 2
			Comp always
			Pass replace
		}
		 
		 
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

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
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D _SparkleTex;
			float4 _SparkleTex_ST;

			sampler2D _TrainAlphaTex;
			float4 _TrainAlphaTex_ST;


			float2 saturate(float2 p) { return clamp(p,0.,1.); }

			float2 rot(float2 p, float a) {
				    a=radians(a);
				    return cos(a)*p + sin(a)*float2(p.y, -p.x);
				}

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
					 float4 screen = tex2D(_MainTex, i.uv);
				    return screen;
				}
			ENDCG
		}
	}
}
