Shader "Unlit/GemBloom_Replacment"
{
	Properties
	{
		_MainTex("MainTexture", 2D) = "white" {}
		_Color ("Color", Color) = (1.0, 1.0, 1.0, 1.0)
	}

// First all objects that occlude other objects ...

//
//SubShader {
//    Tags { "RenderType"="Opaque" }
//    Pass {
//        Lighting On
//        Material {
//            Diffuse (0.0,0.0,0.0,0)
//            Ambient (0.0,0.0,0.0,0)
//        }
//    }
//}
//
//
//SubShader {
//    Tags { "RenderType"="Transparent" }
//    Pass {
//        Blend SrcAlpha OneMinusSrcAlpha
//        ZWrite Off
//        Color (0.0,0.0,0.0,0.5)
//    }
//}
//
//
//SubShader {
//    Tags { "RenderType"="TransparentCutout" }
//    Pass {
//        AlphaTest Greater [_Cutoff]
//        SetTexture[_MainTex] { constantColor(0.3,0.3,1.0,0.5) combine constant, texture }
//    }
//}

SubShader 
	{
		Tags {"RenderType"="Sparkle" "LightMode" = "ForwardBase" "Queue" = "AlphaTest"}
		UsePass "Eugene/Enviroment/Water/WaterShaderReplacment/SPARKLE"
	}

}
