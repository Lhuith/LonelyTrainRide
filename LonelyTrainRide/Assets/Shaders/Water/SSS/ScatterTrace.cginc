
				static float _TexSize = 2056;
			static float _Bias = 0.01;

			static float _FarClip = 100;
			static float _NearClip = 0.3;

			   float trace(float4 P, float4 W, float4x4  lightTexMatrix, // to light texture space
			            float4x4  lightObjectMatrix,    // to light space
			            sampler2D Tex,
						float ndl,
						float attenShadow,
						float3 objSpaceLightPos
			            ) 
			{

			  // transform point into light texture space
			   float4 texCoord = mul(lightTexMatrix, float4(P.xyw, 1.0)); 
		
			   	texCoord.xy /=     texCoord.w;            
				texCoord.x = 0.5 * texCoord.x + 0.5f; 
				texCoord.y = 0.5 * texCoord.y + 0.5f;

				   float depth =  texCoord.z / texCoord.w;

			  // get distance from light at entry point
			  fixed shadow = attenShadow * ndl;//UNITY_SHADOW_ATTENUATION(texCoord, W, 0);

			    // get distance from light at entry point
			   float d_i = DecodeFloatRGBA(tex2D(Tex, (fixed2(texCoord.x, texCoord.y))));
			   	float sceneDepth = _NearClip * (depth + 1.0) / (_FarClip + _NearClip - depth * (_FarClip - _NearClip));

				 float2 texelpos = _TexSize * texCoord;
				  float2 lerps = frac( texelpos );
			  	// sample shadow map
			    float dx = 1.0f / _TexSize;

				float s0 = (DecodeFloatRGBA(tex2D(Tex, texCoord.xy)) + _Bias < sceneDepth) ? 0.0f : 1.0f;
				float s1 = (DecodeFloatRGBA(tex2D(Tex, texCoord.xy + float2(dx, 0.0f))) + _Bias < sceneDepth) ? 0.0f : 1.0f;
				float s2 = (DecodeFloatRGBA(tex2D(Tex, texCoord.xy + float2(0.0f, dx))) + _Bias  < sceneDepth) ? 0.0f : 1.0f;
				float s3 = (DecodeFloatRGBA(tex2D(Tex, texCoord.xy + float2(dx, dx))) + _Bias  < sceneDepth) ? 0.0f : 1.0f;
				float shadowCoeff = lerp( lerp( s0, s1, lerps.x ), lerp( s2, s3, lerps.x ), lerps.y );
			  // transform position to light space		  
			   float3 Plight = mul(lightTexMatrix, W);
			   float3 MPlight = mul(lightTexMatrix, P);
			  // distance of this pixel from light (exit)		  
			   float d_o = length(Plight) + length(MPlight);//;+ length(W) ;//* length(shadow);
			
			  // calculate depth 
		
			   //d_o *= shadow * depth;
			
			   //unityShadowCoord3 lightCoord = mul(unity_WorldToLight, unityShadowCoord4(worldPos, 1)).xyz; \
			   //fixed shadow = UNITY_SHADOW_ATTENUATION(input, worldPos); \
			   //fixed destName = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL * shadow;

			   float s = (d_o - shadowCoeff);
			   //s = smoothstep(depth, s, ndl);
			  return  s;
			}
