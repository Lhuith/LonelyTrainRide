Shader "Custom/Test/RayCastTester"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			v2f vert (appdata_base v)
			{
				v2f o;
				o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.uv = v.texcoord;
				return o;
			}
			
			float distFunc(float3 pos)
			{
				const float sphereRadius = 1;
				return length(pos) - sphereRadius;
			}

			fixed4 renderSurface(float3 pos)
			{
				const float2 eps = float2(0.0,0.01);

				float ambientIntensity = 0.1;
				float3 lightDir = float3(0, -0.5, 0.5);

				float3 normal = normalize(float3(
				distFunc(pos + eps.yxx) - distFunc(pos - eps.yxx), 
				distFunc(pos + eps.xyx) - distFunc(pos - eps.xyx), 
				distFunc(pos + eps.xxy) - distFunc(pos - eps.xxy)));
				
				float diffuse = ambientIntensity + max(dot(-lightDir, normal), 0);

				return fixed4(diffuse, diffuse, diffuse, 1); 
			}

			fixed4 frag (v2f i) : SV_Target
			{
				float2 uv = i.uv - 0.5;
				float3 camUp = float3(0, 1, 0);
				float3 camForward = float3(0,0,1);
				float3 camRight = float3(1,0,0);

				float3 pos = float3(0,0, -5);
				float3 ray = camUp * uv.y + camRight * uv.x + camForward;

				fixed4 color = 0;

				float4 tex = tex2D(_MainTex, i.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw);

				for (int i = 0; i < 30; i++)
				{
					
					float d = distFunc(pos);

					if(d < 0.01)
					{
						color = renderSurface(pos);
						break;
					}

					pos += ray * d;

					if(d > 40)
					{
					 break; 
					}

				}


				return color * tex;
			}
			ENDCG
		}
	}
}
