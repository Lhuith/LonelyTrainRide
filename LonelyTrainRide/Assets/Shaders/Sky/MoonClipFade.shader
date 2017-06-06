Shader "Unlit/MoonClipFade"
{
	Properties
	{
	 _MainTex ("Color (RGB) Alpha (A)", 2D) = "white"
		_AlphaCut("AlphaCutoff", Float) = 1
	    _Alpha("Alpha", Float) = 1
	}
	SubShader
	{

			
		 Tags { "Queue"="Transparent" "RenderType"="Transparent" }

		Pass
		{
			Tags{"LightMode" = "ForwardBase"}
			 Blend SrcAlpha OneMinusSrcAlpha 
					Cull Off
			ZWrite Off
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
			float _Alpha;
			float _AlphaCut;

			v2f vert (appdata_base v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{

				float LightAngle = _WorldSpaceLightPos0.y;
				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);
				float alpha = _Alpha * col.a;
				clip((col.a - _AlphaCut));

				return  float4(col.rgb, (saturate(-LightAngle + .2)) * alpha);
			}
			ENDCG
		}
	}
}
