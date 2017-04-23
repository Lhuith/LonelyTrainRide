			   float trace(float4 P,
						uniform float4x4  lightTexMatrix, // to light texture space
			            uniform float4x4  lightMatrix, //Object To light    // to light space
			            uniform sampler2D DepthTex
			            )
			{

			   float4 texCoord = mul(lightTexMatrix, P);
			
			  // get distance from light at entry point
			  
			  float d_i = LinearEyeDepth( tex2Dproj(DepthTex, UNITY_PROJ_COORD(texCoord)).r);

			  // transform position to light space
			  
			   float4 Plight = mul(lightMatrix, float4(P.xyz, 1.0));
			
			  // distance of this pixel from light (exit)
			  
			   float d_o = (length(Plight));
			
			  // calculate depth 
			  
			   float s = d_o - d_i;
			  return s;
			}
