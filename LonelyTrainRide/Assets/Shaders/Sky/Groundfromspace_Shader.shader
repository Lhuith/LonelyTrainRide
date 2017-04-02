// Upgrade NOTE: commented out 'float3 _WorldSpaceCameraPos', a built-in variable
// Good Color 5BA6C8FF

Shader "Custom/Test/Ground_From_Space"
{
	Properties
	{
		_Color("Main Color", Color) = (1,1,1,1)
		_MainTex("Texture", 2D) = "white" {}
		_fScaleDepth("Scale", Float) = 1.0
		_ESun("Enviroment Sun", Float) = 1.0
		_fOuterRadius("Outer Radius", Float) = 1.0
		_fInnerRadius("Inner Radius", Float) = 1.0
		_Kr("KR", Float) = 1.0
		_Km("Km", Float) = 1.0
		_fSamples("Number Of Scatter Checks", Float) = 1.0
		_G("G", Float) = 0.0
	} 


	SubShader
	{
	 Pass{
	Tags { "LightMode" = "ForwardBase"  }
 	 
	 CGPROGRAM
	 #pragma vertex vert
	 #pragma fragment frag
	 #include "UnityCG.cginc"
	 #define PI 3.14159265f;

	 //The Cameras current Position
	 uniform sampler2D _MainTex;
	 uniform float4 _MainTex_ST;
	 
	 uniform float3 _viewDir; //View Direction
	 uniform float _fCameraHeight; //The Camera's current height
	 uniform float _fCameraHeight2;
	 uniform float3 _v3InWaveLength; // 1 / pow(waveLength, 4) for RGB
	 uniform float3 _waveLength; //WaveLength Colors
	 uniform float _fOuterRadius; //The outer(atmosphere) radius
	 uniform float _fInnerRadius; //The inner (planetery) radius
	 uniform float _ESun;
	 uniform float _Kr;
	 uniform float _Km;
	 uniform float _fScale;
	 uniform float _fScaleDepth;
	 uniform float _fSamples;
	 uniform float _nSamples;
	 uniform float _fKr4PI;
	 uniform float _fKm4PI;
	 uniform float _fKrESun;
	 uniform float _fKmESun;
	 uniform float _fOuterRadius2;
	 uniform float _fInnerRadius2;
	 uniform float _fInvScaleDepth;
	 uniform float _fScaleOverScaleDepth;
	 
	 uniform half4 _LightColor0;

	 float getNearIntersection(float3 pos, float3 ray, float distance2, float radius2)
	 {
	 	float B = 2.0 * dot(pos, ray);
	 	float C = distance2 - radius2;
	 	float det = max(0.0, B*B - 4.0 * C);
	 	return 0.5 * (-B - sqrt(det));
	 } 
	 
	 float scale(float fcos)
	 {
	 	float x = 1 - fcos;
	 	return _fScaleDepth * (exp(-0.00287 + x * (0.459 + x * (3.83 + x * (-6.80 + x * 5.25)))));
	 }
	 
	 
	 struct v2f
	 {
	 	float4 pos : SV_POSITION;
	 	float4 frontColor : COLOR0;
	 	float4 frontSecondaryColor : COLOR1;
	 	float4 tex : TEXCOORD1;
	 	float3 lightDir : TEXCOORD2;
	 	float3 normalDir : TEXCOORD3;
	 };
	 
	 v2f vert(appdata_base v)
	 {
	 	v2f o; 


	_v3InWaveLength = float3(
       1.0f / pow(0.650f, 4),
	   1.0f / pow(0.570f, 4),
	   1.0f / pow(0.475f, 4));

		_fKr4PI = (_Kr * 4) * PI;
		_fKm4PI = (_Km * 4) * PI;
		_fKrESun = _Kr * _ESun;
		_fKmESun = _Km * _ESun;

	 	o.normalDir = normalize(mul(float4(v.normal, 0.0), unity_WorldToObject).xyz);

	 	_fCameraHeight = length(_WorldSpaceCameraPos.xyz);
	 	_fCameraHeight2 = _fCameraHeight * _fCameraHeight;

	 	float3 v3Pos =  mul(unity_ObjectToWorld, v.vertex);
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
	 	 float fDepth = exp((_fInnerRadius - _fOuterRadius) / _fScaleDepth);
	 	 float fCameraAngle = dot(-v3Ray, v3Pos) /  length(v3Pos);
	 	 float fLightAngle = dot(o.lightDir.xyz, v3Pos) /  length(v3Pos);
	 	 float fCameraScale = scale(fCameraAngle);
	 	 float fLightScale = scale(fLightAngle);
	 	 float fCameraOffset = fDepth * fCameraScale;
	 	 float fTemp = (fCameraScale + fLightScale);
	 	
	 	 float fSampleLength = fFar / _fSamples;
	 	 float fScaledLength = fSampleLength * _fScale;
	 	 float3 v3SampleRay = v3Ray * fSampleLength;
	 	 float3 v3SamplePoint = v3Start + v3SampleRay * 0.5;
	 	
	 	 //Now loop through the sample points
	 	float3 v3FrontColor = float3(0.0,0.0,0.0);
	 	float3 v3Attenuate;
	 	
	 	 for(int i = 0; i < _nSamples; i++)
	 	 { 
	 		float fHeight = length(v3SamplePoint);
	 		float fDepth = exp(_fScaleOverScaleDepth * (_fInnerRadius - fHeight)); 
	 		float fScatter = fDepth * fTemp - fCameraOffset;
	 	    v3Attenuate = exp(-fScatter * (_v3InWaveLength * _fKr4PI + _fKm4PI));
	 		v3FrontColor += v3Attenuate * (fDepth * fScaledLength);
	 		v3SamplePoint += v3SampleRay;
	 	}
	 	
	 	o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
	 	o.frontColor.rgb = v3FrontColor * (_v3InWaveLength.xyz * _fKrESun + _fKmESun);
	 	o.frontSecondaryColor.rgb = v3Attenuate;
	 	o.tex = v.texcoord;
	 	return o;
	 }
	 
	 fixed4 frag(v2f i) : SV_TARGET
	 {
	 	fixed nDotL = dot(i.normalDir, i.lightDir.xyz);
	 
	 	float3 color = i.frontColor + 0.25 * i.frontSecondaryColor;
	 	float atten = 1.0;
	 	float3 diffuseReflection =  _LightColor0.xyz * saturate(nDotL);
	 
	 	float4 tex = tex2D(_MainTex, i.tex.xy * _MainTex_ST.xy + _MainTex_ST.zw);
	 
	 	return float4((color * tex), 1.0);
	 }
	 	ENDCG
	 
	 
	 }

	//Pass{
	//
	//Tags { "LightMode" = "ForwardBase" }
	////ZWrite Off
	////AlphaToMask On
	//	CGPROGRAM
	//	#pragma vertex vert
	//	#pragma fragment frag
	//	#include "UnityCG.cginc"
	//	#define PI 3.14159265
	//
	//////The Cameras current Position
    ////static const float PI = 3.14159265;
	//uniform sampler2D _MainTex;
	//uniform float4 _MainTex_ST;
	//uniform float4 _Color;
	//uniform float3 _viewDir; //View Direction
	//uniform float _fCameraHeight; //The Camera's current height
	//uniform float _fCameraHeight2;
	//uniform float3 _v3InWaveLength; // 1 / pow(waveLength, 4) for RGB
	//uniform float4 _waveLength; //WaveLength Colors
	//uniform float _fOuterRadius; //The outer(atmosphere) radius
	//uniform float _fInnerRadius; //The inner (planetery) radius
	//uniform float _ESun;
	//uniform float _Kr;
	//uniform float _Km;
	//uniform float _fScale;
	//uniform float _fScaleDepth;
	//uniform float _fSamples;
	//uniform float _nSamples;
	//uniform float _fKr4PI;
	//uniform float _fKm4PI;
	//uniform float _fKrESun;
	//uniform float _fKmESun;
	//uniform float _fOuterRadius2;
	//uniform float _fInnerRadius2;
	//uniform float _fInvScaleDepth;
	//uniform float _fScaleOverScaleDepth;
	//uniform float _G;
	//uniform float _G2;
	//
	//float getRayleighPhase(float fCos2)
	//{
	//	return 0.75 + 0.75 * fCos2;
	//}
	//
	//float getNearIntersection(float3 pos, float3 ray, float distance2, float radius2)
	//{
	//	float B = 2.0 * dot(pos, ray);
	//	float C = distance2 - radius2;
	//	float det = max(0.0, B*B - 4.0 * C);
	//	return 0.5 * (-B - sqrt(det));
	//} 
	//
	//float scale(float fCos)
	//{
	//	float x = 1 - fCos;
	//	return _fScale * (exp(-0.00287 + x * (0.459 + x * (3.83 + x * (-6.80 + x * 5.25)))));
	//}
	//
	//
	//struct v2f
	//{
	//	float4 pos : SV_POSITION;
	//	float4 frontColor : COLOR0;
	//	float4 frontSecondaryColor : COLOR1;
	//	float4 tex : TEXCOORD1;
	//	float3 lightDir : TEXCOORD2;
	//	float3 normalDir : TEXCOORD3;
	//	float3 v3Direction : TEXCOORD4;
	//};
	//
	//v2f vert(appdata_full v)
	//{
	//
	//v2f o;
	//
	//_v3InWaveLength = float3(
    //    1.0f / pow(0.650f, 4),
    //    1.0f / pow(0.570f, 4),
    //    1.0f / pow(0.475f, 4));
	//
    // _fKr4PI = (_Kr * 4) * PI;
    // _fKm4PI = (_Km * 4) * PI;
    ////_fKrESun = _Kr * _ESun;
    ////_fKmESun = _Km * _ESun;
    ////_fOuterRadius2 = (_fOuterRadius * _fOuterRadius);
    ////_fInnerRadius2 = (_fInnerRadius * _fInnerRadius);
    ////_fScale =  1 / (_fOuterRadius - _fInnerRadius);
    ////_fInvScaleDepth = 1.0f / _fScaleDepth;
    ////_fScaleOverScaleDepth = _fScale / _fScaleDepth;
    ////_G2 = _G * _G;
	//// _Object2World
	//	half4 posWorld = mul(unity_ObjectToWorld, v.vertex);
	//	 _viewDir = (_WorldSpaceCameraPos.xyz - posWorld.xyz);
	//	 half3 fragmentToLightSource = _WorldSpaceLightPos0.xyz - posWorld.xyz;
	//	//
	//	 //o.lightDir = _WorldSpaceLightPos0.xyz - v.vertex.xyz;//float4(
	//			      //normalize(lerp(_WorldSpaceLightPos0.xyz, fragmentToLightSource, _WorldSpaceLightPos0.w)),
	//			      //lerp(1.0, 1.0/length(fragmentToLightSource), _WorldSpaceLightPos0.w));
	//			  
	//
	//	//Get the ray from the camera to the vertex and its length (which
	//	// is the far point of the ray passing through the atmosphere)
	//	_fCameraHeight = length(_WorldSpaceCameraPos.xyz);
	//	_fCameraHeight2 = _fCameraHeight * _fCameraHeight;
	//	
	//	float3 v3Pos =  v.vertex.xyz;
	//	o.lightDir = normalize(v3Pos - _WorldSpaceLightPos0.xyz);
	//	float3 v3Ray = normalize(v3Pos - _WorldSpaceCameraPos.xyz);
	//	float fFar = length(v3Ray);
	//	v3Ray /= fFar;
	//	
	//	//Calculate the closest intersection of the ray with
	//	//the outher atmosphere
	//	
	//	//float fNear = getNearIntersection(_WorldSpaceCameraPos.xyz, v3Ray, _fCameraHeight2,
	//	// _fOuterRadius2);
	//	float B = 2.0 * dot(_WorldSpaceCameraPos.xyz, v3Ray);
	//	float C = _fCameraHeight2 - _fOuterRadius2;
	//	float fDet = max(0.0, B*B - 4.0 * C);
	//	float fNear = 0.5 * (-B - sqrt(fDet));
	//
	//	 //Calulate the rays start and end positions in the atmosphere,
	//	 //then calculate its scattering offset
	//	
	//	 float3 v3Start = _WorldSpaceCameraPos.xyz + v3Ray * fNear;
	//	 fFar -= fNear;	
	//	 float fStartAngle = dot(v3Ray, v3Start) / _fOuterRadius;
	//	 float fStartDepth = exp(-1.0 / _fScaleDepth);
	//	 float fStartOffset = fStartDepth * scale(fStartAngle);
	//	 
	//		
	//	 o.frontColor = float4(0,0,0,0);
	//	 float fSampleLength = fFar / _fSamples; 
	//	 float fScaledLength = fSampleLength * _fScale;
	//	 float3 v3SampleRay = v3Ray * fSampleLength;
	//	 float3 v3SamplePoint = v3Start + v3SampleRay * 0.5;
	//	
	//	 //Now loop through the sample points
	//	float3 v3FrontColor = float3(0.0,0.0,0.0);
	//	float3 v3Attenuate = float3(0,0,0);
	//
	//	 for(int i = 0; i < _nSamples; i++)
	//	 { 
	//		float fHeight = length(v3SamplePoint);
	//		float fDepth = exp(_fScaleOverScaleDepth * (_fInnerRadius - fHeight)); 
	//		float fLightAngle = dot(o.lightDir, v3SamplePoint) / fHeight;
	//		float fCameraAngle = dot(v3Ray, v3SamplePoint) / fHeight;
	//		float fScatter = (fStartOffset + fDepth * (scale(fLightAngle) - scale(fCameraAngle)));
	//	    float3 v3Attenuate = exp(-fScatter * (_v3InWaveLength * _fKr4PI + _fKm4PI));
	//
	//		v3FrontColor += v3Attenuate * (fDepth * fScaledLength);
	//		v3SamplePoint += v3SampleRay;
	//	 }
	//
	//	//Finally, scale the Mie and Rayleigh colors;
	//	o.frontSecondaryColor.rgb = v3FrontColor * _fKmESun;
	//	o.frontColor.rgb = v3FrontColor * (_v3InWaveLength.xyz * _fKrESun);
	//	o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
	//	o.v3Direction = _WorldSpaceCameraPos.xyz - v3Pos;
	//	return o;
	//}
	//
	//fixed4 frag(v2f i) : SV_TARGET
	//{
	//	float fCos = dot(i.lightDir, i.v3Direction.xyz) / length(i.v3Direction);
	//
	//	float fMiePhase = 1.5 * ((1.0 - _G2) / (2.0 + _G2)) * (1.0 + fCos * fCos) / 
	//					pow(1.0 + _G2 - 2.0 * _G * fCos, 1.5);
	//						
	//	float4 color = i.frontColor + fMiePhase * i.frontSecondaryColor;
	//	color.a = color.b;
	//	return color;
	//}
	//	ENDCG
	//
	//
	//}

}
}
