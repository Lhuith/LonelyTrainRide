// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Skybox/Atmospheric_Scatter_Shader"
{
Properties
	{
		_Color("Color Tst", Color) = (1.0,1.0,1.0,1.0)
		_fSamples("Number Of Scatter's", Float) = 1.0
		_fScaleDepth("Depth Scale", Float) = 1.0
		_ESun("Enviroment Sun", Float) = 1.0
		_fOuterRadius("Outer Radius", Float) = 1.0
		_fInnerRadius("Inner Radius", Float) = 1.0
		_Kr("KR", Float) = 1.0
		_Km("Km", Float) = 1.0
		_G("G", Float) = 0.0
	} 

	SubShader
	{ 
	Pass{
	
	Tags { "Queue" = "Background" "RenderType" = "Background" "PreviewType" = "Skybox" "LightMode" = "ForwardBase"  }
		  Cull Off
		  ZWrite Off
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#include "UnityCG.cginc"
		#define PI 3.14159265f
		#define _fKr4PI (_Kr * 4 * PI)
		#define _fKm4PI (_Km * 4) * PI

	//const static float PI = 3.14159265f;
	uniform float4 _Color;
	uniform float3 _viewDir; //View Direction
	uniform float _fCameraHeight; //The Camera's current height
	uniform float _fCameraHeight2;
	uniform float3 _v3InWaveLength; // 1 / pow(waveLength, 4) for RGB
	uniform float4 _waveLength; //WaveLength Colors
	uniform float _fOuterRadius; //The outer(atmosphere) radius
	uniform float _fInnerRadius; //The inner (planetery) radius
	uniform float _ESun;
	uniform float _Kr;
	uniform float _Km;
	uniform float _fScale;
	uniform float _fScaleDepth;
	uniform float _fSamples;
	uniform float _nSamples;
	//uniform float _fKr4PI;
	//uniform float _fKm4PI;
	uniform float _fKrESun;
	uniform float _fKmESun;
	uniform float _fOuterRadius2;
	uniform float _fInnerRadius2;
	uniform float _fInvScaleDepth;
	uniform float _fScaleOverScaleDepth;
	uniform float _G;
	uniform float _G2;
	
	float getRayleighPhase(float fCos2)
	{
		return 0.75 + 0.75 * fCos2;
	}
	
	float getNearIntersection(float3 pos, float3 ray, float distance2, float radius2)
	{
		float B = 2.0 * dot(pos, ray);
		float C = distance2 - radius2;
		float fdet = max(0.0, B*B - 4.0 * C);
		return 0.5 * (-B - sqrt(fdet));
	} 
	
	float scale(float fCos)
	{
		float x = 1 - fCos;
		return _fScaleDepth * exp(-0.00287 + x*(0.459 + x*(3.83 + x*(-6.80 + x*5.25))));
	}
	
	
	struct v2f
	{
		float4 pos : POSITION;
		float4 frontColor : TEXCOORD0;
		float4 frontSecondaryColor : TEXCOORD1;
		float3 lightDir : TEXCOORD3;
		float3 normalDir : TEXCOORD4;
		float3 v3Direction : TEXCOORD5;
	};
	
	v2f vert(appdata_base v)
	{
	
	v2f o;
	
	_v3InWaveLength = float3(
        1.0f / pow(0.650f, 4),
        1.0f / pow(0.570f, 4),
        1.0f / pow(0.475f, 4));
	
		//_fKr4PI = (_Kr * 4) * PI;
		//_fKm4PI = (_Km * 4) * PI;
		_fKrESun = _Kr * _ESun;
		_fKmESun = _Km * _ESun;


		//Get the ray from the camera to the vertex and its length (which
		// is the far point of the ray passing through the atmosphere)
		_fCameraHeight = length(_WorldSpaceCameraPos.xyz);
		_fCameraHeight2 = _fCameraHeight * _fCameraHeight;

		o.normalDir = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject).xyz);

		float3 v3Pos =mul(unity_ObjectToWorld, v.vertex);
		float3 v3Ray = (v3Pos - _WorldSpaceCameraPos.xyz);
		o.lightDir = normalize(_WorldSpaceLightPos0.xyz);
		float fFar = length(v3Ray);
		v3Ray /= fFar;
		
		//Calculate the closest intersection of the ray with
		//the outher atmosphere
		
		float fNear = getNearIntersection(_WorldSpaceCameraPos.xyz, v3Ray, _fCameraHeight2,
		 _fOuterRadius2);
	
		 //Calulate the rays start and end positions in the atmosphere,
		 //then calculate its scattering offset
		
		 float3 v3Start = _WorldSpaceCameraPos.xyz + v3Ray * fNear;
		 fFar -= fNear;	
		 float fStartAngle = dot(v3Ray, v3Start) / _fOuterRadius;
		 float fStartDepth = exp(-1.0 / _fScaleDepth);
		 float fStartOffset = fStartDepth * scale(fStartAngle);
		 
			
		 o.frontColor = float4(0.0,0.0,0.0,0.0);
		 float fSampleLength = fFar / _fSamples; 
		 float fScaledLength = fSampleLength * _fScale;
		 float3 v3SampleRay = v3Ray * fSampleLength;
		 float3 v3SamplePoint = v3Start + v3SampleRay * 0.5;
		
		 //Now loop through the sample points
		float3 v3FrontColor = float3(0.0,0.0,0.0);
	
		 for(int i = 0; i < 2; i++)
		 { 
			float fHeight = length(v3SamplePoint);
			float fDepth = exp(_fScaleOverScaleDepth * (_fInnerRadius - fHeight)); 
			float fLightAngle = dot(o.lightDir.xyz, v3SamplePoint) / fHeight;
			float fCameraAngle = dot(v3Ray, v3SamplePoint) / fHeight;
			float fScatter = (fStartOffset + fDepth * (scale(fLightAngle) - scale(fCameraAngle)));
		    float3 v3Attenuate = exp(-fScatter * (_v3InWaveLength * _fKr4PI + _fKm4PI));
			v3FrontColor += v3Attenuate * (fDepth * fScaledLength);
			v3SamplePoint += v3SampleRay;
		 }
	
		//Finally, scale the Mie and Rayleigh colors;
		o.pos = UnityObjectToClipPos(v.vertex);
		o.frontSecondaryColor.rgb = v3FrontColor * _fKmESun;
		o.frontColor.rgb = v3FrontColor * (_v3InWaveLength.xyz * _fKrESun);
		o.v3Direction = (_WorldSpaceCameraPos.xyz - v3Pos);
		return o;
	}
	
	fixed4 frag(v2f i) : SV_TARGET
	{
		float fCos = dot(i.lightDir.xyz, i.v3Direction.xyz) / length(i.v3Direction);
		float fCos2 = fCos * fCos;
		float fMiePhase = 1.5 * ((1.0 - _G2) / (2.0 + _G2)) * (1.0 + fCos * fCos) / 
						pow(1.0 + _G2 - 2.0 * _G * fCos, 1.5);
							
		float4 color = getRayleighPhase(fCos2) * i.frontColor + fMiePhase * i.frontSecondaryColor;
		color.a = color.b;
		return float4(_Color.rgb, 1.0);
	}
		ENDCG
	
	
	}
	}
}
