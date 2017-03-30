// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced 'glstate.matrix.mvp' with 'UNITY_MATRIX_MVP'

Shader "Eugene/WaterShaderV6" {
Properties{

	_Color("Color_Tint", Color) = (1.0,1.0,1.0,1.0)
	_MainTex("Diffuse Texture", 2D) = "white" {}
	_SpecColor("Specular Color", Color) = (1.0,1.0,1.0,1.0)
	
	_AniX("Anisotropic X", Range(0.0, 2.0)) = 1.0
	_AniY("Anisotropic Y", Range(0.0, 2.0)) = 1.0
	
	_Shininess("Shininess", Float) = 1.0
	_NoiseMap("Noise_Map", 2D) = "white" {}
	_MipMap("Mip_Map", 2D) = "white"{}
	_GlitterStrengh("Glitter Strengh", Range(0.0, 20)) = 0.3
	
	_NormalMap("Bump Map", 2D) = "white" {}
	_BumpDepth("Bump Depth", Float) = 0.1
	_Curvature ("Curvature", Float) = 0.001
	
	_DepthTexture("Depth Texture", 2D) = "white" {}
	_DepthFactor("Deepness", Float) = 0.1

	//Translucant Variables
	_BackScatter("Back Translucent Color", Color) = (1.0,1.0,1.0,1.0) 
	_Translucence("Forward Translucent Color", Color) = (1.0,1.0,1.0,1.0)
	_Intensity("Translucent Intensity", Float) = 10.0
	
    _ExtrudeTex ("Extrusion Texture", 2D) = "white" {}
    _Amount ("Extrusion Amount", Range(-1,1)) = 0.5
     
    _ExtrudeDetail ("Extrusion Detail Texture", 2D) = "white" {}
     
    _SineAmplitude ("Amplitude", Float) = 1.0
   //the following three are vectors so we can control more than one wave easily
   _SineFrequency ("Frequency", Vector) = (1,1,0,0)
   _Speed ("Speed", Vector) = (1,1,0,0)
   _Steepness ("steepness", Vector) = (1,1,0,0)
   //two direction vectors as we are using two gerstner waves
   _Dir ("Wave Direction", Vector) = (1,1,0,0)
   _Dir2 ("2nd Wave Direction", Vector) = (1,1,0,0)
   
    _ObjectScale ("_ObjectScale", Vector) = (0,0,0,0)

    _TimeCostum ("Time", float) = 0.0
    
	_Smoothing("Normal Smoothing", float) = 10
}
	SubShader{

	// Grab the screen behind the object into _GrabTexture, using default values
		Pass{

			Tags{ "LightMode" = "ForwardBase"}
			Blend One SrcColor
			//Blend One One 
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#pragma multi_compile_fwdadd_fullshadows
			 
			//user defined verables
			uniform fixed4 _Color;
			uniform fixed4 _SpecColor;
			uniform fixed _AniX;
			uniform fixed _AniY;
			uniform half _Shininess;
			
			uniform sampler2D _MainTex;
			uniform half4 _MainTex_ST;
			
			uniform sampler2D _NoiseMap;
			uniform half4 _NoiseMap_ST;
			
			uniform sampler2D _NormalMap;
			uniform half4 _NormalMap_ST;
			
			uniform sampler2D _MipMap;
			uniform half4 _MipMap_ST;
			
			uniform fixed _GlitterStrengh;
			uniform half _BumpDepth;
			
			uniform half _WaveXPos;
			uniform half _WaveYPos;
			uniform half _WaveZPos;
			
			uniform fixed _WaveScale;
			uniform fixed _WaveSpeed;
			uniform fixed _WaveDistance;
			
			
			uniform fixed4 _BackScatter;
			uniform fixed4 _Translucence;
			uniform half _Intensity;
			
			uniform sampler2D _ExtrudeTex;
			uniform half4 _ExtrudeTex_ST;
			
			uniform sampler2D _ExtrudeDetail;
			uniform half4 _ExtrudeDetail_ST;
			
			uniform half _Amount;
			
			float _SineAmplitude;
			float4 _SineFrequency;
			float4 _Speed;
			float4 _Steepness;
			float4 _Dir;
			float4 _Dir2;
			
			float _Smoothing;
			
			uniform float3 _ObjectScale; 
			uniform float _TimeCostum; 
		
        
			//Ripple Amplitudes and there offets
				
			
			//unity defined verables
			uniform half4 _LightColor0;
			//Base Input structs
        	
  
        
			struct VertexInput{
				half4 vertex : POSITION;
				half3 normal : NORMAL;
				half4 tangent : TANGENT;
				float2 texcoord : TEXCOORD0;
				
			};
			
			struct VertexOutput{
				half4 pos : SV_POSITION;
				half2 tex : TEXCOORD0;
				fixed3 normalDir : TEXCOORD1;
				fixed4 lightDir : TEXCOORD2;
				fixed3 viewDir : TEXCOORD3;
				fixed3 tangentDir : TEXCOORD4;
				float2 uv : TEXCOORD5;
				fixed3 binormalDir : TEXCOORD9;
				float3 posWorld : TEXCOORD10;
				LIGHTING_COORDS(11,12)
			};
			

			//vertex function
			VertexOutput vert(VertexInput v)
			{
			
			VertexOutput o;	
						
						o.posWorld = mul(unity_ObjectToWorld, v.vertex);
					
							
				
						//float4 tex = tex2Dlod (_ExtrudeTex, float4(v.texcoord0.xy,0,0));
						float4 tex2 = tex2Dlod (_ExtrudeDetail, float4(v.texcoord.xy,0,0));
						
						
						float2 dir = _Dir.xy;
						dir = normalize(dir);
						float dotprod = dot(dir, o.posWorld.xz);
						float disp = _TimeCostum * _Speed.x;

						//do the same for our second wave
						float2 dir2 = _Dir2.xy;
						dir2 = normalize(dir2);
						float dotprod2 = dot(dir2, o.posWorld.xz);
						float disp2 = _TimeCostum * _Speed.y;										
						
												
						float3 v1 = v.vertex + float3(0.05, 0 , 0);
						float3 v2 = v.vertex + float3(0.0, 0 , 0.05);
						
								
						v.vertex.x += (_Steepness.x *_SineAmplitude) *_Dir.x * cos(_SineFrequency.x* (dotprod + disp))/_ObjectScale.x;
						v.vertex.z += (_Steepness.x *_SineAmplitude) *_Dir.y * cos(_SineFrequency.x * (dotprod + disp))/_ObjectScale.z;
						v.vertex.y += _SineAmplitude * - sin(_SineFrequency.x*dotprod + disp )/_ObjectScale.y;
						
						v1.x += (_Steepness.x *_SineAmplitude) *_Dir.x * cos(_SineFrequency.x* (dotprod + disp))/_ObjectScale.x;
						v1.z += (_Steepness.x *_SineAmplitude) *_Dir.y * cos(_SineFrequency.x * (dotprod + disp))/_ObjectScale.z;
						v1.y += _SineAmplitude * - sin(_SineFrequency.x*dotprod + disp )/_ObjectScale.y;
	
						v2.x += (_Steepness.x *_SineAmplitude) *_Dir.x * cos(_SineFrequency.x* (dotprod + disp))/_ObjectScale.x;
						v2.z += (_Steepness.x *_SineAmplitude) *_Dir.y * cos(_SineFrequency.x * (dotprod + disp))/_ObjectScale.z;
						v2.y += _SineAmplitude * - sin(_SineFrequency.x*dotprod + disp )/_ObjectScale.y;

						v.vertex.x += (_Steepness.y *_SineAmplitude) * _Dir2.x *cos(_SineFrequency.y * (dotprod2 + disp2))/_ObjectScale.x;
						v.vertex.z += (_Steepness.y *_SineAmplitude) *_Dir2.y*  cos (_SineFrequency.y * (dotprod2 + disp2))/_ObjectScale.z;
						v.vertex.y += _SineAmplitude * sin(_SineFrequency.y * (dotprod2 + disp2)) /_ObjectScale.y;
						
						v1.x += (_Steepness.y *_SineAmplitude) * _Dir2.x *cos(_SineFrequency.y * (dotprod2 + disp2))/_ObjectScale.x;
						v1.z += (_Steepness.y *_SineAmplitude) *_Dir2.y*  cos (_SineFrequency.y * (dotprod2 + disp2))/_ObjectScale.z;
						v1.y += _SineAmplitude * sin(_SineFrequency.y * (dotprod2 + disp2)) /_ObjectScale.y;
						
						
						v2.x += (_Steepness.y *_SineAmplitude) * _Dir2.x *cos(_SineFrequency.y * (dotprod2 + disp2))/_ObjectScale.x;
						v2.z += (_Steepness.y *_SineAmplitude) *_Dir2.y*  cos (_SineFrequency.y * (dotprod2 + disp2))/_ObjectScale.z;
						v2.y += _SineAmplitude * sin(_SineFrequency.y * (dotprod2 + disp2)) /_ObjectScale.y;
						
						v1.y -= (v1.y - v.vertex.y) * _Smoothing;
						v2.y -= (v2.y - v.vertex.y) * _Smoothing;
						
						v1.z -= (v1.z - v.vertex.z) * _Smoothing;
						v2.z -= (v2.z - v.vertex.z) * _Smoothing;
						
						v1.x -= (v1.x - v.vertex.x) * _Smoothing;
						v2.x -= (v2.x - v.vertex.x) * _Smoothing;
						
						float3 vna = cross(v2 - v.vertex, v1 - v.vertex);
						
						float vn = mul(unity_WorldToObject, float4(vna,0.0));
						
						v.normal = normalize(vna);
					
	
						 
					//o.posWorld = mul(_Object2World, v.vertex);	
						
					o.tex = v.texcoord.xy;
					o.uv = float4( v.texcoord.xy, 0, 0 );
					//Normal Direction
					o.normalDir = v.normal; //normalize(mul(half4(v.normal, 0.0), _World2Object).xyz);
					//tangent Direction
					o.tangentDir = normalize(mul(unity_ObjectToWorld, half4(v.tangent.xyz, 0.0)).xyz);
					//Binormal direction
					o.binormalDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
					//Unity transform Position
					o.normalDir = normalize(cross(o.binormalDir, o.tangentDir));
					//tangent Direction
					o.pos = mul(UNITY_MATRIX_MVP, v.vertex);

					//view Direction
					o.viewDir = normalize(_WorldSpaceCameraPos.xyz - o.posWorld.xyz);
					//light Direction
					half3 fragmentToLightSource = _WorldSpaceLightPos0.xyz - o.posWorld.xyz;
					
					o.lightDir = fixed4(
					normalize(lerp(_WorldSpaceLightPos0.xyz, fragmentToLightSource, _WorldSpaceLightPos0.w)),
					lerp(1.0, 1.0/length(fragmentToLightSource), _WorldSpaceLightPos0.w)
					);
					TRANSFER_VERTEX_TO_FRAGMENT(o)
					return o;
}

			//fragment function
			fixed4 frag(VertexOutput i) : COLOR
			{
			
				fixed atten = LIGHT_ATTENUATION(i);	
				//Texture Unpack
			fixed4 texP = tex2D(_NoiseMap, i.tex.xy * _NoiseMap_ST.xy + _NoiseMap_ST.zw);
			half4 texM = tex2D( _MipMap, i.tex.x * _MipMap_ST.xy +_MipMap_ST.zw);
			half4 texB = tex2D( _MainTex, i.tex.xy * _MainTex_ST.xy + _MainTex_ST.zw);
			   
			half4 texwave = tex2D (_ExtrudeTex,  i.tex.xy * _ExtrudeTex_ST.xy + _ExtrudeTex_ST.zw);
			
			fixed4 texDetWave = tex2D(_ExtrudeDetail, i.tex.xy * _ExtrudeDetail_ST.xy + _ExtrudeDetail_ST.zw);

			//Normal Texture
			half4 texN = tex2D( _NormalMap, i.tex.xy + _Time.x/50 * _NormalMap_ST.xy + _NormalMap_ST.zw);
			//half4 texN = tex2D( _ExtrudeTex, i.tex.xy * _ExtrudeTex_ST.xy + _ExtrudeTex_ST.zw);
		
			
			//unpackNormal function
			fixed3 localCoords = float3(2.0 * texN.ag - float2(1.0, 1.0), _BumpDepth);
			
			//normal transpose matrix
			fixed3x3 local2WorldTranspose = fixed3x3(
			i.tangentDir,
			i.binormalDir,
			i.normalDir
			);
			
			//normalDirection.y += texwave.rgb;
			//i.normalDir.y *= sum;
			
			fixed3 normalDirection = normalize( mul(localCoords, local2WorldTranspose));
			
			
			//normalDirection.xyz += texwave.rgb;
			//Lighting
			fixed3 h = normalize(i.lightDir.xyz + i.viewDir);
			fixed3 binormalDir = cross(normalDirection, i.tangentDir);
			
			//dotProduct
			fixed nDotL = dot(normalDirection, i.lightDir.xyz);
			fixed nDotH = dot(normalDirection, h);
			fixed nDotV = dot(normalDirection, i.viewDir);
			fixed tDotHX = dot(i.tangentDir, h)/ _AniX;
			fixed bDotHY = dot(binormalDir, h)/ _AniY;
			
			//normalDirection.y += sum;
			
			fixed3 Reflection = pow(saturate(dot(reflect(-i.lightDir.xyz, normalDirection), i.viewDir)),_Shininess );
			//texB.rbg += texwave.rbg;
			//Diffuse Reflection
			fixed3 diffuseReflection =  i.lightDir.w * _LightColor0.xyz * saturate(nDotL);
			//Specular Reflection
			fixed3 AniospecularReflection =  diffuseReflection *( exp(-(tDotHX * tDotHX + bDotHY * bDotHY)) * _Shininess) * _SpecColor.xyz;

			
			//NormalReflecion
			fixed3 specularReflection = diffuseReflection * _SpecColor.xyz * pow(saturate(dot(reflect( - i.lightDir.xyz, i.normalDir),1.0)),_Shininess);
			
//			//Translucance
//			fixed3 backScatter = i.lightDir.w * _LightColor0.xyz * _BackScatter.xyz * saturate(dot(i.normalDir, -i.lightDir));
//			fixed3 translucence = i.lightDir.w * _LightColor0.xyz * _Translucence.xyz * pow(saturate(dot( -i.lightDir.xyz, i.viewDir)), _Intensity);
//			
			//Reflection Glitter
			float3 fp2 = saturate( frac(.7 * i.pos + 9 * texP.xyz + ( AniospecularReflection * 0.04).r + 0.3 * i.viewDir));
			fp2 *= (1 - fp2);
			texM.y *= 1;
			float glitter = saturate(1 - 3 * (fp2.x + fp2.y + fp2.z));
			float sparkle =	 glitter * pow(AniospecularReflection, 2.5) * _SpecColor.xyz;
			
			//General Glitter
			float specBase =	saturate( 4 * dot( normalDirection, i.viewDir )); // JOURNEY!!!!!!!!!!!!!!
			normalDirection.y *= 1;
			//texP.y *= 1;
			float3 fp1 = frac(.7 * i.pos + 9 * texM.xyz + ( specularReflection * 0.04).r + 0.3 * i.viewDir);
			fp1 *= (1 - fp1);
			float Normglitter = saturate(1 - 7 * (fp1.x + fp1.y + fp1.z));
			float Normsparkle =  Normglitter * (pow(AniospecularReflection, 2.5) * _SpecColor.xyz);
			
			//texB.rgb *= texDetWave.rgb;
			
			//texB.rgb *= lerp(texB, atten, _Amount);
			
			fixed3 lightFinal = specularReflection + AniospecularReflection + (Normsparkle * _GlitterStrengh)  + UNITY_LIGHTMODEL_AMBIENT.xyz;
			
			
			
			return fixed4((texB * _Color) + lightFinal, 1.0);
			}
			
			
			ENDCG
		}
 
        Pass {
        //Blend SrcAlpha OneMinusSrcAlpha 
        Name "ShadowCaster"
        	Tags {"LightMode" = "ShadowCaster"}
        	//Blend SrcAlpha OneMinusSrcAlpha 
    		Fog {Mode Off}
            ZWrite On ZTest Less Cull Off
            Offset [_ShadowBias], [_ShadowBiasSlope]
   
   			
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile SHADOWS_NATIVE SHADOWS_CUBE
            #pragma fragmentoption ARB_precision_hint_fastest
            #include "UnityCG.cginc"
			#include "AutoLight.cginc"
			#pragma multi_compile_fwdadd_fullshadows
				
			uniform fixed4 _TintColor;
			uniform	fixed _DepthFactor;
			
				uniform sampler2D _DepthTexture;
			uniform half4 _DepthTexture_ST;
			
			
			uniform float _Curvature;
			uniform half _Amount;
			
			
			uniform sampler2D _MainTex;
			uniform half4 _MainTex_ST;
			
				float _SineAmplitude;
			float4 _SineFrequency;
			float4 _Speed;
			float4 _Steepness;
			float4 _Dir;
			float4 _Dir2;
			float _Smoothing;
			uniform float3 _ObjectScale; 
			uniform float _TimeCostum;
			
            struct appdata_t {
                float4 vertex : POSITION;
                fixed4 color : COLOR;
                float4 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
            };
 
            struct v2f {
                float4 vertex : SV_POSITION;
              	half4 tex : TEXCOORD0;
                float4 projPos : TEXCOORD1;
                float4 posWorld: TEXCOORD2;
                LIGHTING_COORDS(3,4)
            };
           
 
 
            v2f vert (appdata_t v)
            {
         
            	v2f o;
            	
            			o.posWorld = mul(unity_ObjectToWorld, v.vertex);
						
						
						
						float2 dir = _Dir.xy;
						dir = normalize(dir);
						float dotprod = dot(dir, o.posWorld.xz);
						float disp = _TimeCostum * _Speed.x;

						//do the same for our second wave
						float2 dir2 = _Dir2.xy;
						dir2 = normalize(dir2);
						float dotprod2 = dot(dir2, o.posWorld.xz);
						float disp2 = _TimeCostum * _Speed.y;										
										
						float3 v1 = v.vertex + float3(0.05, 0 , 0);
						float3 v2 = v.vertex + float3(0.0, 0 , 0.05);
						
								
						v.vertex.x += (_Steepness.x *_SineAmplitude) *_Dir.x * cos(_SineFrequency.x* (dotprod + disp))/_ObjectScale.x;
						v.vertex.z += (_Steepness.x *_SineAmplitude) *_Dir.y * cos(_SineFrequency.x * (dotprod + disp))/_ObjectScale.z;
						v.vertex.y += _SineAmplitude * - sin(_SineFrequency.x*dotprod + disp )/_ObjectScale.y;
						
						v1.x += (_Steepness.x *_SineAmplitude) *_Dir.x * cos(_SineFrequency.x* (dotprod + disp))/_ObjectScale.x;
						v1.z += (_Steepness.x *_SineAmplitude) *_Dir.y * cos(_SineFrequency.x * (dotprod + disp))/_ObjectScale.z;
						v1.y += _SineAmplitude * - sin(_SineFrequency.x*dotprod + disp )/_ObjectScale.y;
	
						v2.x += (_Steepness.x *_SineAmplitude) *_Dir.x * cos(_SineFrequency.x* (dotprod + disp))/_ObjectScale.x;
						v2.z += (_Steepness.x *_SineAmplitude) *_Dir.y * cos(_SineFrequency.x * (dotprod + disp))/_ObjectScale.z;
						v2.y += _SineAmplitude * - sin(_SineFrequency.x*dotprod + disp )/_ObjectScale.y;


						v.vertex.x += (_Steepness.y *_SineAmplitude) * _Dir2.x *cos(_SineFrequency.y * (dotprod2 + disp2))/_ObjectScale.x;
						v.vertex.z += (_Steepness.y *_SineAmplitude) *_Dir2.y*  cos (_SineFrequency.y * (dotprod2 + disp2))/_ObjectScale.z;
						v.vertex.y += _SineAmplitude * sin(_SineFrequency.y * (dotprod2 + disp2)) /_ObjectScale.y;
						
						v1.x += (_Steepness.y *_SineAmplitude) * _Dir2.x *cos(_SineFrequency.y * (dotprod2 + disp2))/_ObjectScale.x;
						v1.z += (_Steepness.y *_SineAmplitude) *_Dir2.y*  cos (_SineFrequency.y * (dotprod2 + disp2))/_ObjectScale.z;
						v1.y += _SineAmplitude * sin(_SineFrequency.y * (dotprod2 + disp2)) /_ObjectScale.y;
						
						
						v2.x += (_Steepness.y *_SineAmplitude) * _Dir2.x *cos(_SineFrequency.y * (dotprod2 + disp2))/_ObjectScale.x;
						v2.z += (_Steepness.y *_SineAmplitude) *_Dir2.y*  cos (_SineFrequency.y * (dotprod2 + disp2))/_ObjectScale.z;
						v2.y += _SineAmplitude * sin(_SineFrequency.y * (dotprod2 + disp2)) /_ObjectScale.y;
						
						v1.y -= (v1.y - v.vertex.y) * _Smoothing;
						v2.y -= (v2.y - v.vertex.y) * _Smoothing;
						
						v1.z -= (v1.z - v.vertex.z) * _Smoothing;
						v2.z -= (v2.z - v.vertex.z) * _Smoothing;
						
						v1.x -= (v1.x - v.vertex.x) * _Smoothing;
						v2.x -= (v2.x - v.vertex.x) * _Smoothing;
						
						float3 vna = cross(v2 - v.vertex, v1 - v.vertex);
						
						//float vn = mul(_World2Object, float4(vna,0.0));
						
						v.normal = normalize(vna);
						
 						o.tex = v.texcoord;
            	
               	o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
				o.projPos = ComputeScreenPos (o.vertex);
				COMPUTE_EYEDEPTH(o.projPos.z);
	      
			
				//v.vertex += mul(_World2Object, vv);
				TRANSFER_VERTEX_TO_FRAGMENT(o)
                return o;
            }
 			
            sampler2D_float _CameraDepthTexture;
           
            fixed4 frag (v2f i) : COLOR
            {
            	fixed atten = LIGHT_ATTENUATION(i);	
             return  atten;
            }
            ENDCG
        }
        
//        Pass {
//        
//        Name "Dephth Check"
//        	Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
//    		Blend SrcAlpha OneMinusSrcAlpha 
//   			AlphaTest Greater .01
//    		ColorMask RGB
//   			Cull Off Lighting Off Zwrite Off
//   			
//            CGPROGRAM
//            #pragma vertex vert
//            #pragma fragment frag
//            #include "UnityCG.cginc"
//
//					
//			uniform	fixed _DepthFactor;
//			
//			uniform half _Amount;
//			
//			
//			uniform sampler2D _MainTex;
//			uniform half4 _MainTex_ST;
//			
//			uniform fixed4 _TintColor;
//			
//				uniform sampler2D _DepthTexture;
//			uniform half4 _DepthTexture_ST;
//		
//			float _SineAmplitude;
//			float4 _SineFrequency;
//			float4 _Speed;
//			float4 _Steepness;
//			float4 _Dir;
//			float4 _Dir2;
//			float _Smoothing;
//			uniform float3 _ObjectScale; 
//			uniform float _TimeCostum;
//			
//            struct appdata_t {
//                float4 vertex : POSITION;
//                fixed4 color : COLOR;
//                float4 texcoord : TEXCOORD0;
//                float3 normal : NORMAL;
//            };
// 
//            struct v2f {
//                float4 vertex : SV_POSITION;
//              	half4 tex : TEXCOORD0;
//                float4 projPos : TEXCOORD1;
//                float4 posWorld: TEXCOORD2;
//            };
//           
// 
//            v2f vert (appdata_t v)
//            {
//         
// 				
//
//            	v2f o;	
//            			o.posWorld = mul(_Object2World, v.vertex);
//						o.vertex = mul(UNITY_MATRIX_MVP, v.vertex);
//						float2 dir = _Dir.xy;
//						dir = normalize(dir);
//						float dotprod = dot(dir, o.posWorld.xz);
//						float disp = _TimeCostum * _Speed.x;
//
//						//do the same for our second wave
//						float2 dir2 = _Dir2.xy;
//						dir2 = normalize(dir2);
//						float dotprod2 = dot(dir2, o.posWorld.xz);
//						float disp2 = _TimeCostum * _Speed.y;										
//										
//						float3 v1 = v.vertex + float3(0.05, 0 , 0);
//						float3 v2 = v.vertex + float3(0.0, 0 , 0.05);
//						
//								
//						v.vertex.x += (_Steepness.x *_SineAmplitude) *_Dir.x * cos(_SineFrequency.x* (dotprod + disp))/_ObjectScale.x;
//						v.vertex.z += (_Steepness.x *_SineAmplitude) *_Dir.y * cos(_SineFrequency.x * (dotprod + disp))/_ObjectScale.z;
//						v.vertex.y += _SineAmplitude * - sin(_SineFrequency.x*dotprod + disp )/_ObjectScale.y;
//						
//						v1.x += (_Steepness.x *_SineAmplitude) *_Dir.x * cos(_SineFrequency.x* (dotprod + disp))/_ObjectScale.x;
//						v1.z += (_Steepness.x *_SineAmplitude) *_Dir.y * cos(_SineFrequency.x * (dotprod + disp))/_ObjectScale.z;
//						v1.y += _SineAmplitude * - sin(_SineFrequency.x*dotprod + disp )/_ObjectScale.y;
//	
//						v2.x += (_Steepness.x *_SineAmplitude) *_Dir.x * cos(_SineFrequency.x* (dotprod + disp))/_ObjectScale.x;
//						v2.z += (_Steepness.x *_SineAmplitude) *_Dir.y * cos(_SineFrequency.x * (dotprod + disp))/_ObjectScale.z;
//						v2.y += _SineAmplitude * - sin(_SineFrequency.x*dotprod + disp )/_ObjectScale.y;
//
//
//						v.vertex.x += (_Steepness.y *_SineAmplitude) * _Dir2.x *cos(_SineFrequency.y * (dotprod2 + disp2))/_ObjectScale.x;
//						v.vertex.z += (_Steepness.y *_SineAmplitude) *_Dir2.y*  cos (_SineFrequency.y * (dotprod2 + disp2))/_ObjectScale.z;
//						v.vertex.y += _SineAmplitude * sin(_SineFrequency.y * (dotprod2 + disp2)) /_ObjectScale.y;
//						
//						v1.x += (_Steepness.y *_SineAmplitude) * _Dir2.x *cos(_SineFrequency.y * (dotprod2 + disp2))/_ObjectScale.x;
//						v1.z += (_Steepness.y *_SineAmplitude) *_Dir2.y*  cos (_SineFrequency.y * (dotprod2 + disp2))/_ObjectScale.z;
//						v1.y += _SineAmplitude * sin(_SineFrequency.y * (dotprod2 + disp2)) /_ObjectScale.y;
//						
//						
//						v2.x += (_Steepness.y *_SineAmplitude) * _Dir2.x *cos(_SineFrequency.y * (dotprod2 + disp2))/_ObjectScale.x;
//						v2.z += (_Steepness.y *_SineAmplitude) *_Dir2.y*  cos (_SineFrequency.y * (dotprod2 + disp2))/_ObjectScale.z;
//						v2.y += _SineAmplitude * sin(_SineFrequency.y * (dotprod2 + disp2)) /_ObjectScale.y;
//						
//						v1.y -= (v1.y - v.vertex.y) * _Smoothing;
//						v2.y -= (v2.y - v.vertex.y) * _Smoothing;
//						
//						v1.z -= (v1.z - v.vertex.z) * _Smoothing;
//						v2.z -= (v2.z - v.vertex.z) * _Smoothing;
//						
//						v1.x -= (v1.x - v.vertex.x) * _Smoothing;
//						v2.x -= (v2.x - v.vertex.x) * _Smoothing;
//						
////						float3 vna = cross(v2 - v.vertex, v1 - v.vertex);
//						
//						//float vn = mul(_World2Object, float4(vna,0.0));
//						
//						
// 				o.tex = v.texcoord;
//            	
//				o.projPos = ComputeScreenPos (o.vertex);
//				COMPUTE_EYEDEPTH(o.projPos.z);
//
//                return o;
//            }
// 			
//            sampler2D_float _CameraDepthTexture;
//           
//            fixed4 frag (v2f i) : COLOR
//            {
//           // _DepthTexture
//               half4 texDepth = tex2D( _DepthTexture, i.tex.xy * _DepthTexture_ST.xy + _DepthTexture_ST.zw);
//      
//            half4 texB = tex2D( _MainTex, i.tex.xy * _MainTex_ST.xy + _MainTex_ST.zw);
//            
//            float sceneZ = LinearEyeDepth (SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture,UNITY_PROJ_COORD(i.projPos)));
//			float partZ = i.projPos.z;
//			float fade = saturate (_DepthFactor / (sceneZ-partZ));
//			texDepth.a -= saturate(abs(1 - fade));
//		
//  			//texwave.a += saturate(abs(1 - fade));
//             
//             return texDepth;
//            }
//            ENDCG
//        }
   }  
 Fallback "Transparent/Cutout/VertexLit"
    }