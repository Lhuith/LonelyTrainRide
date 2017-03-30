Shader "Test/Smoke"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Pixels("Number of Pixels", Float) = 1028
		_Dissipation("Rate of Disperstion", Range(0,1)) = 4
		_Minimum("Minimum Dissipation Size", Range(0,1)) = 0.003

		_SmokeCentre("Smoke Point", Vector) = (0,0,0,0)
		_SmokeRaduis("Smoke Size", Range(0,1)) = 0.0089
	}
	SubShader
	{
		ZTest Always Cull Off ZWrite Off
		Fog { Mode off }

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			uniform float _Pixels;
			uniform float _Dissipation;
			uniform float _Minimum;

			uniform float _SmokeRaduis;
			uniform float2 _SmokeCentre;

			struct v2f
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 wPos : TEXCOORD1;
			};

			v2f vert (appdata_full v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
				o.wPos =  mul(unity_ObjectToWorld, v.vertex).xyz;
				return o;
			}
			
			fixed4 frag (v2f i) : COLOR
			{

				fixed2 uv = round(i.uv * _Pixels) / _Pixels;

				//Neighboring cells
			    half s = 1 / _Pixels;

				float cl = tex2D(_MainTex, uv + fixed2(-s, 0)).a; // F[ x - 1, y ] : Centre Left
				float tc = tex2D(_MainTex, uv + fixed2(0, -s)).a; // F[ x, y - 1 ] : Top Left
				float cc = tex2D(_MainTex, uv + fixed2(0,  0)).a; // F[ x,  y    ] : Centre Centre
				float bc = tex2D(_MainTex, uv + fixed2(0, +s)).a; //F[ x, y + 1] : Bottom Centre
				float cr = tex2D(_MainTex, uv + fixed2(+s, 0)).a; // F[ x, y] : Centre Right

				// sample the texture
				fixed4 col = tex2D(_MainTex, i.uv);

				//Diffusion step (HAWT HAWT HAWT)
				float factor = _Dissipation * ( 0.25 * (cl + tc + bc + cr) - cc ) ;

				//Minimum Flow
				if(factor >= -_Minimum && factor < 0.0)
				factor = -_Minimum;

				cc += factor;

				if(distance(i.wPos, _SmokeCentre) < _SmokeRaduis)
				cc = 1;


				return float4(1,1,1, cc);
			}
			ENDCG
		}
	}
}
