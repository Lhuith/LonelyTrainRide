Shader "Masked/DepthMaskReplacment" 
{
 
	SubShader 
	{
		// Render the mask after regular geometry, but before masked geometry and
		// transparent things.
 
		Tags {"Queue" = "Geometry+10" "RenderType"="Depth" "LightMode" = "ForwardBase"}

		//// Don't draw in the RGBA channels; just the depth buffer
		Cull Front
		//ColorMask 0
		//
		//ZWrite On
		//Name "DEPTH"
		//// Do nothing specific in the pass:
		Pass
		 {	
		 Name "DEPTH"
		}
		 
	}
}