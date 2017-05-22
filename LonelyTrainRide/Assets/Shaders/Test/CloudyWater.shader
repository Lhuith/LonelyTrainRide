Shader "Unlit/CloudyWater"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_NoiseTex("Noise Texture", 2D)  = "white" {}
		_X("X Rotation", Float) = 1.0
		_XDir("X Direction", Float) = 1.0
		_Y("Y Rotation", Float) = 1.0
		_Z("Z Rotation", Float) = 1.0
	}
	SubShader
	{
			Tags{ "LightMode" = "ForwardBase"}
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			

			/*
 * This are predefined settings you can quickly use
 *    - D_DEMO_FREE play with parameters as you would like
 *    - D_DEMO_SHOW_IMPROVEMENT_FLAT show improved integration on flat surface
 *    - D_DEMO_SHOW_IMPROVEMENT_NOISE show improved integration on noisy surface
 *    - the two previous without volumetric shadows
 */
#define D_DEMO_FREE
//#define D_DEMO_SHOW_IMPROVEMENT_FLAT
#define D_DEMO_SHOW_IMPROVEMENT_NOISE
#define D_DEMO_SHOW_IMPROVEMENT_FLAT_NOVOLUMETRICSHADOW
#define D_DEMO_SHOW_IMPROVEMENT_NOISE_NOVOLUMETRICSHADOW

#ifdef D_DEMO_FREE
	// Apply noise on top of the height fog?
    #define D_FOG_NOISE 1.0

	// Height fog multiplier to show off improvement with new integration formula
    #define D_STRONG_FOG 0.0

    // Enable/disable volumetric shadow (single scattering shadow)
    #define D_VOLUME_SHADOW_ENABLE 1

	// Use imporved scattering?
	// In this mode it is full screen and can be toggle on/off.
	#define D_USE_IMPROVE_INTEGRATION 1

//
// Pre defined setup to show benefit of the new integration. Use D_DEMO_FREE to play with parameters
//
#elif defined(D_DEMO_SHOW_IMPROVEMENT_FLAT)
    #define D_STRONG_FOG 10.0
    #define D_FOG_NOISE 0.0
	#define D_VOLUME_SHADOW_ENABLE 1
#elif defined(D_DEMO_SHOW_IMPROVEMENT_NOISE)
    #define D_STRONG_FOG 5.0
    #define D_FOG_NOISE 1.0
	#define D_VOLUME_SHADOW_ENABLE 1
#elif defined(D_DEMO_SHOW_IMPROVEMENT_FLAT_NOVOLUMETRICSHADOW)
    #define D_STRONG_FOG 10.0
    #define D_FOG_NOISE 0.0
	#define D_VOLUME_SHADOW_ENABLE 0
#elif defined(D_DEMO_SHOW_IMPROVEMENT_NOISE_NOVOLUMETRICSHADOW)
    #define D_STRONG_FOG 3.0
    #define D_FOG_NOISE 1.0
	#define D_VOLUME_SHADOW_ENABLE 1
#endif



/*
 * Other options you can tweak
 */

// Used to control wether transmittance is updated before or after scattering (when not using improved integration)
// If 0 strongly scattering participating media will not be energy conservative
// If 1 participating media will look too dark especially for strong extinction (as compared to what it should be)
// Toggle only visible zhen not using the improved scattering integration.
#define D_UPDATE_TRANS_FIRST 1

// Use to restrict ray marching length. Needed for volumetric evaluation.
#define D_MAX_STEP_LENGTH_ENABLE 1

// Light position and color
#define LPOS float3( 20 + _X, 8 + _Y, -20 + _Z)
#define LCOL (200.0*float3( 1.0, 0.9, 0.5))


			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float4 wPos : TEXCOORD1;
				float4 fragPos : TEXCOORD2;
				float3 normal : TEXCOORD3;
				float4 tangent : TEXCOORD5;
				float3 normalDir  : TEXCOORD6;
				float4 tangentDir : TEXCOORD7;
				float4 col : COLOR;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			sampler2D _NoiseTex;
			float4 _NoiseTex_ST;

			float4x4 unity_WorldToLight;
			//float4 _LightPositionRange;
			float4 _LightColor0;

			uniform float _X;
			uniform float _XDir;
			uniform float _Y;
			uniform float _Z;

float displacementSimple( float2 p )
{
    float f;
    f  = 0.5000* tex2Dlod( _NoiseTex, float4( p, 0.0, 0.0) ).x; p = p*2.0;
    f += 0.2500* tex2Dlod( _NoiseTex, float4( p, 0.0, 0.0) ).x; p = p*2.0;
    f += 0.1250* tex2Dlod( _NoiseTex, float4( p, 0.0, 0.0) ).x; p = p*2.0;
    f += 0.0625* tex2Dlod( _NoiseTex, float4( p, 0.0, 0.0) ).x; p = p*2.0;
    
    return f;
}

float3 evaluateLight(in float3 pos, float3 lightDir)
{
    float3 lightPos = lightDir.xyz;
    float3 lightCol = LCOL;
    float3 L = lightPos-pos;
    float distanceToL = length(L);
    return lightCol * 1.0/(distanceToL*distanceToL);
}

float3 evaluateLight(in float3 pos, in float3 normal, float3 lightDir)
{
    float3 lightPos = lightDir.xyz;
    float3 L = lightPos-pos;
    float distanceToL = length(L);
    float3 Lnorm = L/distanceToL;
    return max(0.0,dot(normal,Lnorm)) * evaluateLight(pos, lightDir);
}

// To simplify: wavelength independent scattering and extinction
void getParticipatingMedia(out float muS, out float muE, in float3 pos)
{
    float heightFog = 7.0 + D_FOG_NOISE * 2.0 * clamp(displacementSimple(pos.xz * 0.5 + _Time.y * 0.02), 0.0, 1.0);

    heightFog = 0.5 * clamp((heightFog - pos.y) * 1.0, 0.0, 1.0);
    
    const float fogFactor = 1.0 + D_STRONG_FOG * 1.0;
    
    const float sphereRadius = 5.0;

    float sphereFog = clamp((sphereRadius-length(pos-float3(20.0,19.0,-17.0)))/sphereRadius, 0.0,1.0);
    
    const float constantFog = 0.01;

    muS = constantFog + heightFog*fogFactor;
   
    const float muA = 0.0;
    muE = max(0.000000001, muA + muS); // to avoid division by zero extinction
}

float phaseFunction()
{
    return 1.0/(4.0*3.14);
}

float volumetricShadow(in float3 from, in float3 to)
{
#if D_VOLUME_SHADOW_ENABLE
    const float numStep = 16.0; // quality control. Bump to avoid shadow alisaing
    float shadow = 1.0;
    float muS = 0.0;
    float muE = 0.0;
    float dd = length(to-from) / numStep;
    for(float s=0.5; s<(numStep-0.1); s+=1.0)// start at 0.5 to sample at center of integral part
    {
        float3 pos = from + (to-from)*(s/(numStep));
        getParticipatingMedia(muS, muE, pos);
        shadow *= exp(-muE * dd);
    }
    return shadow;
#else
    return 1.0;
#endif
}

void traceScene(bool improvedScattering, float3 rO, float3 rD, inout float3 finalPos, 
					inout float3 normal, inout float4 scatTrans, float3 lightDir)
{
	const int numIter = 300;
	
    float muS = 0.0;
    float muE = 0.0;
    
    float3 lightPos = lightDir;
    
    // Initialise volumetric scattering integration (to view)
    float transmittance = 1.0;
    float3 scatteredLight = float3(0.0, 0.0, 0.0);
    
	float d = 0; // hack: always have a first step of 1 unit to go further
	float3 p = float3(0.0, 0.0, 0.0);
    float dd = 0.0;

	for(int i=0; i<numIter;++i)
	{
		float3 p = (rO + d * rD) ;
        
        
    	getParticipatingMedia(muS, muE, p);
        
#ifdef D_DEMO_FREE
        if(D_USE_IMPROVE_INTEGRATION>0) // freedom/tweakable version
#else
        if(improvedScattering)
#endif
        {
            // See slide 28 at http://www.frostbite.com/2015/08/physically-based-unified-volumetric-rendering-in-frostbite/
            float3 S = evaluateLight(p, lightDir) * muS * phaseFunction()* volumetricShadow(p,lightPos);// incoming light
            float3 Sint = (S - S * exp(-muE * dd)) / muE; // integrate along the current step segment
            scatteredLight += transmittance * Sint; // accumulate and also take into account the transmittance from previous steps

            // Evaluate transmittance to view independentely
            transmittance *= exp(-muE * dd);
        }
		else
        {
            // Basic scatering/transmittance integration
        #if D_UPDATE_TRANS_FIRST
            transmittance *= exp(-muE * dd);
        #endif
            scatteredLight += muS * evaluateLight(p, lightDir) * phaseFunction() * volumetricShadow(p,lightPos) * transmittance * dd;
        #if !D_UPDATE_TRANS_FIRST
            transmittance *= exp(-muE * dd);
        #endif
        }
        
		
        dd = 2;
        if(dd<0.1)
            break; // give back a lot of performance without too much visual loss
		d += dd;
	}
    
    scatTrans = float4(scatteredLight, transmittance);
}
			v2f vert (appdata_full v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;
				o.wPos = mul(unity_ObjectToWorld, v.vertex);
				o.fragPos = v.vertex;
				o.normal = v.normal;
				o.tangent = v.tangent;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{

		   float3 normalDirection =	normalize( mul(float4(i.normal, 0.0), unity_WorldToObject).xyz);
		   float3 viewDirection = normalize(float3(float4(_WorldSpaceCameraPos.xyz, 1.0) - mul(unity_ObjectToWorld,i.wPos).xyz));
		   float3 lightDirection;
		   float atten = 1.0;
		   
		   //lighting
		   lightDirection = normalize(_WorldSpaceLightPos0.xyz);
		   float3 diffuseReflection = atten * _LightColor0.xyz * max(0.0, dot(normalDirection, lightDirection));
		   float3 specularReflection =atten * max(0.0, dot(normalDirection, lightDirection)) * pow(max(0.0, dot(reflect( -lightDirection, normalDirection), viewDirection)), 300);
		   float3 lightFinal = diffuseReflection + specularReflection;
		   
		    float4 col = float4(specularReflection,1.0);


			  //_Time.x
		    //iMouse
		    //_ScreenParams
		    
			float2 uv = i.uv;
			float2 uv2 = 2 * i.uv.xy - 1.0; 
						float3 nSpec =   lightDirection = normalize(mul(unity_LightPosition[0],UNITY_MATRIX_IT_MV).xyz);

			float3 camPos = float3( 1.0, 1.0,-150.0);

			float3 camX   = float3  (1, 0.0, 0.0) * 1.75;
			float3 camY   = float3( 0.0, 1, 0.0) * 0.5;
			float3 camZ   = float3( 0.0, 0.0, 1) ;
				
						
			float3 rO = camPos;

			float3 rD = nSpec;//normalize(uv2.x * camX + uv2.y * camY + camZ);
			
			float3 finalPos = float3(0,0,0);
			float3 normal = float3( 0.0, 0.0, 0.0 );
		    float4 scatTrans = float4( 0.0, 0.0, 0.0, 0.0 );
			
			float3 nDotl = dot(normalDirection, lightDirection);

		    traceScene( i.uv.y>(_ScreenParams.y), rO, rD, finalPos, normalDirection, scatTrans, nSpec);
			
		    //lighting
		    float3 color = evaluateLight(finalPos, i.normal, nSpec ) * volumetricShadow(finalPos,nSpec);
		    // Apply scattering/transmittance
		    color = color * scatTrans.w + scatTrans.xyz;
		    
		    // Gamma correction
			color = pow(color, float3(1.0/2.2,1.0/2.2,1.0/2.2)); // simple linear to gamma, exposure of 1.0
		    
				//color
			return float4(color, 1.0);
			}
			ENDCG
		}
	}
}
