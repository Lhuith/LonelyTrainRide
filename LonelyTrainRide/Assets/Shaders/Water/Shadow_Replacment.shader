// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/Shadow_Replacment"
{
	Properties
	{
		_MainTex("MainTexture", 2D) = "white" {}
		_Color ("Color", Color) = (1.0, 1.0, 1.0, 1.0)
	}

// First all objects that occlude other objects ...


	SubShader 
	{
	 Tags
    {
        "Queue"="AlphaTest+49"
        "IgnoreProjector"="True"
         "RenderType" = "Sparkle"
    }
    Pass
    {
        Tags {"LightMode" = "ForwardBase"}
        ZWrite On
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma multi_compile_fwdbase
     
        #include "UnityCG.cginc"
        #include "AutoLight.cginc"
        struct v2f
        {
            float4 pos : SV_POSITION;
            SHADOW_COORDS(0)
        };
     
        fixed _ShadowStrength;
        v2f vert (appdata_img v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos (v.vertex);
            TRANSFER_SHADOW(o);
            return o;
        }
        fixed4 frag (v2f i) : COLOR
        {
            fixed shadow = SHADOW_ATTENUATION(i);
            fixed shadowalpha = (1.0 - shadow) * _ShadowStrength;
            clip(shadowalpha - 0.5);
            return fixed4(0.0, 0.0, 0.0, 1.0);
        }
        ENDCG
    }
    Pass
    {
        Tags {"LightMode"="ShadowCaster"}
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma multi_compile_shadowcaster
        #include "UnityCG.cginc"
        struct v2f {
            V2F_SHADOW_CASTER;
        };
        v2f vert(appdata_base v)
        {
            v2f o;
            TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
            return o;
        }
        float4 frag(v2f i) : SV_Target
        {
            SHADOW_CASTER_FRAGMENT(i)
        }
        ENDCG
    
	}
	}
}
