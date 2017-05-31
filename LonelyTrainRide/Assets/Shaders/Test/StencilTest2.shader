Shader "Eugene/ShaderDemos/Stencils/Masks/StencilMask_2"
{
	SubShader 
	{
				// Render the mask after regular geometry, but before masked geometry and
		// transparent things.
 
		Tags {"Queue" = "Geometry+10" "RenderType"="Depth"}

		// Don't draw in the RGBA channels; just the depth buffer
		Cull Off
		ColorMask 0
		ZWrite On
		// Do nothing specific in the pass:
		Pass
		 {	
		 }
	}
}


/*
	Pass {
			Cull Front
			ZTest Less

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			ENDCG
		}
		
		Pass {
			Cull Back
			ZTest Greater

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			ENDCG
		}
		
		*/