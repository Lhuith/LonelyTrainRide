Shader "Masked/Mask2" 
{
 
	SubShader 
	{
		// Render the mask after regular geometry, but before masked geometry and
		// transparent things.
 
		Tags {"RenderType"="Depth" "LightMode" = "ForwardBase"}

		// Don't draw in the RGBA channels; just the depth buffer
		Cull Off
		//ColorMask 0
		//
		//ZWrite On
		//Name "DEPTH"
		// Do nothing specific in the pass:
		Pass
		 {
		 	//Name "DEPTH"

		 CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#include "UnityCG.cginc"

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};
			v2f vert (appdata_base v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				return float4(1,1,1,1);
			}
			ENDCG
		}
		 
	}
}