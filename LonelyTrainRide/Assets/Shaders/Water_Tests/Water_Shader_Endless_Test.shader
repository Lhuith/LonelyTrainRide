// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'


Shader "Test/Water_Shader_Endless_Test"
{
	Properties
	{
		//Basic Ocean Information
		_OceanColor("Ocean Color", Color) = (1,1,1,1)

		//---------------------------------------------------------------------------------
		//Depth Controls
		_FadeLimit("Fade Limit", float) = 1.0
		_InvFade("Inverted Fade", float) = 1.0
		_SubColor("Ocean SubSurface Color", Color) = (1,1,1,1)
		[PowerSlider(3.0)] _DepthFactor("Water DepthFactor", Range(-100,100)) = 0
		_sigma_t("Depth Value", Range(-100, 100)) = .05
		_ScatterTex ("Scatter Texture", 2D) = "white" {}
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
		_AniX("Anisotropic X", Range(0.0, 2.0)) = 1.0
		_AniY("Anisotropic Y", Range(0.0, 2.0)) = 1.0
		_Shininess("Shininess", float) = 1.0
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
		Tags { "Queue"="Transparent"" RenderType" = "Transparent" "LightMode" = "ForwardBase"}
		Cull Off 
		Blend SrcAlpha OneMinusSrcAlpha
		
		
		Pass
		{
			CGPROGRAM
			#pragma glsl
			#pragma vertex vert
			#pragma fragment frag
			#include "AutoLight.cginc"
			#include "UnityCG.cginc"
			#pragma shader_feature _IBLMODE_OFF _IBLMODE_REFL _IBLMODE_REFR
			uniform fixed4 _OceanColor;
			uniform fixed4 _SubColor;

			//------------
			// Lighting Controls
			uniform fixed _DepthFactor;
			uniform samplerCUBE _Cube;
			uniform fixed _Quality;
			fixed _ReflectionFactor;
			half _Detail;
			fixed _ReflectionExposure;
			uniform float _Growth;
			uniform fixed4 _Color;
			uniform fixed4 _SpecColor;
			uniform fixed _AniX;
			uniform fixed _AniY;
			uniform half _Shininess;


			uniform half4 _LightColor0;

			fixed _GlitterStrength;
			//------------
			// Lighting Controls

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
			fixed4x4 _LightProjectionMatrix;
			fixed4x4 _Object2Light;
			float4x4 unity_WorldToLight;
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
				fixed eyeDepth : TEXCOORD2;
				fixed3 normalDir : TEXCOORD3;
				fixed4 lightDir : TEXCOORD4;
				fixed3 viewDir : TEXCOORD5;
				fixed3 tangentDir : TEXCOORD7;
				fixed4 projPos : TEXCOORD8;
				fixed3 rayDir : TEXCOORD9;
				fixed4 fragPos : TEXCOORD10;
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

			fixed3 mod289(fixed3 x) {
				return x - floor(x * (1.0 / 289.0)) * 289.0;
			}

			fixed4 mod289(fixed4 x) {
				return x - floor(x * (1.0 / 289.0)) * 289.0;
			}

			fixed4 permute(fixed4 x) {
				return mod289(((x*34.0) + 1.0)*x);
			}

			fixed4 taylorInvSqrt(fixed4 r)
			{
				return 1.79284291400159 - 0.85373472095314 * r;
			}

			fixed snoise(fixed3 v)
			{
				const fixed2  C = fixed2(1.0 / 6.0, 1.0 / 3.0);
				const fixed4  D = fixed4(0.0, 0.5, 1.0, 2.0);

				// First corner
				fixed3 i = floor(v + dot(v, C.yyy));
				fixed3 x0 = v - i + dot(i, C.xxx);

				// Other corners
				fixed3 g = step(x0.yzx, x0.xyz);
				fixed3 l = 1.0 - g;
				fixed3 i1 = min(g.xyz, l.zxy);
				fixed3 i2 = max(g.xyz, l.zxy);

				//   x0 = x0 - 0.0 + 0.0 * C.xxx;
				//   x1 = x0 - i1  + 1.0 * C.xxx;
				//   x2 = x0 - i2  + 2.0 * C.xxx;
				//   x3 = x0 - 1.0 + 3.0 * C.xxx;
				fixed3 x1 = x0 - i1 + C.xxx;
				fixed3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
				fixed3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y

										   // Permutations
				i = mod289(i);
				fixed4 p = permute(permute(permute(
					i.z + fixed4(0.0, i1.z, i2.z, 1.0))
					+ i.y + fixed4(0.0, i1.y, i2.y, 1.0))
					+ i.x + fixed4(0.0, i1.x, i2.x, 1.0));

				// Gradients: 7x7 points over a square, mapped onto an octahedron.
				// The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
				fixed n_ = 0.142857142857; // 1.0/7.0
				fixed3  ns = n_ * D.wyz - D.xzx;

				fixed4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  fmod(p,7*7)

				fixed4 x_ = floor(j * ns.z);
				fixed4 y_ = floor(j - 7.0 * x_);    // fmod(j,N)

				fixed4 x = x_ *ns.x + ns.yyyy;
				fixed4 y = y_ *ns.x + ns.yyyy;
				fixed4 h = 1.0 - abs(x) - abs(y);

				fixed4 b0 = fixed4(x.xy, y.xy);
				fixed4 b1 = fixed4(x.zw, y.zw);

				//fixed4 s0 = fixed4(lessThan(b0,0.0))*2.0 - 1.0;
				//fixed4 s1 = fixed4(lessThan(b1,0.0))*2.0 - 1.0;
				fixed4 s0 = floor(b0)*2.0 + 1.0;
				fixed4 s1 = floor(b1)*2.0 + 1.0;
				fixed4 sh = -step(h, fixed4(0.0, 0.0, 0.0, 0.0));

				fixed4 a0 = b0.xzyw + s0.xzyw*sh.xxyy;
				fixed4 a1 = b1.xzyw + s1.xzyw*sh.zzww;

				fixed3 p0 = fixed3(a0.xy, h.x);
				fixed3 p1 = fixed3(a0.zw, h.y);
				fixed3 p2 = fixed3(a1.xy, h.z);
				fixed3 p3 = fixed3(a1.zw, h.w);

				//Normalise gradients
				fixed4 norm = taylorInvSqrt(fixed4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
				p0 *= norm.x;
				p1 *= norm.y;
				p2 *= norm.z;
				p3 *= norm.w;

				// lerp final noise value
				fixed4 m = max(0.6 - fixed4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
				m = m * m;
				return 42.0 * dot(m*m, fixed4(dot(p0, x0), dot(p1, x1),
					dot(p2, x2), dot(p3, x3)));
			}

			fixed3 hsv(fixed h, fixed s, fixed v)
			{
				return lerp(fixed3(1.0, 1.0, 1.0), clamp((abs(frac(
					h + fixed3(3.0, 2.0, 1.0) / 3.0) * 6.0 - 3.0) - 1.0), 0.0, 1.0), s) * v;
			}

							
			   fixed trace(fixed3 P, uniform fixed4x4  lightTexMatrix,  uniform fixed4x4  lightMatrix, 
			            uniform sampler2D DepthTex
			            )
			{

			   fixed4 texCoord = mul(lightTexMatrix, float4(P, 1.0));
			
			  // get distance from light at entry point
			  
			 fixed d_i = Linear01Depth( tex2Dproj( DepthTex, UNITY_PROJ_COORD( texCoord ) ).r );

			  // transform position to light space
			  
			   fixed4 Plight = mul(lightMatrix, float4(P, 1.0));
			
			  // distance of this pixel from light (exit)
			  
			   fixed d_o = length(Plight);
			
			  // calculate depth 
			  
			   fixed s = d_o - d_i;
			  return s;
			}


			v2f vert (appdata_full v)
			{
				v2f o;
				
			
				o.wPos =  mul(unity_ObjectToWorld, v.vertex);
				fixed4 vertNew = GestnerWave(o.wPos, _Time.y);
				//v.normal /= normalize((v.vertex - vertNew));
				v.vertex += vertNew;
				o.fragPos = v.vertex;
				o.tangentDir = normalize(mul(unity_WorldToObject, half4(v.tangent.xyz, 0.0)));
				//dyno = tex2Dlod(_DynamicTex, fixed4(v.texcoord.xy, 0.0,0.0));
				o.normalDir = normalize(mul(unity_WorldToObject, half4(v.normal, 0.0)));
				o.viewDir = normalize(_WorldSpaceCameraPos.xyz - o.wPos.xyz);
				o.pos = UnityObjectToClipPos(v.vertex);
				o.projPos = ComputeScreenPos (o.pos);
				
				COMPUTE_EYEDEPTH(o.projPos.z);
				o.uv = v.texcoord;

						half3 fragmentToLightSource = _WorldSpaceLightPos0.xyz - o.wPos.xyz;
				o.lightDir = fixed4(
				normalize(lerp(_WorldSpaceLightPos0.xyz, fragmentToLightSource, _WorldSpaceLightPos0.w)),
				lerp(1.0, 1.0 / length(fragmentToLightSource), _WorldSpaceLightPos0.w));
			
				//o.pos.xyz += v.normal * _Growth;

				half3 eyeRay = normalize(mul(unity_WorldToObject, v.vertex.xyz));
				o.rayDir = half3(-eyeRay);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				half3 fragmentToLightSource =  normalize(_WorldSpaceLightPos0.xyz);
				fixed3 worldRefl = reflect(-i.viewDir, i.normalDir.xyz);

				fixed worldReflAngle = dot(normalize(-i.viewDir), i.normalDir.xyz);
				fixed worldReflightAngle = dot(normalize(_WorldSpaceLightPos0), i.normalDir.xyz);
				
		
				fixed rawZ =  SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture,UNITY_PROJ_COORD(i.projPos));
				fixed sceneZEye = LinearEyeDepth(rawZ);
				fixed partZ = i.projPos.z;

				fixed fade = 1.0;

				if(rawZ > 0.0)
				fade = saturate(_InvFade * ((sceneZEye) - partZ));

				fixed4 fadecol = fixed4(0,0,0, 0);

				if(fade < _FadeLimit)
				{
					 fadecol += (1 - fade);
				}

				fixed4 finalColor = fixed4(0,0,0, 1.0);

				fixed3 h = normalize(i.lightDir.xyz + i.viewDir);
				fixed3 binormal = cross(i.normalDir, i.tangentDir);
				
				//dotProdoct
				fixed nDotl = dot(i.normalDir, i.lightDir.xyz);
				fixed nDotH = dot(i.normalDir, h);
				fixed nDotV = dot(i.normalDir, i.viewDir);
				fixed tDotHX = dot(i.tangentDir, h) / _AniX;
				fixed bDotHY = dot(binormal, h) / _AniY;	


				fixed3 diffuseReflection = i.lightDir.w * _LightColor0.xyz * saturate(nDotl);
				fixed3 specularReflection =  diffuseReflection * exp(-(tDotHX * tDotHX + bDotHY * bDotHY)) * _Shininess * _SpecColor;
				fixed3 specularReflection2 = i.lightDir * saturate(nDotl);

				//unity_WorldToLight
				//_Object2Light
				fixed si = trace(i.pos, _LightProjectionMatrix, unity_WorldToLight, _CameraDepthTexture);

				fixed4 SSS = float4(0,0,0,1.0);
				float ex = 0;
				 ex =  exp(-si * _sigma_t) * _SubColor  * (fade);
				SSS = float4(ex,ex,ex,ex);

				fixed4 lightFinal = fixed4(specularReflection + diffuseReflection +
								UNITY_LIGHTMODEL_AMBIENT.xyz, 1.0);
				
				finalColor.rgb += _OceanColor * lightFinal;
				fixed3 reflection = IBLRefl(_Cube, _Detail, worldRefl, _ReflectionExposure, _ReflectionFactor);
				finalColor.rgb *= reflection;
				//finalColor += SSS;
				//Sparkle:
				fixed2 uv =  h.xy * 1028;
				fixed4 glitColor = fixed4(0,0,0,1.0);

				fixed fadeLR = .5 - abs(uv.x - .5);
				fixed fadeTB = 1. - uv.y;
				fixed3 pos = fixed3(uv * fixed2(3., 1.) - fixed2(0., _Time.y * nDotV), _Time.y  * nDotH);
				fixed n =  (fadeLR * fadeTB * smoothstep(.6, 1., snoise(pos)) * nDotl);
				fixed col = hsv(n * .1 + .7, .4, 1.);

				glitColor = ((fixed4(col * fixed3(n, n, n), n)) * _GlitterStrength) * fixed4(specularReflection * diffuseReflection,1.0);
				glitColor.rgb = lerp(glitColor.rgb, specularReflection * glitColor, nDotl) * _LightColor0;
				glitColor.rgb *= reflection;

				return fixed4(finalColor);  
			}
			ENDCG
		}

	}
	   FallBack "Diffuse"
}
 