Shader "Masked/Mask" 
{
 
	SubShader 
	{
		// Render the mask after regular geometry, but before masked geometry and
		// transparent things.
 
		Tags { "RenderType"="Depth" "LightMode" = "ForwardBase"}

		// Don't draw in the RGBA channels; just the depth buffer
		Cull Back
		//ColorMask 0
		//
		ZWrite On
		//Name "DEPTH"
		// Do nothing specific in the pass:
		Pass
		 {
		 	Name "DEPTH"

		 CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
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

			sampler2D _MaskingTex;
			float4 _MaskingTex_ST;

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
				return float4(0,0,0,1);
			}
			ENDCG
		}
		 
	}
}