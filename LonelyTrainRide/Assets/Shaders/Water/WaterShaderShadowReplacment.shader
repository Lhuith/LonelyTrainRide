// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Eugene/Enviroment/Water/WaterShaderShadowReplacment"
{
SubShader
{ 
	Tags
    {
        "Queue"="AlphaTest+49"
        "IgnoreProjector"="True"
        "RenderType"="Sparkle"
		"LightMode" = "ForwardBase"
    }
    Pass
    {
   Name "ShadowCaster"
          Tags { "LightMode" = "ShadowCaster" }
        
          Fog { Mode Off }
          ZWrite On ZTest Less Cull Off
          Offset 1, 1
          
          CGPROGRAM
 
          #pragma vertex vert
          #pragma fragment frag
          #pragma multi_compile_shadowcaster
          #pragma fragmentoption ARB_precision_hint_fastest
          
          #include "UnityCG.cginc"
 
          struct v2f
          { 
              V2F_SHADOW_CASTER;
          };
        
          v2f vert(appdata_base v)
          {
              v2f o;
              TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
              return o;
          }
        
          float4 frag(v2f i) : COLOR
          {
              SHADOW_CASTER_FRAGMENT(i)
          }
 
          ENDCG
       
   }
	
	    Pass
		{
		Tags { "LightMode" = "ShadowCaster" }
		}
	 
		}
   //Fallback "VertexLit"
}
 