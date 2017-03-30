// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Test/Water_01"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_DynamicTex("Texture", 2D) = "white" {}
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
		Tags { "RenderType"="Opaque" }

		Pass
		{
			CGPROGRAM
			#pragma glsl
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"


			float _SineAmplitude;
			float4 _SineFrequency;
			float4 _Speed;
			float4 _Steepness;
			float4 _Dir;
			float4 _Dir2;
			
			float _Smoothing;
			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
				float4 wPos : TEXCOORD1;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			
			sampler2D _DynamicTex;
			float4 _DynamicTex_ST;

			fixed4 dyno;

			v2f vert (appdata_full v)
			{
				v2f o;
				
				o.wPos =  mul(unity_ObjectToWorld, v.vertex);
				//
				dyno = tex2Dlod(_DynamicTex, float4(v.texcoord.xy, 0.0,0.0));
				fixed4 main = tex2Dlod(_MainTex,float4(v.texcoord.xy, 0.0,0.0));

				if(distance(o.wPos, _WorldSpaceCameraPos) > 128)
				dyno.a = 0;
				
						v.vertex.y += 1 - dyno.a * 100;
						v.vertex.z -=  dyno.a * 10;
						v.vertex.z +=  dyno.a * 10;

						float2 dir = _Dir.xy;
						dir = normalize(dir) ; 
						float dotprod = dot(dir, o.wPos.xz);
						float disp = (_Time.x * _Speed.x);

						//do the same for our second wave
						float2 dir2 = _Dir2.xy;
						dir2 = normalize(dir2);
						float dotprod2 = dot(dir2, o.wPos.xz);
						float disp2 = (_Time.x * _Speed.y);										
						
												
						v.vertex.x += (_Steepness.x *_SineAmplitude) *_Dir.x * cos(_SineFrequency.x * (dotprod + disp));
						v.vertex.z += (_Steepness.x *_SineAmplitude) *_Dir.y * cos(_SineFrequency.x * (dotprod + disp));
						v.vertex.y += _SineAmplitude * - sin(_SineFrequency.x * (dotprod + disp));
	
						v.vertex.x += (_Steepness.y *_SineAmplitude) * _Dir2.x * cos(_SineFrequency.y * (dotprod2 + disp2));
						v.vertex.z += (_Steepness.y *_SineAmplitude) *_Dir2.y *  cos (_SineFrequency.y * (dotprod2 + disp2));
						v.vertex.y *= _SineAmplitude * sin(_SineFrequency.y * (dotprod2 + disp2));

						o.pos = mul(UNITY_MATRIX_MVP,   v.vertex);
						o.uv = v.texcoord;

				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture
				fixed4 main = tex2D(_MainTex, i.uv);
				fixed4 dynoSmoke = tex2D(_DynamicTex, i.uv);

				//if(distance(i.wPos, _WorldSpaceCameraPos) > 241)
				//dynoSmoke.a = 0;//lerp(0, dynoSmoke.a, distance(i.wPos, _WorldSpaceCameraPos) /241);

				fixed4 col = main + dynoSmoke;
				return col;
			}
			ENDCG
		}

	}
}
