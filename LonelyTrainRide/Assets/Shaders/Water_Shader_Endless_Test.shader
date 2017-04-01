// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Test/Water_Shader_Endless_Test"
{
	Properties
	{
		_MainTex ("Color (RGB) Alpha (A)", 2D) = "white" {}
		_DynamicTex("Texture", 2D) = "white" {}

		_OceanColor("Color Of Ocean", Color) = (1,1,1,1)

		_SpecColor("Specular Color", Color) = (1.0,1.0,1.0,1.0)
		_AniX("Anisotropic X", Range(0.0, 2.0)) = 1.0
		_AniY("Anisotropic Y", Range(0.0, 2.0)) = 1.0
		_Shininess("Shininess", Float) = 1.0

		_DepthFactor("Water Edge Power", Range(0,300)) = 0
	}
	SubShader
	{
		Tags { "Queue"="Transparent" "RenderType"="Transparent" "LightMode" = "ForwardBase" }
		Cull Off 
		Blend SrcAlpha OneMinusSrcAlpha
		Fog { Mode Off }
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

			uniform sampler2D _CameraDepthTexture;
			uniform float4 _EdgeColor;
			uniform float4 _DeepColor;
			uniform float4 _OceanColor;

			uniform half4 _LightColor0;

			uniform float _DepthFactor;

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
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				//dyno = tex2Dlod(_DynamicTex, float4(v.texcoord.xy, 0.0,0.0));
				o.wPos =  mul(unity_ObjectToWorld, v.vertex);

				o.viewDir = normalize(_WorldSpaceCameraPos.xyz - o.wPos.xyz);

				half3 fragmentToLightSource = _WorldSpaceLightPos0.xyz - o.wPos.xyz;

				o.lightDir = fixed4(
				normalize(lerp(_WorldSpaceLightPos0.xyz, fragmentToLightSource, _WorldSpaceLightPos0.w)),
				lerp(1.0, 1.0 / length(fragmentToLightSource), _WorldSpaceLightPos0.w));

				o.uv = v.texcoord;
				o.projPos = ComputeScreenPos (o.pos);

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
		
				return fixed4(heightMap + float4(specularReflection, 1.0));
			}
			ENDCG
		}

	}
}
