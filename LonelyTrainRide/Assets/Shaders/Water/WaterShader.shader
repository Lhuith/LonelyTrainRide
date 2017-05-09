Shader "Eugene/Enviroment/Water/WaterShader"
{
	Properties
	{
		//Basic Ocean Information
		_OceanColor("Ocean Color", Color) = (1,1,1,1)
		_BumpMap("Normal Texture", 2D) = "bump" {}
		_BumpDepth("Bump Depth", Range(-10, 10.0)) = 1
		_AtmosDarkColor  ("Ocean Atmosheric Dark Color", Color) = (1,1,1,1)
		_AtmosBrightColor("Ocean Atmosheric Bright Color", Color) = (1,1,1,1)
		//---------------------------------------------------------------------------------
		//Depth Controls
		_FadeLimit("Fade Limit", Float) = 1.0
		_InvFade("Inverted Fade", Float) = 1.0
		_SubColor("Ocean SubSurface Color", Color) = (1,1,1,1)
		_sigma_t("Scatter Coeffiecant", Range(-100, 100)) = .05
		_Extinction("Extinction Color",  Color) = (0.46, 0.09,0,06)
		//_ScatterTex ("Scatter Texture", 2D) = "white" {}
		_WaterDepth("Depth Of Water", Float) = 1.0
		_ScatterStrength("ScatterStrength", Float) = 1.0
		_FresnelPower("Frezzy Power", Float) = 1.0
		//------------------------------------------- --------------------------------------
		//Depth Controls

		//---------------------------------------------------------------------------------
		//Lighting Controls
		_SpecColor("Specular Color", Color) = (1.0,1.0,1.0,1.0)
		//_AniX("Anisotropic X", Range(0.0, 2.0)) = 1
		//_AniY("Anisotropic Y", Range(0.0, 2.0)) = 1
		_Shininess("Shinniness", Float) = 1
		_SpecStrength("Light Strengh", Float) = 1
		_Growth("SSS Growth", Float) = 0		
		//Lighting Controls
		//---------------------------------------------------------------------------------

		//Reflection Controls
		//---------------------------------------------------------------------------------
		[KeywordEnum(Off, Refl, Refr)] _IBLMode ("IBL Mode", Float) = 1.0
		//#pragma shader_feature _IBLMODE_OFF _IBLMODE_REFL _IBLMODE_REFR

		_ReflectionFactor("Specular %", Range(0,1)) = 1
		_Cube("Cube Map", Cube) = "" {}
		_Detail("Reflection Detail", Range(1, 9)) = 1.0
		_ReflectionExposure("HDR Exposure", Float) = 1.0
		_Quality("Quility Of Intersection", Float) = 1.0
		//Reflection Controls
		//---------------------------------------------------------------------------------

		//---------------------------------------------------------------------------------
		//Ocean Controls
		_Amplitude ("Amplitude", Float) = 1.0
		_Frequency ("Frequency", Float) = 1.0
		_Speed ("Speed", Vector) = (1,1,0,0)
		_Phase ("Phase", Float) = 1.0
		_Dir ("Wave Direction", Vector) = (1,1,0,0)
		_Dir2 ("Wave Direction2", Vector) = (1,1,0,0)
		_Dir3 ("Wave Direction2", Vector) = (1,1,0,0)
		//---------------------------------------------------------------------------------
		//Ocean Controls

		//---------------------------------------------------------------------------------
		//Glitter Controls
		_GlitterStrength("Glitter Strength", Range(0 , 1)) = .5
		//---------------------------------------------------------------------------------
	}
	
Category 
{
	 	Tags { "Queue"="Transparent" "RenderType"="Opaque" }

SubShader
	{

		GrabPass { Name "BASE" Tags { "LightMode" = "Always" }} 
		Pass
		{
		Blend One OneMinusSrcAlpha
			CGPROGRAM
			#pragma glsl
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "SparkNoise.cginc"
			#include "Trace.cginc"
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma shader_feature _IBLMODE_OFF _IBLMODE_REFL _IBLMODE_REFR

			uniform fixed4 _OceanColor;
			uniform fixed4 _SubColor;

			//------------ 
			// Lighting Controls
			uniform float4 _AtmosDarkColor;
			uniform float4 _AtmosBrightColor;
			uniform samplerCUBE _Cube;
			uniform fixed _Quality;
			fixed _ReflectionFactor;
			half _Detail;
			fixed _ReflectionExposure;
			uniform float _Growth;
			uniform fixed4 _SpecColor;
			uniform fixed _AniX;
			uniform fixed _AniY;
			uniform half _Shininess;
			uniform float _SpecStrength;

			fixed _GlitterStrength;
			uniform sampler2D _BumpMap;
			uniform half4 _BumpMap_ST;
			float _BumpDepth;
			uniform half4 _LightColor0;
			// Lighting Controls
			//----------------------------------------------

			//-------------------------------------------
			//Depth
			sampler2D _CameraDepthTexture;
			fixed4 _CameraDepthTexture_TexelSize;
			sampler2D _LightTexture0;
			uniform fixed _sigma_t;
			sampler2D _ScatterTex;
			float4x4 _LightProjectionMatrix;
			float4x4 unity_ObjectToLight;
			float4x4 unity_WorldToLight;
			uniform float4 _Extinction;
			uniform float _WaterDepth;
			uniform float _ScatterStrength;
			uniform fixed _InvFade;
			uniform float _FresnelPower;
			//Depth
			//-------------------------------------------
			

			//Waves
			//------------------------------------------
			fixed  _Amplitude;
			fixed _Frequency;
			fixed _Speed;
			fixed _Phase;
			fixed2 _Dir;
			fixed2 _Dir2;
			fixed2 _Dir3;
			//Waves
			//------------------------------------------

			sampler2D _MainTex;
			fixed4 _MainTex_ST;
			sampler2D _NoiseTex;
			fixed4 _NoiseTex_ST;
			fixed4 _FallOff_ST;
			sampler2D _FallOff;
			sampler2D _GlitterTex;
			uniform fixed _FadeLimit;
			
			sampler2D _GrabTexture;
			float4 _GrabTexture_TexelSize;

			struct Wave
			{
				float  freq;
				float  amp;
				float  phase;
				float2 dir;
			};

			struct v2f
			{
				fixed4 pos : SV_POSITION;
				fixed2 uv : TEXCOORD0;
				fixed4 wPos : TEXCOORD1;
				fixed4 Dist : TEXCOORD2;
				fixed3 normalWorld : TEXCOORD3;
				fixed4 lightDir : TEXCOORD4;
				fixed3 viewDir : TEXCOORD5;
				fixed3 normalDir : TEXCOORD6;
				fixed4 tangentWorld : TEXCOORD7;
				float3 binormalWorld : TEXCOORD8;
				fixed4 projPos : TEXCOORD9;
				fixed3 rayDir : TEXCOORD10;
				fixed4 fragPos : TEXCOORD11;
				float4 depth : TEXCOORD12;
				float4 uvgrab : TEXCOORD13;
				float2 uvbump : TEXCOORD14;

				//LIGHTING_COORDS(14,15)
			};

			uniform Wave w[3];
			
			fixed4 blend(fixed4 A, fixed4 B) 
			{
			   fixed4 C;
			   C.a = A.a + (1 - A.a) * B.a;
			   C.rgb = (1 / C.a) * (A.a * A.rgb + (1 - A.a) * B.a * B.rgb);
			   return C;
			}

			// compute the gerstner offset for one wave 
			float3 getGerstnerOffset(float2 x0, Wave w, float time)
			{
				float k = length(w.dir);
				float2 x = (w.dir / k)* w.amp * sin( dot( w.dir, x0) - w.freq * time +w.phase);
				float y = w.amp * cos( dot( w.dir, x0) - w.freq*time + w.phase);
				return float3(x.x, y, x.y);
			}


		// Helper function to compute the binormal of the offset wave point
		// This comes from the taking the derivative of the Gerstner surface in the x-direction
		float3 computeBinormal(float2 x0, Wave w, float time)
		{
			float3 B = float3(0,0,0);
			half k = length(w.dir);
			B.x = w.amp * (pow(w.dir.x, 2) / k) * cos( dot(w.dir, x0) - w.freq * time + w.phase);
			B.y = -w.amp * w.dir.x * sin( dot(w.dir, x0) - w.freq * time + w.phase);
			B.z = w.amp * ((w.dir.y * w.dir.x)/ k) * cos( dot(w.dir, x0) - w.freq * time + w.phase);
			return B;
		}
		
		// Helper function to compute the tangent vector of the offset wave point
		// This comes from the taking the derivative of the Gerstner surface in the z-direction
		float3 computeTangent(float2 x0, Wave w, float time)
		{
			float3 T = float3(0, 0, 0);
			half k = length(w.dir);
			T.x = w.amp * ((w.dir.y * w.dir.x)/ k) * cos( dot(w.dir, x0) - w.freq * time + w.phase);
			T.y = -w.amp * w.dir.x * sin( dot(w.dir, x0) - w.freq * time + w.phase);
			T.z = w.amp * (pow(w.dir.y, 2) / k) * cos( dot(w.dir, x0) - w.freq * time + w.phase);
			return T;		
		}

		
		float fresnel(float3 V, float3 N)
		{	
			
			half NdotL = max( dot(V, N), 0.0);
			half fresnelBias = 0.4;
			half fresnelPow = 5.0;
			fresnelPow = _LightColor0;

			half facing  = (1.0 - NdotL);
			return max( fresnelBias + (1-fresnelBias) * pow(facing, fresnelPow), 0.0);
		}
		
		
		float3 computeSunColor(float3 V, float3 N, float3 sunDir)
		{
			float3 HalfVector = normalize( abs( V + (-sunDir)));
			return _LightColor0 * pow( abs( dot(HalfVector, N)), _LightColor0);
		}

		// primitive simulation of non-uniform atmospheric fog
		float3 CalculateFogColor(float3 pixel_to_light_vector, float3 pixel_to_eye_vector)
		{
			return lerp(_AtmosDarkColor,_AtmosBrightColor,0.5*dot(pixel_to_light_vector,-pixel_to_eye_vector)+0.5);
		}
					
		fixed3 IBLRefl(samplerCUBE cubeMap, half detial, fixed3 worldRefl, fixed exposure, fixed reflectionFactor)
		{
			fixed4 cubeMapCol = texCUBElod(cubeMap, fixed4(worldRefl, detial)).rgba;
			return reflectionFactor * cubeMapCol.rgb * (cubeMapCol.a * exposure);
		}

		fixed4 GestnerWave(fixed4 Wpos, fixed4 time)
		{				
			return float4(0,0,0,0);
		}

		float3 GetWaterColor(float accumulatedWater, float depth, float3 refractionValue, float3 incidentLight)
		{
		    // This tracks the incident light coming down, lighting up the ocean bed and then travelling back up to the surface.
		    float3 refractionAmountAtSurface = refractionValue * exp(-_Extinction * (depth + accumulatedWater));
		   // This tracks the scattering that occurs.
		   // Scattering should quickly max out with depth (since the amount of scatter added gets weaker and weaker the deewpr your go.)
		   float inverseScatterAmount = exp(-_sigma_t * accumulatedWater);
		
		   return lerp(_SubColor, refractionAmountAtSurface, inverseScatterAmount) * incidentLight;
		}

		v2f vert (appdata_base v)
		{
			v2f o;
					
			w[0].freq =  _Frequency;		   
			w[0].amp =   _Amplitude; 	
			w[0].phase = _Phase;	
			w[0].dir =   _Dir;

					
			w[1].freq =  _Frequency;		   
			w[1].amp =   _Amplitude * 2; 	
			w[1].phase = _Phase;	
			w[1].dir =   _Dir2;
			
			w[2].freq =  _Frequency;		   
			w[2].amp =   _Amplitude / 2; 	
			w[2].phase = _Phase;	
			w[2].dir =   _Dir3;

				o.wPos =  mul(unity_ObjectToWorld, v.vertex);
			    half2 x0 = o.wPos.xz;
				float3 newPos = float3(0.0, 0.0, 0.0);
				float3 tangent = float3(0, 0, 0);
				float3 binormal = float3(0, 0, 0);

				int nw = min(21, 12);

				for(int i = 0; i < 3; i++)
				{
					//Wave w = w;//waveBuffer[i];
					newPos += getGerstnerOffset(x0, w[i], _Time.y);
					binormal += computeBinormal(x0, w[i], _Time.y);
					tangent += computeTangent(x0, w[i], _Time.y);
				}

				// fix binormal and tangent
				binormal.x = 1 - binormal.x;
				binormal.z = 0 - binormal.z;

				tangent.x = 0 - tangent.x;
				tangent.z = 1 - tangent.z; 
				// displace vertex 
				v.vertex.x -= newPos.x;
				v.vertex.z -= newPos.z;
				v.vertex.y = newPos.y;

		    o.pos = UnityObjectToClipPos(v.vertex);
			//o.tangent.xyz = tangent;
			//o.normal = v.normal;
			o.fragPos = v.vertex;

			o.tangentWorld =  normalize( mul( float4(tangent, 0.0), unity_ObjectToWorld));
			o.binormalWorld = normalize( mul( float4(binormal.xyz, 0.0), unity_ObjectToWorld).xyz);
			o.normalDir = normalize( cross( o.tangentWorld, o.binormalWorld) * o.tangentWorld.w);
			//v.normal += ((vertNew));

		
			o.viewDir = normalize(_WorldSpaceCameraPos.xyz - o.wPos.xyz);
			o.projPos = ComputeScreenPos (o.pos);
			
			COMPUTE_EYEDEPTH(o.projPos);

			o.uv = v.texcoord; 

			o.uvgrab.xy = (float2(o.pos.x, o.pos.y*-1) + o.pos.w) * 0.5;
			o.uvgrab.zw = o.pos.zw;
			o.uvbump = TRANSFORM_TEX( v.texcoord, _BumpMap );
			o.viewDir = normalize(_WorldSpaceCameraPos.xyz - o.wPos.xyz);
			//o.pos.xyz += v.normal * _Growth;
	
			half3 eyeRay = normalize(mul(unity_WorldToObject, v.vertex.xyz));
			o.rayDir = half3(-eyeRay);
			TRANSFER_VERTEX_TO_FRAGMENT(o);		

			return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{

			
				fixed4 texN = tex2D(_BumpMap, i.uv.xy * _BumpMap_ST.xy + _BumpMap_ST.zw);

								//unpackNormal function
				fixed3 localCoords = float3(2.0 * texN.ag - float2(1.0, 1.0),	_BumpDepth);
				
				//normal transpose matrix
				fixed3x3 local2WorldTranspose = fixed3x3(
				i.tangentWorld.xyz,
				i.binormalWorld,
				i.normalDir
				);
				
				//calculate normal direction
				fixed3 normalDirection = normalize( mul(localCoords, local2WorldTranspose));

				half3 fragmentToLightSource = _WorldSpaceLightPos0.xyz - i.wPos.xyz;

				i.lightDir = fixed4(
				normalize(lerp(_WorldSpaceLightPos0.xyz, fragmentToLightSource, _WorldSpaceLightPos0.w)),
				lerp(1.0, 1.0 / length(fragmentToLightSource), _WorldSpaceLightPos0.w));
			
				fixed3 worldRefl = reflect(-i.viewDir, normalDirection);
				
				fixed worldReflAngle = dot(normalize(-i.viewDir), normalDirection);
				fixed worldReflightAngle = dot(normalize(_WorldSpaceLightPos0), normalDirection);				
				
				fixed4 finalColor = fixed4(0,0,0, 1.0);

				fixed nDotl = saturate(dot(normalDirection, i.lightDir.xyz));
				
				float waveThickness = saturate(mul(unity_WorldToObject, i.wPos).y * _ScatterStrength);
				
				float scatterFactor = saturate(-dot(normalDirection * waveThickness, float3(i.lightDir.x, 0, i.lightDir.y)));
				
				float r = (1.2-1-0)/(1.2+1.0);
				float fresnelFactor = max(0.0, min(1.0, r+(1.0-r)*pow(1.0-dot( normalDirection, i.viewDir), _FresnelPower)));

				fresnelFactor *= min(length(_WorldSpaceCameraPos.xyz - i.wPos.xyz)/10.0, 1.0);

				fixed3 diffuseReflection = i.lightDir.w * _LightColor0.xyz * saturate(nDotl);
			    fixed3 specularReflection = (diffuseReflection * _SpecColor.xyz * pow(saturate(dot(reflect(-i.lightDir.xyz, 
											normalDirection), i.viewDir)) , _Shininess)) * _SpecStrength; 

				fixed3 glitColor = fixed4(1,1,1,1.0);
				
				fixed2 uv =  i.wPos.xy * 128;
				fixed fadeLR = specularReflection.x;
				fixed fadeTB = i.normalDir + uv.y;
				fadeTB /= 4;
				fixed3 pos = fixed3(uv * fixed2(3., 1.) - fixed2(0., _Time.x * nDotl), _Time.x   * nDotl);
				fixed n =  (fadeLR * fadeTB * smoothstep(.8, 1., snoise(pos)) * nDotl );
				fixed col = hsv(n * .1 + .7, .4, 1.);			
							
				glitColor = ((fixed4(col * fixed3(n, n, n), n)) * _GlitterStrength) * _LightColor0;

				//unity_WorldToLight
				//_Object2Light
				float3 objSpaceLightPos = mul(unity_WorldToLight, _WorldSpaceLightPos0).xyz;
				
						
				fixed rawZ =  SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos));
				fixed sceneZEye = ((LinearEyeDepth(rawZ)));
				fixed partZ = i.projPos.z;
				
				fixed fade = 1.0;
				
				if(rawZ > 0.0)
				fade = (_InvFade * ((sceneZEye) - partZ));
				
				fixed4 fadecol = fixed4(0,0,0, 0);				
				
				float zDist = dot(_WorldSpaceCameraPos - i.wPos, UNITY_MATRIX_M[1].xyz);
				float fadeDist = UnityComputeShadowFadeDistance(i.wPos, zDist);
				
				float si = ComputeSSS(i.normalWorld, i.lightDir, i.viewDir);	
				
				 float ex = 0;
				 ex =  exp(si * _sigma_t);
					 
				
				fixed4 SSS = float4(ex,ex,ex,ex);
				
				if(fade < _FadeLimit)
				{
					 fadecol = fade + _SubColor * (1 - fade);
				
				}
				
				i.uvgrab.xy = TransformStereoScreenSpaceTex(i.uvgrab.xy, i.uvgrab.w);

				half2 bump = UnpackNormal(tex2D( _BumpMap, i.uvbump)).rg; // we could optimize this by just reading the x & y without reconstructing the Z
				float2 offset = bump * 50 * _GrabTexture_TexelSize.xy;

				//i.uvgrab.xy = offset * UNITY_Z_0_FAR_FROM_CLIPSPACE(i.uvgrab.z) + i.uvgrab.xy + normalDirection.xz;
	
				half4 Fraccol = tex2Dproj( _GrabTexture, UNITY_PROJ_COORD(i.uvgrab));

				fixed3 reflection = IBLRefl(_Cube, _Detail * fresnelFactor, (worldRefl * fresnelFactor), _ReflectionExposure, _ReflectionFactor) * fresnelFactor;
			
				fixed4 lightFinal = fixed4((specularReflection + diffuseReflection * reflection), 1.0);

				float4 subSurface =  (SSS * _SubColor);

				float waterDepth = max(0, length(_WorldSpaceCameraPos.xyz - i.wPos.xyz) * _WaterDepth) * (nDotl) ;			
	
				float3 waterColor = GetWaterColor(1.0 - fadeDist / 50, waterDepth, float3(1,2,1), (nDotl) + specularReflection ); 
				//float4(waterColor + Fraccol + lightFinal + reflection, 1.0);  
				//glitColor += waterColor;
				//waterColor *= lightFinal;
				float lightAlpha = (1.0 - (waterColor.g * waterColor.b) * nDotl);

				reflection = lerp(waterColor, reflection, fresnelFactor);

				return float4((waterColor.rgb) + lightFinal + scatterFactor + glitColor, lightAlpha);  

			}
			ENDCG
		} 
		}

	}
	   FallBack "VertexLit"
}
 