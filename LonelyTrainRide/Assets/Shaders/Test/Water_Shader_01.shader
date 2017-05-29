Shader "Eugene/Tests/Water_V1"
{
	Properties
	{
		_MainTex ("Color (RGB) Alpha (A)", 2D) = "white" {}
		_DynamicTex("Texture", 2D) = "white" {}
		_SineAmplitude ("Amplitude", Float) = 1.0
		//the following three are vectors so we can control more than one wave easily
		_SineFrequency ("Frequency", Vector) = (1,1,0,0)
		_Speed ("Speed", Vector) = (1,1,0,0)
		_Steepness ("steepness", Vector) = (1,1,0,0)
		//two direction vectors as we are using two gerstner waves
		_Dir ("Wave Direction", Vector) = (1,1,0,0)
		_Dir2 ("2nd Wave Direction", Vector) = (1,1,0,0)
		_DepthFactor("Water Edge Power", Range(0,300)) = 0
		_Smoothing("Normal Smoothing", float) = 10

		_EdgeColor("Color Of Edge", Color) = (1,1,1,1)
		_DeepColor("Color Of Deep", Color) = (1,1,1,1)
		_OceanColor("Color Of Ocean", Color) = (1,1,1,1)

		_SpecColor("Specular Color", Color) = (1.0,1.0,1.0,1.0)
		_AniX("Anisotropic X", Range(0.0, 2.0)) = 1.0
		_AniY("Anisotropic Y", Range(0.0, 2.0)) = 1.0
		_Shininess("Shininess", Float) = 1.0

	}
	SubShader
	{
		Tags { "Queue"="Transparent" "RenderType"="Transparent" }
		Cull Off
		Blend SrcAlpha OneMinusSrcAlpha
		Fog { Mode Off }
		//Reciever
		Stencil 
		{
			    Ref 1
                Comp equal
                Pass keep 
                ZFail decrWrap
		}
		
		Pass
		{
			CGPROGRAM
			#pragma glsl
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			uniform fixed4 _Color;
			uniform fixed4 _SpecColor;
			uniform fixed _AniX;
			uniform fixed _AniY;
			uniform half _Shininess;
			uniform float _Quality;

			float _SineAmplitude;
			float4 _SineFrequency;
			float4 _Speed;
			float4 _Steepness;
			float4 _Dir;
			float4 _Dir2;
			uniform float _DepthFactor;
			float _Smoothing;

			uniform sampler2D _CameraDepthTexture;
			uniform float4 _EdgeColor;
			uniform float4 _DeepColor;
			uniform float4 _OceanColor;

			uniform half4 _LightColor0;
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
			
			sampler2D _DynamicTex;
			float4 _DynamicTex_ST;

			fixed4 dyno;

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

			float4 blend(float4 A, float4 B)
			{
			   float4 C;
			   C.a = A.a + (1 - A.a) * B.a;
			   C.rgb = (1 / C.a) * (A.a * A.rgb + (1 - A.a) * B.a * B.rgb);
			   return C;
			}

			v2f vert (appdata_full v)
			{
				v2f o;
				
		
				o.normalDir = normalize(mul(half4(v.normal, 0.0), unity_WorldToObject).xyz);
				o.tangentDir = normalize(mul(unity_WorldToObject, half4(v.tangent.xyz, 0.0)).xyz);
				o.pos = UnityObjectToClipPos(v.vertex);
				//dyno = tex2Dlod(_DynamicTex, float4(v.texcoord.xy, 0.0,0.0));
				o.wPos =  mul(unity_ObjectToWorld, v.vertex);

				o.viewDir = normalize(_WorldSpaceCameraPos.xyz - o.wPos.xyz);

				half3 fragmentToLightSource = _WorldSpaceLightPos0.xyz - o.wPos.xyz;

				o.lightDir = fixed4(
				normalize(lerp(_WorldSpaceLightPos0.xyz, fragmentToLightSource, _WorldSpaceLightPos0.w)),
				lerp(1.0, 1.0 / length(fragmentToLightSource), _WorldSpaceLightPos0.w));

				v.vertex += GestnerWave(o.wPos, _Time.x);
				v.vertex += GestnerWave(o.wPos, _Time.y);

				o.uv = v.texcoord;
				o.projPos = ComputeScreenPos (o.pos);

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{

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
								UNITY_LIGHTMODEL_AMBIENT.xyz, 1.0);
				
				fixed4 heightMap = tex2D(_MainTex, i.uv);	
				float sceneZ =  Linear01Depth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture,																		UNITY_PROJ_COORD(i.projPos)));
				// Calculates Genuine Distance To Camera
                float partZ = i.projPos.z;
				float fade = saturate (_DepthFactor * (sceneZ - partZ));
				_EdgeColor *= abs(1 - fade);
		
				return fixed4(((_OceanColor * _EdgeColor)));
			}
			ENDCG
		}

	}
}
