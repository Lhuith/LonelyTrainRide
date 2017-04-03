// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Test/Water_Shader_Endless_Test"
{
	Properties
	{
		_MainTex ("Color (RGB) Alpha (A)", 2D) = "white" {}
		_DynamicTex("Texture", 2D) = "white" {}
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
		_Smoothing("Normal Smoothing", float) = 10

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

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
				float4 wPos : TEXCOORD1;
				float4 projPos : TEXCOORD2;
				fixed3 normalDir : TECOORD3;
				fixed4 lightDir : TEXCOORD4;
				fixed3 viewDir : TEXCOORD5;
				float3 tangentDir : TEXCOORD7;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _AlphaMap;
			float4 _AlphaMap_ST;

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

			v2f vert (appdata_full v)
			{
				v2f o;
				
			
				o.wPos =  mul(unity_ObjectToWorld, v.vertex);
				v.vertex += GestnerWave(o.wPos, _Time.y);
				//v.normal = normalize(o.wPos);
				o.tangentDir = normalize(mul(unity_WorldToObject, half4(v.tangent.xyz, 0.0)).xyz);
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				//dyno = tex2Dlod(_DynamicTex, float4(v.texcoord.xy, 0.0,0.0));
				o.normalDir = normalize(mul(half4(v.normal, 0.0), unity_WorldToObject).xyz);

				o.viewDir = normalize(_WorldSpaceCameraPos.xyz - o.wPos.xyz);
				o.projPos = ComputeScreenPos (o.pos);
				COMPUTE_EYEDEPTH(o.projPos.z);
				o.uv = v.texcoord;

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{

				half3 fragmentToLightSource = _WorldSpaceLightPos0.xyz - i.wPos.xyz;

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
				fixed3 specularReflection = diffuseReflection * exp(-(tDotHX * tDotHX + bDotHY * bDotHY)) * _Shininess;
							
				fixed4 lightFinal = fixed4(specularReflection + diffuseReflection +
								UNITY_LIGHTMODEL_AMBIENT.xyz, _Alpha) / _Alpha;
				
				finalColor.rgb += _OceanColor * lightFinal;

				float3 worldRefl = reflect(-i.viewDir, i.normalDir.xyz);
				finalColor.rgb *= IBLRefl(_Cube, _Detail, worldRefl, _ReflectionExposure, _ReflectionFactor);

				return finalColor;
			}
			ENDCG
		}

	}
}
