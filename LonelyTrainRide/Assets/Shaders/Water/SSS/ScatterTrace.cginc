			   float trace(float3 P, uniform float4x4  lightTexMatrix, // to light texture space
			            uniform float4x4  lightMatrix,    // to light space
			            uniform sampler2D DepthTex
			            )
			{

			  // transform point into light texture space
			  
			   float4 texCoord = mul(lightTexMatrix, P);
			
			  // get distance from light at entry point
			  
			 float d_i = Linear01Depth( tex2Dproj( DepthTex, UNITY_PROJ_COORD( texCoord ) ).r );

			  // transform position to light space
			  
			   float4 Plight = mul(lightMatrix, float4(P.xyz, 1.0));
			
			  // distance of this pixel from light (exit)
			  
			   float d_o = length(Plight);
			
			  // calculate depth 
			  
			   float s = d_o - d_i;
			  return s;
			}
