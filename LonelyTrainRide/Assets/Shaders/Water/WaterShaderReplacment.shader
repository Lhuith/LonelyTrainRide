Shader "Eugene/Enviroment/Water/WaterShaderReplacment"
{
	Properties
	{

		_NUM_SAMPLES("Iteration Amount", Float) = 1.0
		_Weight("Iteration Weight", Float) = 1.0
		_Decay("Light Decay", Float) = 1.0
		_Exposure("Light Exposure", Float) = 1.0
		_Density("Density", Float) = 1.0
		//Basic Ocean Information
		_FrameSampler("Frame Sampler Texture", 2D) = "white" {}
		_OceanColor("Ocean Color", Color) = (1,1,1,1)
		_BumpMap("Normal Texture", 2D) = "bump" {}
		_BumpDepth("Bump Depth", Range(-100, 100.0)) = 1
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
		_FogMinHeight ("Min Fog Hight", Range(-100.0,100)) = -100.0
		_FogMaxHeight ("Max Fog Hight", Range(-100.0,100)) = 100.0
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
		_GlitterStrength("Glitter Strength", Range(-100 , 100)) = .5
		 _GlitDistanceFade("Glitter Distance Strengh", Range(-100 , 100)) = .5
		//---------------------------------------------------------------------------------
	}
	

SubShader
	{
	
		Tags { "Queue"="Transparent" "RenderType" = "Sparkle" "LightMode" = "ForwardBase"}
		Pass
		{
			Name "SPARKLE"
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
		
			uniform float _Exposure;
			uniform float _Decay;
			uniform float _NUM_SAMPLES;
			uniform sampler2D _FrameSampler;
			uniform float _Weight;
			uniform float _Density;
		
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
			
			uniform float _FogMinHeight;
			uniform float _FogMaxHeight;
		
			fixed _GlitterStrength;
			float _GlitDistanceFade;
			uniform sampler2D _BumpMap;
			uniform half4 _BumpMap_ST;
			float _BumpDepth;
			uniform half4 _LightColor0;
			// Lighting Controls
			//----------------------------------------------
		
			//-------------------------------------------
			//Depth
			sampler2D_float _CameraDepthTexture;
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
				float4 uvgrab : TEXCOORD12;
		
		
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
		
		
		fixed3 glitter(float3 pos, float3 normalDir, float3 lightDir, float3 diffuse, float3 viewVec)
		{
				float dist = distance(pos, _WorldSpaceCameraPos) / _GlitDistanceFade;
		
				normalDir.y += pos * _GlitterStrength;
				float3 specBase = diffuse * saturate(dot(reflect(-normalize(viewVec), normalDir),
				lightDir));
				// Perturb a grid pattern with some noise and with the view-vector
				// to let the glittering change with view.
				float3 fp = frac(0.9 * (pos * dist) + 9 * snoise( pos * 0.07).r + 0.09 * viewVec) ;
				fp *= (1 - fp);
				float3 glitter = saturate(1 - 9 * (fp.x + fp.y + fp.z));
				return  glitter * pow(specBase, 1.5 * length(pos.y));					
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
					
		fixed3 IBLRefl(samplerCUBE cubeMap, half detial, fixed3 worldRefl, fixed exposure, fixed reflectionFactor, fixed fresnel)
		{
			fixed4 cubeMapCol = texCUBElod(cubeMap, fixed4(worldRefl, detial)).rgba;
			return (reflectionFactor* fresnel * cubeMapCol.rgb * (cubeMapCol.a * exposure));
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
				
			w[1].freq =  _Frequency * 2;		   
			w[1].amp =   _Amplitude * 2; 	
			w[1].phase = _Phase * 2;	
			w[1].dir =   _Dir2;
			
			w[2].freq =  _Frequency* 4; 		   
			w[2].amp =   _Amplitude * 4; 	
			w[2].phase = _Phase* 4; 	
			w[2].dir =   _Dir3;
		
			o.wPos =  mul(unity_ObjectToWorld, v.vertex);
			half2 x0 = o.wPos.xz;
			float3 newPos = float3(0.0, 0.0, 0.0);
			float4 tangent = float4(0.0, 0.0, 0.0, 0.0);
			float3 binormal = float3(0.0, 0.0,0.0);
		
			for(int i = 0; i < 3; i++)
			{
				//Wave w = w;//waveBuffer[i];
				newPos += getGerstnerOffset(x0, w[i], _Time.y);
				binormal += computeBinormal(x0, w[i], _Time.y);
				tangent += float4(computeTangent(x0, w[i], _Time.y).xyz, 1.0);
			}
		
			// fix binormal and tangent
			binormal.x = 1 - binormal.x;
			binormal.z = 0 - binormal.z;
		
			tangent.x = 0 - tangent.x;
			tangent.z = 1 - tangent.z; 
			// displace vertex 
			v.vertex.x -= newPos.x;
			v.vertex.z -= newPos.z;
			v.vertex.y += newPos.y;
		
		    o.pos = UnityObjectToClipPos(v.vertex);
			o.fragPos = v.vertex;

			//o.tangentWorld =  normalize( mul( float4(tangent, 0.0), unity_ObjectToWorld));
			o.tangentWorld = normalize(mul(unity_ObjectToWorld, half4(tangent.xyz, 0.0)));

			o.binormalWorld = normalize( mul( float4(binormal.xyz, 0.0), unity_ObjectToWorld).xyz);
			o.normalDir = normalize( cross( o.tangentWorld, o.binormalWorld));
		
			o.viewDir = normalize(_WorldSpaceCameraPos.xyz - o.wPos.xyz);
			o.projPos = ComputeScreenPos (o.pos);
			
			COMPUTE_EYEDEPTH(o.projPos.z);
		
			o.uv = v.texcoord; 
		
			o.uvgrab.xy = (float2(o.pos.x, o.pos.y*-1) + o.pos.w) * 0.5;
			o.uvgrab.zw = o.pos.zw;
			o.viewDir = normalize(_WorldSpaceCameraPos.xyz - o.wPos.xyz);
			//o.pos.xyz += v.normal * _Growth;
		
			half3 eyeRay = normalize(mul(unity_WorldToObject, v.vertex.xyz));
			o.rayDir = half3(-eyeRay);
			TRANSFER_VERTEX_TO_FRAGMENT(o);		
		
			return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
		
				//Initlializing Values
				fixed4 finalColor = fixed4(0,0,0, 1.0);		
				fixed4 fadecol = fixed4(0,0,0, 0);
				
				fixed3 glitColor = fixed4(1,1,1,1.0);
				//Normal Calculations
				//------------------------------------------
				fixed4 texN = tex2D(_BumpMap, i.uv.xy * _BumpMap_ST.xy + _BumpMap_ST.zw);
				fixed4 texBloom = tex2D(_FrameSampler, i.uv.xy);
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
		
				//------------------------------------------
		
		
		
				//Light Calculations
				//------------------------------------------
				half3 fragmentToLightSource = _WorldSpaceLightPos0.xyz - i.wPos.xyz;
		
				i.lightDir = fixed4(
				normalize(lerp(_WorldSpaceLightPos0.xyz, fragmentToLightSource, _WorldSpaceLightPos0.w)),
				lerp(1.0, 1.0 / length(fragmentToLightSource), _WorldSpaceLightPos0.w));
		
				fixed nDotl = saturate(dot(normalDirection, i.lightDir.xyz));	
				

				//Lighting
				fixed3 h = normalize(i.lightDir.xyz + i.viewDir);
				fixed3 binormalDir = cross(i.normalDir, i.tangentWorld);
				
				//dotProduct
				fixed nDotL = dot(normalDirection, i.lightDir.xyz);
				fixed nDotH = dot(normalDirection, h);
				fixed nDotV = dot(normalDirection, i.viewDir);
				fixed tDotHX = dot(i.tangentWorld, h)/ _AniX;
				fixed bDotHY = dot(binormalDir, h)/ _AniY;


				fixed3 diffuseReflection = i.lightDir.w * _LightColor0.xyz * saturate(nDotl);
			    fixed3 specularReflection = (diffuseReflection * _SpecColor.xyz * pow(saturate(dot(reflect(-i.lightDir.xyz, 
											normalDirection), i.viewDir)) , _Shininess)) * _SpecStrength; 
				
				fixed3 specularAniReflection = diffuseReflection * _SpecColor.xyz * exp(-(tDotHX * tDotHX + bDotHY * bDotHY)) * _Shininess;
				
				//------------------------------------------
												
				float si = ComputeSSS(normalDirection, i.lightDir, i.viewDir);	
		
				float ex =  exp(-si * _sigma_t);	
								 				
				fixed4 SSS = float4(ex,ex,ex,ex);
				
		
				fixed3 worldRefl = reflect(-i.viewDir, normalDirection);
		
				float r = (1.2-1-0)/(1.2+1.0);
				float fresnelFactor = max(0.0, min(1.0, r+(1.0-r)*pow(1.0-dot( normalDirection, i.viewDir), _FresnelPower)));
		
				fresnelFactor *= min(length(_WorldSpaceCameraPos.xyz - i.wPos.xyz)/10.0, 1.0);
		
				fixed sceneZEye = LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos)));
				fixed partZ = i.projPos.z;
				
				fixed fade = saturate(_InvFade * (sceneZEye- partZ));
				
				float zDist = dot(_WorldSpaceCameraPos - i.wPos, UNITY_MATRIX_M[1].xyz);
				float fadeDist = UnityComputeShadowFadeDistance(i.wPos, zDist);
		
				i.uvgrab.xy = TransformStereoScreenSpaceTex(i.uvgrab.xy, i.uvgrab.w);
		
				half2 bump = UnpackNormal(tex2D( _BumpMap, TRANSFORM_TEX( i.uv, _BumpMap ))).rg; // we could optimize this by just reading the x & y without reconstructing the Z
				float2 offset = bump * 50 * _GrabTexture_TexelSize.xy;
		
				i.uvgrab.xy = offset * UNITY_Z_0_FAR_FROM_CLIPSPACE(i.uvgrab.z) + i.uvgrab.xy + normalDirection.xz;
		
				half3 refraction = tex2Dproj( _GrabTexture, UNITY_PROJ_COORD(i.uvgrab));
		        //refraction *= fade;
				
				//float3 gloss =  pow(clamp(dot(reflect(i.wPos, normalDirection), i.lightDir), 0.0, 1.0), 64.0);;

				fixed3 reflection = IBLRefl(_Cube, _Detail, worldRefl, _ReflectionExposure * fresnelFactor, 
				_ReflectionFactor * fresnelFactor, fresnelFactor);
		
				float waterDepth = max(0, i.wPos.y * fade * _WaterDepth); 		
					
				refraction = lerp(refraction, float3(1,1,1), fade);
		
				//float3 refRaf = lerp(reflection , refraction , fresnelFactor);

				fixed4 lightFinal = fixed4((specularReflection + specularAniReflection), 1.0) * fresnelFactor;		

				float3 waterColor = GetWaterColor(fade, waterDepth, refraction, 
				lightFinal + diffuseReflection);	

				float3 glitterSpec = glitter(i.wPos, normalDirection , 
				i.lightDir, ((diffuseReflection) / 24) + specularAniReflection + specularReflection, i.viewDir) * fresnelFactor;
		
				glitterSpec *= _GlitterStrength * 12;
			    return float4(glitterSpec,1) ; 
		
			}
			ENDCG
		} 
	

	}
	   //FallBack "VertexLit"
}
 