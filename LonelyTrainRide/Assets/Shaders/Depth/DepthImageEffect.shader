Shader "Eugene/SSS/DepthImageEffect"
{
Properties
{
_MainTex("Main Texture", 2D) = "white" {}
_ThicknessTex("Thickness Texture", 2D) = "white" {}
_Color("Color", Color) = (1, 1, 1, 1)
_Sigma("Sigma", Float) = 1.0
}

SubShader
{
// No culling or depth
		Cull Off ZWrite Off ZTest Always
		Pass 
		{
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag
 
			#include "UnityCG.cginc"
 
			uniform sampler2D _MainTex;
 
			float4 frag(v2f_img i) : COLOR {
				float4 c = tex2D(_MainTex, i.uv);
				return c;
			}
			ENDCG
		}
			Pass
		{
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			
			
			sampler2D _MainTex;
			sampler2D _ThicknessTex;
			fixed3 _Color;
			float _Sigma;
			
			fixed4 frag (v2f_img  i) : SV_Target
			{
			// adapted from http://prideout.net/blog/?p=51
			float thickness = abs(tex2D(_ThicknessTex, i.uv).r);
			
			float intensity = exp(-_Sigma * thickness);
			fixed4 col = fixed4(intensity * _Color, 1);
			
			
				if (thickness <= 0.0)
				{
				 discard;
				}
			
			return col ;
			}
			ENDCG
	}
}
}