Shader "Unlit/Gem_Sparkle"
{
	Properties
	{
		_MainTex ("tex2D", 2D) = "white" {}
		_SparkleTex("SparklerTexture", 2D) = "white" {}
		_TrainAlphaTex("TrainAlphaTexture", 2D) = "white" {}
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D _SparkleTex;
			float4 _SparkleTex_ST;

			sampler2D _TrainAlphaTex;
			float4 _TrainAlphaTex_ST;


			float2 saturate(float2 p) { return clamp(p,0.,1.); }

			float2 rot(float2 p, float a) {
				    a=radians(a);
				    return cos(a)*p + sin(a)*float2(p.y, -p.x);
				}

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
					 float4 screen = tex2D(_MainTex, i.uv);
					 float4 TrainAlpha = tex2D(_TrainAlphaTex, i.uv); //BEtter To do Depth Testing for this

					 float dist = 1.0 - (distance(i.vertex, _WorldSpaceCameraPos));

				    const float n = 12;
				    const float a1 = -1.;
				    const float a2 = -5.;
				    float2 uv = i.uv;
				    float3 color = float3(0,0,0);
				    float2 colorShift = float2(.001,.002);
				    float2 uv1 = uv+colorShift;
				    float2 uv2 = uv;
				    float2 uv3 = uv-colorShift;
				    float2 axis1 = rot(float2(0,1.105/_ScreenParams.y),-15.);
				    float2 axis2 = rot(float2(0,0.953/_ScreenParams.y),+65.);

				    for(float delta = 0.; delta< n;delta++)
					{
				        float scale = .0625*.0625*(1.-.9875*delta/n);
				        float2 d1r = delta*rot(axis1,-a1);
				        float2 d1g = delta*axis1;
				        float2 d1b = delta*rot(axis1,+a1);
				        float4 texR1 = tex2D(_SparkleTex, saturate(uv1+d1r));
				        float4 texR2 = tex2D(_SparkleTex, saturate(uv1-d1r));
				        float4 texG1 = tex2D(_SparkleTex, saturate(uv2+d1g));
				        float4 texG2 = tex2D(_SparkleTex, saturate(uv2-d1g));
				        float4 texB1 = tex2D(_SparkleTex, saturate(uv3+d1b));
				        float4 texB2 = tex2D(_SparkleTex, saturate(uv3-d1b));
				        float3 aberr1 = float3(dot(float4(10,4,2,0),texR1+texR2),
				                           dot(float4(3,10,3,0),texG1+texG2),
				                           dot(float4(2,4,10,0),texB1+texB2));
				        float3 col1 = aberr1*max(aberr1.r,max(aberr1.g,aberr1.b));
				        float2 d2r = delta*rot(axis2,+a2);
				        float2 d2g = delta*axis2;
				        float2 d2b = delta*rot(axis2,-a2);
				        float4 texR3 = tex2D(_SparkleTex, saturate(uv1+d2r));
				        float4 texR4 = tex2D(_SparkleTex, saturate(uv1-d2r));
				        float4 texG3 = tex2D(_SparkleTex, saturate(uv2+d2g));
				        float4 texG4 = tex2D(_SparkleTex, saturate(uv2-d2g));
				        float4 texB3 = tex2D(_SparkleTex, saturate(uv3+d2b));
				        float4 texB4 = tex2D(_SparkleTex, saturate(uv3-d2b));
				        float3 aberr2 = float3(dot(float4(10,4,2,0),texR3+texR4),
				                           dot(float4(3,10,3,0),texG3+texG4),
				                           dot(float4(2,4,10,0),texB3+texB4));
				        float3 col2 = aberr2*max(aberr2.r,max(aberr2.g,aberr2.b));
				        float3 col = pow(scale*max(col1,col2)*3.7,float3(5.2, 5.2, 5.2));
				        color+=col;
				    }
				    return (float4(lerp(tex2D(_SparkleTex,uv).rgb, color, 
					smoothstep(.01,.2,min(uv.x,uv.y)) * smoothstep(-.99,-.8,-max(uv.x,uv.y))),1) * (1.0 -TrainAlpha.a)) + screen;
				}
			ENDCG
		}
	}
}
