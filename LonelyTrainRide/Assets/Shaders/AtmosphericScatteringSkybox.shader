// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

//  Copyright(c) 2016, Michal Skalsky
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation
//     and/or other materials provided with the distribution.
//
//  3. Neither the name of the copyright holder nor the names of its contributors
//     may be used to endorse or promote products derived from this software without
//     specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY
//  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
//  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.IN NO EVENT
//  SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
//  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
//  OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
//  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
//  TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
//  EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


Shader "Skybox/AtmosphericScattering"
{

    Properties
    {
        _SampleCount0("Sample Count (min)", Float) = 30
        _SampleCount1("Sample Count (max)", Float) = 90
        _SampleCountL("Sample Count (light)", Int) = 16

        [Space]
        _NoiseTex1("Noise Volume", 3D) = ""{}
        _NoiseTex2("Noise Volume", 3D) = ""{}
        _NoiseFreq1("Frequency 1", Float) = 3.1
        _NoiseFreq2("Frequency 2", Float) = 35.1
        _NoiseAmp1("Amplitude 1", Float) = 5
        _NoiseAmp2("Amplitude 2", Float) = 1
        _NoiseBias("Bias", Float) = -0.2

        [Space]
        _Scroll1("Scroll Speed 1", Vector) = (0.01, 0.08, 0.06, 0)
        _Scroll2("Scroll Speed 2", Vector) = (0.01, 0.05, 0.03, 0)

        [Space]
        _Altitude0("Altitude (bottom)", Float) = 1500
        _Altitude1("Altitude (top)", Float) = 3500
        _FarDist("Far Distance", Float) = 30000

        [Space]
        _Scatter("Scattering Coeff", Float) = 0.008
        _HGCoeff("Henyey-Greenstein", Float) = 0.5
        _Extinct("Extinction Coeff", Float) = 0.01

        [Space]
        _SunSize ("Sun Size", Range(0,1)) = 0.04
        _AtmosphereThickness ("Atmoshpere Thickness", Range(0,5)) = 1.0
        _SkyTint ("Sky Tint", Color) = (.5, .5, .5, 1)
        _GroundColor ("Ground", Color) = (.369, .349, .341, 1)
        _Exposure("Exposure", Range(0, 8)) = 1.3
    }



	SubShader
	{
		Tags{ "Queue" = "Background" "RenderType" = "Background" "PreviewType" = "Skybox" }
		Cull Off ZWrite Off

		Pass
		{
			CGPROGRAM
			#pragma shader_feature ATMOSPHERE_REFERENCE
			#pragma shader_feature RENDER_SUN
			#pragma shader_feature HIGH_QUALITY
			
			#pragma vertex vert
			#pragma fragment frag

			#pragma target 5.0
			
			#include "UnityCG.cginc"
			#include "AtmosphericScattering.cginc"

			float3 _CameraPos;

			struct v2f
			{
				float4	pos		: SV_POSITION;
				float3	vertex	: TEXCOORD0;
				float2 uv : TEXCOORD1;
				float3 rayDir : TEXCOORD2;
				float3 groundColor : TEXCOORD3;
				float3 skyColor : TEXCOORD4;
				float3 sunColor : TEXCOORD5; 
			};

			v2f vert (appdata_base v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.vertex = v.vertex;
				return o;
			}


			
			fixed4 frag (v2f i) : SV_Target
			{

#ifdef ATMOSPHERE_REFERENCE
					
									
				float3 rayStart = _CameraPos;
				float3 rayDir = normalize(mul((float3x3)unity_ObjectToWorld, i.vertex));

				float3 lightDir = -_WorldSpaceLightPos0.xyz;

				float3 planetCenter = _CameraPos;
				planetCenter = float3(0, -_PlanetRadius, 0);

				float2 intersection = RaySphereIntersection(rayStart, rayDir, planetCenter, _PlanetRadius + _AtmosphereHeight);		
				float rayLength = intersection.y ;

				intersection = RaySphereIntersection(rayStart, rayDir, planetCenter, _PlanetRadius);
				if (intersection.x > 0)
					rayLength = min(rayLength, intersection.x);

				float4 extinction;
				float4 inscattering = IntegrateInscattering(rayStart, rayDir, rayLength, planetCenter, 1, lightDir, 16, extinction);

				
				return float4(inscattering.xyz, 1);
#else
				float3 rayStart = _CameraPos;
				float3 rayDir = normalize(mul((float3x3)unity_ObjectToWorld, i.vertex));

				float3 lightDir = -_WorldSpaceLightPos0.xyz;

				float3 planetCenter = _CameraPos;
				planetCenter = float3(0, -_PlanetRadius, 0);

				float4 scatterR = 0;
				float4 scatterM = 0;

				float height = length(rayStart - planetCenter) - _PlanetRadius;
				float3 normal = normalize(rayStart - planetCenter);

				float viewZenith = dot(normal, rayDir);
				float sunZenith = dot(normal, -lightDir);

				float3 coords = float3(height / _AtmosphereHeight, viewZenith * 0.5 + 0.5, sunZenith * 0.5 + 0.5);

				coords.x = pow(height / _AtmosphereHeight, 0.5);
				float ch = -(sqrt(height * (2 * _PlanetRadius + height)) / (_PlanetRadius + height));
				if (viewZenith > ch)
				{
					coords.y = 0.5 * pow((viewZenith - ch) / (1 - ch), 0.2) + 0.5;
				}
				else
				{
					coords.y = 0.5 * pow((ch - viewZenith) / (ch + 1), 0.2);
				}
				coords.z = 0.5 * ((atan(max(sunZenith, -0.1975) * tan(1.26*1.1)) / 1.1) + (1 - 0.26));

				scatterR = tex3D(_SkyboxLUT, coords);			

#ifdef HIGH_QUALITY
				scatterM.x = scatterR.w;
				scatterM.yz = tex3D(_SkyboxLUT2, coords).xy;
#else
				scatterM.xyz = scatterR.xyz * ((scatterR.w) / (scatterR.x));// *(_ScatteringR.x / _ScatteringM.x) * (_ScatteringM / _ScatteringR);
#endif

				float3 m = scatterM;
				//scatterR = 0;
				// phase function
				ApplyPhaseFunctionElek(scatterR.xyz, scatterM.xyz, dot(rayDir, -lightDir.xyz));
				float3 lightInscatter = (scatterR * _ScatteringR + scatterM * _ScatteringM) * _IncomingLight.xyz;
#ifdef RENDER_SUN
				lightInscatter += RenderSun(m, dot(rayDir, -lightDir.xyz)) * _SunIntensity;
#endif

				return float4(max(0, lightInscatter), 1);
#endif
			}
			ENDCG
		}
	}
}
