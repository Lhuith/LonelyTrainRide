

			   float trace(float3 P, float4 W, float4x4  lightTexMatrix, // to light texture space
			            float4x4  lightObjectMatrix,    // to light space
			            sampler2D Tex,
						float ndl,
						float attenShadow,
						float3 objSpaceLightPos
			            ) 
			{

			  // transform point into light texture space
			   float4 texCoord = mul(lightTexMatrix, float4(W.xyw, 1.0)); 
			   texCoord /= texCoord.w;

			    texCoord.x = (texCoord.x + 1.0) / 2.0;
                texCoord.y = (texCoord.y + 1.0) / 2.0;
                texCoord.z = (texCoord.z + 1.0) / 2.0;

			  // get distance from light at entry point
			  fixed shadow = attenShadow * ndl;//UNITY_SHADOW_ATTENUATION(texCoord, W, 0);

			    // get distance from light at entry point
			  float d_i = tex2Dproj(Tex, UNITY_PROJ_COORD(fixed4(texCoord.x, 1.0 - texCoord.y, texCoord.w, texCoord.z))).r;

			  // transform position to light space		  
			   float3 Plight = mul(lightTexMatrix, W);
			 
			  // distance of this pixel from light (exit)		  
			   float d_o = length(Plight);//* length(shadow);
			
			  // calculate depth 
			   float depth = texCoord.z/100;
			   //d_o *= shadow * depth;
			
			   //unityShadowCoord3 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)).xyz; \
			   //fixed shadow = UNITY_SHADOW_ATTENUATION(input, worldPos); \
			   //fixed destName = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL * shadow;

			   float s = (d_o - d_i);
			   //s = smoothstep(depth, s, ndl);
			  return  s;
			}
