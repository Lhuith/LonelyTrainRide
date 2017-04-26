// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "Test/Water_Shader_Endless"
{
	Properties
	{
		//Basic Ocean Information
		_OceanColor("Ocean Color", Color) = (1,1,1,1)
		_BumpMap("Normal Texture", 2D) = "bump" {}
		_BumpDepth("Bump Depth", Range(0, 1.0)) = 1
		//---------------------------------------------------------------------------------
		//Depth Controls
		_FadeLimit("Fade Limit", Float) = 1.0
		_InvFade("Inverted Fade", Float) = 1.0
		_SubColor("Ocean SubSurface Color", Color) = (1,1,1,1)
		_sigma_t("Scatter Coeffiecant", Range(-100, 100)) = .05
		_Extinction("Extinction Color",  Color) = (0.46, 0.09,0,06)
		_ScatterTex ("Scatter Texture", 2D) = "white" {}
		_WaterDepth("Depth Of Water", Float) = 1.0
		_ScatterStrength("ScatterStrength", Float) = 1.0
		//density = 8.;
		//ss_pow = 5.; 
		//ss_scatter = 0.4;
		//ss_offset = .5;
		// 
		//trols
		//ss_intensity = 1.;
		//ss_lerp = 1.;
		//s how deep from surfac
		//surfaceThickness = 1;
		//t _InvFade;
		//t4 _SubColor;

		//---------------------------------------------------------------------------------
		//Depth Controls

		//---------------------------------------------------------------------------------
		//Lighting Controls
		_SpecColor("Specular Color", Color) = (1.0,1.0,1.0,1.0)
		_AniX("Anisotropic X", Range(0.0, 2.0)) = 1
		_AniY("Anisotropic Y", Range(0.0, 2.0)) = 1
		_Shininess("Shininess", float) = 1
		_Growth("SSS Growth", float) = 0		
		//Lighting Controls
		//---------------------------------------------------------------------------------

		//Reflection Controls
		//---------------------------------------------------------------------------------
		[KeywordEnum(Off, Refl, Refr)] _IBLMode ("IBL Mode", float) = 0
		_ReflectionFactor("Specular %", Range(0,1)) = 1
		_Cube("Cube Map", Cube) = "" {}
		_Detail("Reflection Detail", Range(1, 9)) = 1.0
		_ReflectionExposure("HDR Exposure", float) = 1.0
		_Quality("Quility Of Intersection", float) = 1.0
		//Reflection Controls
		//---------------------------------------------------------------------------------

		//---------------------------------------------------------------------------------
		//Ocean Controls
		_SineAmplitude ("Amplitude", float) = 1.0
		//the following three are vectors so we can control more than one wave easily
		_SineFrequency ("Frequency", Vector) = (1,1,0,0)
		_Speed ("Speed", Vector) = (1,1,0,0)
		_Steepness ("steepness", Vector) = (1,1,0,0)
		//two direction vectors as we are using two gerstner waves
		_Dir ("Wave Direction", Vector) = (1,1,0,0)
		_Dir2 ("2nd Wave Direction", Vector) = (1,1,0,0)
		//---------------------------------------------------------------------------------
		//Ocean Controls

		//---------------------------------------------------------------------------------
		//Glitter Controls
		_GlitterStrength("Glitter Strength", Range(0 , 1)) = .5
		//---------------------------------------------------------------------------------
	}
	
	 
SubShader
	{



	// "RenderType" = "Transperant" "Queue" = "Transparent"
		Tags {"LightMode" = "ForwardBase" }
		Cull Off 
		//Blend SrcAlpha OneMinusSrcAlpha		

		Pass
		{
			CGPROGRAM
			#pragma glsl
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#include "Sparkle.cginc"
			#include "ScatterTrace.cginc"
			#pragma fragmentoption ARB_precision_hint_fastest
			#pragma shader_feature _IBLMODE_OFF _IBLMODE_REFL _IBLMODE_REFR
			uniform fixed4 _OceanColor;
			uniform fixed4 _SubColor;

			//------------
			// Lighting Controls
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


			uniform half4 _LightColor0;

			fixed _GlitterStrength;
			//------------
			// Lighting Controls
			uniform sampler2D _BumpMap;
			uniform half4 _BumpMap_ST;
			float _BumpDepth;

			fixed _SineAmplitude;
			fixed4 _SineFrequency;
			fixed4 _Speed;
			fixed4 _Steepness;
			fixed4 _Dir;
			fixed4 _Dir2;

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
			//-------------------------------------------
			//Depth

			uniform fixed _InvFade;
			//Depth
			//-------------------------------------------

			struct v2f
			{
				fixed2 uv : TEXCOORD0;
				fixed4 pos : SV_POSITION;
				fixed4 wPos : TEXCOORD1;
				fixed4 Dist : TEXCOORD2;
				fixed3 normal : NORMAL;
				fixed4 tangent : TANGENT;
				fixed3 normalWorld : TEXCOORD3;
				fixed4 lightDir : TEXCOORD4;
				fixed3 viewDir : TEXCOORD5;
				fixed3 tangentWorld : TEXCOORD7;
				float3 binormalWorld : TEXCOORD8;
				fixed4 projPos : TEXCOORD9;
				fixed3 rayDir : TEXCOORD10;
				fixed4 fragPos : TEXCOORD11;
				float4 depth : TEXCOORD12;
				LIGHTING_COORDS(13,14)
			};

			sampler2D _MainTex;
			fixed4 _MainTex_ST;
			sampler2D _NoiseTex;
			fixed4 _NoiseTex_ST;
			fixed4 _FallOff_ST;
			sampler2D _FallOff;
			sampler2D _GlitterTex;
			uniform fixed _FadeLimit;

			//uniform fixed4x4 unity_WorldToLight;

			fixed4 blend(fixed4 A, fixed4 B) 
			{
			   fixed4 C;
			   C.a = A.a + (1 - A.a) * B.a;
			   C.rgb = (1 / C.a) * (A.a * A.rgb + (1 - A.a) * B.a * B.rgb);
			   return C;
			}

					
			fixed3 IBLRefl(samplerCUBE cubeMap, half detial, fixed3 worldRefl, fixed exposure, fixed reflectionFactor)
			{
				fixed4 cubeMapCol = texCUBElod(cubeMap, fixed4(worldRefl, detial)).rgba;
				return reflectionFactor * cubeMapCol.rgb * (cubeMapCol.a * exposure);
			}

			fixed4 GestnerWave(fixed4 Wpos, fixed4 time)
			{
				fixed2 dir = _Dir.xy;
				dir = normalize(dir) ; 
				fixed dotprod = dot(dir, Wpos.xz);
				fixed disp = (time.x * _Speed.x);
				
				//do the same for our second wave
				fixed2 dir2 = _Dir2.xy;
				dir2 = normalize(dir2);
				fixed dotprod2 = dot(dir2, Wpos.xz);
				fixed disp2 = (time.x * _Speed.y);										
				
				fixed4 vertex = fixed4(0,0,0,0);
								
				vertex.x = (_Steepness.x *_SineAmplitude) *_Dir.x * cos(_SineFrequency.x * (dotprod + disp));
				vertex.z = (_Steepness.x *_SineAmplitude) *_Dir.y * cos(_SineFrequency.x * (dotprod + disp));
				vertex.y = _SineAmplitude * - sin(_SineFrequency.x * (dotprod + disp));

				vertex.x = (_Steepness.y *_SineAmplitude) * _Dir2.x * cos(_SineFrequency.y * (dotprod2 + disp2));
				vertex.z = (_Steepness.y *_SineAmplitude) *_Dir2.y *  cos (_SineFrequency.y * (dotprod2 + disp2));
				vertex.y = _SineAmplitude * sin(_SineFrequency.y * (dotprod2 + disp2));

				return vertex;
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
			v2f vert (appdata_full v)
			{
				v2f o;	

				// float4 P = v.vertex;
				// P.xyz += v.normal * _Growth;  // scale vertex along normal
				// o.Dist = length(UnityObjectToClipPos(P));
				o.wPos =  mul(unity_ObjectToWorld, v.vertex);
				fixed4 vertNew = GestnerWave(o.wPos, _Time.y);
				v.vertex += vertNew;

			  
			    o.pos = UnityObjectToClipPos(v.vertex);
				o.tangent = v.tangent;
				o.normal = v.normal;
				o.fragPos = v.vertex;

				//v.normal += ((vertNew));

			
				o.viewDir = normalize(_WorldSpaceCameraPos.xyz - o.wPos.xyz);
				o.projPos = ComputeScreenPos (o.pos);
				
				COMPUTE_EYEDEPTH(o.projPos);
				o.uv = v.texcoord;

				
				o.viewDir = normalize(_WorldSpaceCameraPos.xyz - o.wPos.xyz);
				//o.pos.xyz += v.normal * _Growth;

				half3 eyeRay = normalize(mul(unity_WorldToObject, v.vertex.xyz));
				o.rayDir = half3(-eyeRay);
				TRANSFER_VERTEX_TO_FRAGMENT(o);

		

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				i.wPos =  mul(unity_ObjectToWorld, i.fragPos);

				i.normalWorld = normalize(mul(half4(i.normal, 0.0), unity_WorldToObject).xyz);
				i.tangentWorld = normalize(mul(unity_ObjectToWorld, i.tangent).xyz);
				i.binormalWorld = normalize(cross(i.normalWorld, i.tangentWorld) * i.tangent.w);


				half3 fragmentToLightSource = _WorldSpaceLightPos0.xyz - i.wPos.xyz;
				i.lightDir = fixed4(
				normalize(lerp(_WorldSpaceLightPos0.xyz, fragmentToLightSource, _WorldSpaceLightPos0.w)),
				lerp(1.0, 1.0 / length(fragmentToLightSource), _WorldSpaceLightPos0.w));
			
				fixed3 worldRefl = reflect(-i.viewDir, i.normalWorld.xyz);
				
				fixed worldReflAngle = dot(normalize(-i.viewDir), i.normalWorld.xyz);
				fixed worldReflightAngle = dot(normalize(_WorldSpaceLightPos0), i.normalWorld.xyz);				
				
				fixed4 finalColor = fixed4(0,0,0, 1.0);
				
				fixed3 h = normalize(i.lightDir.xyz + i.viewDir);
				fixed3 binormal = cross(i.normalWorld, i.tangentWorld);

				fixed4 texN = tex2D(_BumpMap, i.uv.xy * _BumpMap_ST.xy + _BumpMap_ST.zw);

								//unpackNormal function
				fixed3 localCoords = float3(2.0 * texN.ag - float2(1.0, 1.0),	_BumpDepth);
				
				//normal transpose matrix
				fixed3x3 local2WorldTranspose = fixed3x3(
				i.tangentWorld,
				i.binormalWorld,
				i.normalWorld
				);
				
				//calculate normal direction
				fixed3 normalDirection = normalize( mul(localCoords, local2WorldTranspose));

				//dotProdoct
				fixed nDotl = dot(i.normalWorld, i.lightDir.xyz);
				fixed nDotH = dot(i.normalWorld, h);
				fixed nDotV = dot(i.normalWorld, i.viewDir);
				fixed tDotHX = dot(i.tangentWorld, h) / _AniX;
				fixed bDotHY = dot(binormal, h) / _AniY;	
				

				fixed nNdotL = saturate(dot(normalDirection, i.lightDir.xyz));

				
				float waveThickness = saturate(mul(unity_WorldToObject, i.wPos).y * _ScatterStrength);
				
				float scatterFactor = saturate(-dot(normalDirection * waveThickness, float3(i.lightDir.x, 0, i.lightDir.y)));
				

				fixed3 diffuseReflection = i.lightDir.w * _LightColor0.xyz * saturate(nDotl);
				fixed3 specularAniReflection =  diffuseReflection * exp(-(tDotHX * tDotHX + bDotHY * bDotHY)) * _Shininess * _SpecColor;


				
			   fixed3 diffuseReflection2 = i.lightDir.w * _LightColor0.xyz * nNdotL;
			   fixed3 specularReflection2 = diffuseReflection2 * _SpecColor.xyz * pow(saturate(dot(reflect(-i.lightDir.xyz, 
											normalDirection), i.viewDir)) , _Shininess); 

				fixed3 glitColor = fixed4(1,1,1,1.0);
				
				fixed2 uv =  i.wPos.xy * 128;
				fixed fadeLR = specularAniReflection.x;
				fixed fadeTB = i.normalWorld + uv.y;
				fadeTB /= 4;
				fixed3 pos = fixed3(uv * fixed2(3., 1.) - fixed2(0., _Time.x * nDotV), _Time.x   * nDotH);
				fixed n =  (fadeLR * fadeTB * smoothstep(.8, 1., snoise(pos)) * nDotl );
				fixed col = hsv(n * .1 + .7, .4, 1.);			
							
				glitColor = ((fixed4(col * fixed3(n, n, n), n)) * _GlitterStrength) * _LightColor0;

				//unity_WorldToLight
				//_Object2Light
				float3 objSpaceLightPos = mul(unity_WorldToLight, _WorldSpaceLightPos0).xyz;
				
						
				fixed rawZ =  SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(i.projPos));
				fixed sceneZEye = EncodeFloatRGBA(saturate(LinearEyeDepth(rawZ)));
				fixed partZ = i.projPos.z;
				
				fixed fade = 1.0;
				
				if(rawZ > 0.0)
				fade = (_InvFade * ((sceneZEye) - partZ));
				
				fixed4 fadecol = fixed4(0,0,0, 0);
				
				
				
				float zDist = dot(_WorldSpaceCameraPos - i.wPos, UNITY_MATRIX_V[2].xyz);
				float fadeDist = UnityComputeShadowFadeDistance(i.wPos, zDist);
				
				float si = ComputeSSS(i.normalWorld, i.lightDir, i.viewDir);	
				
				 float ex = 0;
				 ex =  exp(si * _sigma_t) ; //* _SubColor  * (fade);
					 
				
				fixed4 SSS = float4(ex,ex,ex,ex);
				
				if(fade < _FadeLimit)
				{
					 fadecol = fade + _SubColor * (1 - fade);
				
				}
				
				fixed3 reflection = IBLRefl(_Cube, _Detail, worldRefl, _ReflectionExposure, _ReflectionFactor);

				fixed4 lightFinal = fixed4(specularAniReflection + diffuseReflection +
								UNITY_LIGHTMODEL_AMBIENT.xyz, 1.0);
				
				finalColor.rgb += _OceanColor * lightFinal;
				finalColor.rgb *= reflection;

				float4 s =  (SSS * _SubColor);
				
				float3 waterColor = GetWaterColor(zDist, _WaterDepth, float3(1,2,1),  specularReflection2); 
				
				float3 Scol =  lerp (waterColor.rgb, finalColor.rgb, scatterFactor);			

				return float4(finalColor.rgb, fade);  
			}
			ENDCG
		}

	}
	   //FallBack "VertexLit"
}
 