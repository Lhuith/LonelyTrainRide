// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Test/Water_Shader_Endless_Test"
{
	Properties
	{
		_MainTex ("Color (RGB) Alpha (A)", 2D) = "white" {}
		_GlitterTex("Glitter Texture", 2D) = "white" {}
		_NoiseTex("Noise Texture", 2D) = "white" {}
		_FallOff("FallOff Texture", 2D) = "white" {}
		_Alpha("Alpha Mappig", Float) = 1.0

		_OceanColor("Color Of Ocean", Color) = (1,1,1,1)

		_SpecColor("Specular Color", Color) = (1.0,1.0,1.0,1.0)
		_AniX("Anisotropic X", Range(0.0, 2.0)) = 1.0
		_AniY("Anisotropic Y", Range(0.0, 2.0)) = 1.0
		_Shininess("Shininess", Float) = 1.0
		_HighlightThresholdMax("Region Around Depth Collision", Float) = 0
		_DepthFactor("Water DepthFactor", Range(0.01,001)) = 0
		[KeywordEnum(Off, Refl, Refr)] _IBLMode ("IBL Mode", Float) = 0
		_ReflectionFactor("Specular %", Range(0,1)) = 1

		_Cube("Cube Map", Cube) = "" {}
		_Detail("Reflection Detail", Range(1, 9)) = 1.0
		_ReflectionExposure("HDR Exposure", Float) = 1.0
		_Quality("Quility Of Intersection", Float) = 1.0

		_SineAmplitude ("Amplitude", Float) = 1.0
		//the following three are vectors so we can control more than one wave easily
		_SineFrequency ("Frequency", Vector) = (1,1,0,0)
		_Speed ("Speed", Vector) = (1,1,0,0)
		_Steepness ("steepness", Vector) = (1,1,0,0)
		//two direction vectors as we are using two gerstner waves
		_Dir ("Wave Direction", Vector) = (1,1,0,0)
		_Dir2 ("2nd Wave Direction", Vector) = (1,1,0,0)
		_GlitterStrength("Glitter Strength", Range(0 , .1)) = .5

	}
	SubShader
	{
		Tags { "Queue"="Transparent" "RenderType"="Transparent" "LightMode" = "ForwardBase"}
		Cull Off 
		Blend SrcAlpha OneMinusSrcAlpha
		
		Fog { Mode Off }
		Pass
		{
			CGPROGRAM
			#pragma glsl
			#pragma vertex vert
			#pragma fragment frag
			#pragma shader_feature _IBLMODE_OFF _IBLMODE_REFL _IBLMODE_REFR
			#include "UnityCG.cginc"

			uniform float _HighlightThresholdMax;
			uniform fixed4 _Color;
			uniform fixed4 _SpecColor;
			uniform fixed _AniX;
			uniform fixed _AniY;
			uniform half _Shininess;
			uniform float _Quality;

			uniform sampler2D_float _CameraDepthTexture;
			uniform float4 _EdgeColor;
			uniform float4 _DeepColor;
			uniform float4 _OceanColor;

			uniform half4 _LightColor0;

			uniform float _DepthFactor;
			uniform float _Alpha;
			uniform samplerCUBE _Cube;

			float _ReflectionFactor;
			half _Detail;
			float _ReflectionExposure;

			float _SineAmplitude;
			float4 _SineFrequency;
			float4 _Speed;
			float4 _Steepness;
			float4 _Dir;
			float4 _Dir2;

			float _GlitterStrength;
			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
				float4 wPos : TEXCOORD1;
				float4 projPos : TEXCOORD2;
				fixed3 normalDir : TEXCOORD3;
				fixed4 lightDir : TEXCOORD4;
				fixed3 viewDir : TEXCOORD5;
				float3 tangentDir : TEXCOORD7;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _AlphaMap;
			float4 _AlphaMap_ST;
			sampler2D _NoiseTex;
			float4 _NoiseTex_ST;
			float4 _FallOff_ST;
			sampler2D _FallOff;
			sampler2D _GlitterTex;

			float4 blend(float4 A, float4 B) 
			{
			   float4 C;
			   C.a = A.a + (1 - A.a) * B.a;
			   C.rgb = (1 / C.a) * (A.a * A.rgb + (1 - A.a) * B.a * B.rgb);
			   return C;
			}

					
			float3 IBLRefl(samplerCUBE cubeMap, half detial, float3 worldRefl, float exposure, float reflectionFactor)
			{
				float4 cubeMapCol = texCUBElod(cubeMap, float4(worldRefl, detial)).rgba;
				return reflectionFactor * cubeMapCol.rgb * (cubeMapCol.a * exposure);
			}

			float4 GestnerWave(float4 Wpos, float4 time)
			{
				float2 dir = _Dir.xy;
				dir = normalize(dir) ; 
				float dotprod = dot(dir, Wpos.xz);
				float disp = (time.x * _Speed.x);
				
				//do the same for our second wave
				float2 dir2 = _Dir2.xy;
				dir2 = normalize(dir2);
				float dotprod2 = dot(dir2, Wpos.xz);
				float disp2 = (time.x * _Speed.y);										
				
				float4 vertex = float4(0,0,0,0);
								
				vertex.x = (_Steepness.x *_SineAmplitude) *_Dir.x * cos(_SineFrequency.x * (dotprod + disp));
				vertex.z = (_Steepness.x *_SineAmplitude) *_Dir.y * cos(_SineFrequency.x * (dotprod + disp));
				vertex.y = _SineAmplitude * - sin(_SineFrequency.x * (dotprod + disp));

				vertex.x = (_Steepness.y *_SineAmplitude) * _Dir2.x * cos(_SineFrequency.y * (dotprod2 + disp2));
				vertex.z = (_Steepness.y *_SineAmplitude) *_Dir2.y *  cos (_SineFrequency.y * (dotprod2 + disp2));
				vertex.y = _SineAmplitude * sin(_SineFrequency.y * (dotprod2 + disp2));

				return vertex;
			}

			float3 mod289(float3 x) {
				return x - floor(x * (1.0 / 289.0)) * 289.0;
			}

			float4 mod289(float4 x) {
				return x - floor(x * (1.0 / 289.0)) * 289.0;
			}

			float4 permute(float4 x) {
				return mod289(((x*34.0) + 1.0)*x);
			}

			float4 taylorInvSqrt(float4 r)
			{
				return 1.79284291400159 - 0.85373472095314 * r;
			}

			float snoise(float3 v)
			{
				const float2  C = float2(1.0 / 6.0, 1.0 / 3.0);
				const float4  D = float4(0.0, 0.5, 1.0, 2.0);

				// First corner
				float3 i = floor(v + dot(v, C.yyy));
				float3 x0 = v - i + dot(i, C.xxx);

				// Other corners
				float3 g = step(x0.yzx, x0.xyz);
				float3 l = 1.0 - g;
				float3 i1 = min(g.xyz, l.zxy);
				float3 i2 = max(g.xyz, l.zxy);

				//   x0 = x0 - 0.0 + 0.0 * C.xxx;
				//   x1 = x0 - i1  + 1.0 * C.xxx;
				//   x2 = x0 - i2  + 2.0 * C.xxx;
				//   x3 = x0 - 1.0 + 3.0 * C.xxx;
				float3 x1 = x0 - i1 + C.xxx;
				float3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
				float3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y

										   // Permutations
				i = mod289(i);
				float4 p = permute(permute(permute(
					i.z + float4(0.0, i1.z, i2.z, 1.0))
					+ i.y + float4(0.0, i1.y, i2.y, 1.0))
					+ i.x + float4(0.0, i1.x, i2.x, 1.0));

				// Gradients: 7x7 points over a square, mapped onto an octahedron.
				// The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
				float n_ = 0.142857142857; // 1.0/7.0
				float3  ns = n_ * D.wyz - D.xzx;

				float4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  mod(p,7*7)

				float4 x_ = floor(j * ns.z);
				float4 y_ = floor(j - 7.0 * x_);    // mod(j,N)

				float4 x = x_ *ns.x + ns.yyyy;
				float4 y = y_ *ns.x + ns.yyyy;
				float4 h = 1.0 - abs(x) - abs(y);

				float4 b0 = float4(x.xy, y.xy);
				float4 b1 = float4(x.zw, y.zw);

				//float4 s0 = float4(lessThan(b0,0.0))*2.0 - 1.0;
				//float4 s1 = float4(lessThan(b1,0.0))*2.0 - 1.0;
				float4 s0 = floor(b0)*2.0 + 1.0;
				float4 s1 = floor(b1)*2.0 + 1.0;
				float4 sh = -step(h, float4(0.0, 0.0, 0.0, 0.0));

				float4 a0 = b0.xzyw + s0.xzyw*sh.xxyy;
				float4 a1 = b1.xzyw + s1.xzyw*sh.zzww;

				float3 p0 = float3(a0.xy, h.x);
				float3 p1 = float3(a0.zw, h.y);
				float3 p2 = float3(a1.xy, h.z);
				float3 p3 = float3(a1.zw, h.w);

				//Normalise gradients
				float4 norm = taylorInvSqrt(float4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
				p0 *= norm.x;
				p1 *= norm.y;
				p2 *= norm.z;
				p3 *= norm.w;

				// lerp final noise value
				float4 m = max(0.6 - float4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
				m = m * m;
				return 42.0 * dot(m*m, float4(dot(p0, x0), dot(p1, x1),
					dot(p2, x2), dot(p3, x3)));
			}

			float3 hsv(float h, float s, float v)
			{
				return lerp(float3(1.0, 1.0, 1.0), clamp((abs(frac(
					h + float3(3.0, 2.0, 1.0) / 3.0) * 6.0 - 3.0) - 1.0), 0.0, 1.0), s) * v;
			}
			// Blurs using a 3x3 filter kernel
		float4 BlurFunction3x3(sampler2D texsampler, float2 uv) : COLOR0
			{
			  // TOP ROW
			  float4 s11 = tex2D(texsampler, uv + float2(-1.0f / 1024.0f, -1.0f / 768.0f));    // LEFT
			  float4 s12 = tex2D(texsampler, uv + float2(0, -1.0f / 768.0f));              // MIDDLE
			  float4 s13 = tex2D(texsampler, uv + float2(1.0f / 1024.0f, -1.0f / 768.0f)); // RIGHT
			 								
			  // MIDDLE ROW					
			  float4 s21 = tex2D(texsampler, uv + float2(-1.0f / 1024.0f, 0));             // LEFT
			  float4 col = tex2D(texsampler, uv);                                          // DEAD CENTER
			  float4 s23 = tex2D(texsampler, uv + float2(-1.0f / 1024.0f, 0));                 // RIGHT
			 								
			  float4 s31 = tex2D(texsampler, uv + float2(-1.0f / 1024.0f, 1.0f / 768.0f)); // LEFT
			  float4 s32 = tex2D(texsampler, uv + float2(0, 1.0f / 768.0f));                   // MIDDLE
			  float4 s33 = tex2D(texsampler, uv + float2(1.0f / 1024.0f, 1.0f / 768.0f));  // RIGHT
			 
			  // Average the color with surrounding samples
			  col = (col + s11 + s12 + s13 + s21 + s23 + s31 + s32 + s33) / 9;
			  return col;
			}
			 
			v2f vert (appdata_full v)
			{
				v2f o;
				
			
				o.wPos =  mul(unity_ObjectToWorld, v.vertex);
				float4 vertNew = GestnerWave(o.wPos, _Time.y);
				//v.normal /= normalize((v.vertex - vertNew));
				v.vertex += vertNew;

				o.tangentDir = normalize(mul(unity_WorldToObject, half4(v.tangent.xyz, 0.0)).xyz);
				//dyno = tex2Dlod(_DynamicTex, float4(v.texcoord.xy, 0.0,0.0));
				o.normalDir = normalize(mul(half4(v.normal, 0.0), unity_WorldToObject).xyz);
				o.viewDir = normalize(_WorldSpaceCameraPos.xyz - o.wPos.xyz);
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				o.projPos = ComputeScreenPos (o.pos);
				COMPUTE_EYEDEPTH(o.projPos.z);
				o.uv = v.texcoord;

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{

				half3 fragmentToLightSource = _WorldSpaceLightPos0.xyz - i.wPos.xyz;
				float3 worldRefl = reflect(-i.viewDir, i.normalDir.xyz);
				i.lightDir = fixed4(
				normalize(lerp(_WorldSpaceLightPos0.xyz, fragmentToLightSource, _WorldSpaceLightPos0.w)),
				lerp(1.0, 1.0 / length(fragmentToLightSource), _WorldSpaceLightPos0.w));
			
				fixed4 OceanMap = tex2D(_MainTex, i.uv);	
				float sceneZEye = LinearEyeDepth   (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture,UNITY_PROJ_COORD(i.projPos)));
				float partZ = i.projPos.z;
				float fade = saturate (_DepthFactor * ((sceneZEye) - partZ));
				_Alpha *= fade;
				float4 finalColor = float4(0,0,0, _Alpha);
				//finalColor *= fade;

				fixed3 h = normalize(i.lightDir.xyz + i.viewDir);
				fixed3 binormal = cross(i.normalDir, i.tangentDir);
				
				//dotProdoct
				fixed nDotl = dot(i.normalDir, i.lightDir.xyz);
				fixed nDotH = dot(i.normalDir, h);
				fixed nDotV = dot(i.normalDir, i.viewDir);
				fixed tDotHX = dot(i.tangentDir, h) / _AniX;
				fixed bDotHY = dot(binormal, h) / _AniY;	


				fixed3 diffuseReflection = i.lightDir.w * _LightColor0.xyz * saturate(nDotl);
				fixed3 specularReflection =  diffuseReflection * exp(-(tDotHX * tDotHX + bDotHY * bDotHY)) * _Shininess;


				fixed4 lightFinal = fixed4(specularReflection + diffuseReflection  + 
								UNITY_LIGHTMODEL_AMBIENT.xyz, _Alpha) / _Alpha;
				
				finalColor.rgb += _OceanColor * lightFinal;
				float3 reflection = IBLRefl(_Cube, _Detail, worldRefl, _ReflectionExposure, _ReflectionFactor);
				finalColor.rgb *= reflection;

				//Sparkle:
				float2 uv = i.uv.xy ;
				float fadeLR = .5 - abs(uv.x - .5);
				float fadeTB = 1. - uv.y;
				float3 pos = float3(uv * float2(3., 1.) - float2(0., _Time.x * .001), _Time.y  * .001);
				float n =  fadeLR * fadeTB * specularReflection * smoothstep(.6, 1., snoise(pos * 1028)) * 10.;
				float col = hsv(n * .2 + .7, .4, 1.);
				float4 glitColor = (float4(col * float3(n, n, n), n)) * _GlitterStrength;

				float4 GlitterMap = glitColor * _LightColor0;


				return finalColor + float4(GlitterMap);
			}
			ENDCG
		}

	}
}
