// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Eugene/Enviroment/Sky/ProceduralUpgrade" {
Properties {
    _HdrExposure("HDR Exposure", Float) = 1.3
    _GroundColor ("Ground", Color) = (.369, .349, .341, 1)
    _RL("Rayleigh", Float) = 0.0025
    _MIE ("MIE", Float) = 0.0010
    _SUN("Sun brightness", Float) = 20.0
	_NoiseTex("Noise Texture", 2D) = "white"{}
	_FallOffTex01("FallOff Texture 01", 2D) = "white"{}
	_CloudCoverage("Cloud Density", Range(-1,1)) = 0
}
 
SubShader {
    Tags { "Queue"="Background" "RenderType"="Background" "PreviewType"="Skybox" }
    Cull Off ZWrite Off
 
    Pass {
       
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
 
        #include "UnityCG.cginc"
        #include "Lighting.cginc"
 		uniform half gTime;
		uniform half _SUN;
        uniform half _HdrExposure,_RL,_MIE;        // HDR exposure
        uniform half3 _GroundColor;

        // RGB wavelengths
        #define WR 0.65
        #define WG 0.57
        #define WB 0.475
        static const half3 kInvWavelength = half3(1.0 / (WR*WR*WR*WR), 1.0 / (WG*WG*WG*WG), 1.0 / (WB*WB*WB*WB));
        #define OUTER_RADIUS 1.025
        static const half kOuterRadius = OUTER_RADIUS;
        static const half kOuterRadius2 = OUTER_RADIUS*OUTER_RADIUS;
        static const half kInnerRadius = 1.0;
        static const half kInnerRadius2 = 1.0;
 
        static const half kCameraHeight = 0.0001;
 
        //#define kRAYLEIGH 0.0025        // Rayleigh constant
        //#define kMIE 0.0010              // Mie constant
        //#define kSUN_BRIGHTNESS 20.0     // Sun brightness
        #define kRAYLEIGH _RL        // Rayleigh constant
        #define kMIE _MIE             // Mie constant
        #define kSUN_BRIGHTNESS _SUN     // Sun brightness
 
        static const half kKrESun = kRAYLEIGH * kSUN_BRIGHTNESS;
        static const half kKmESun = kMIE * kSUN_BRIGHTNESS;
        static const half kKr4PI = kRAYLEIGH * 4.0 * 3.14159265;
        static const half kKm4PI = kMIE * 4.0 * 3.14159265;
        static const half kScale = 1.0 / (OUTER_RADIUS - 1.0);
        static const half kScaleDepth = 0.25;
        static const half kScaleOverScaleDepth = (1.0 / (OUTER_RADIUS - 1.0)) / 0.25;
        static const half kSamples = 2.0; // THIS IS UNROLLED MANUALLY, DON'T TOUCH
 
        #define MIE_G (-0.990)
        #define MIE_G2 0.9801
 
		
			#define CLOUD_LOWER 1000.0
			#define CLOUD_UPPER 4000.0

			#define TEXTURE_NOISE
			#define REAL_SHADOW

			#define FLATTEN .2
			#define NUM_STEPS 70

			#define MOD2 half2(.16632, .17369)
			#define MOD3 half3(.16532, .17369, .15787)

			uniform half4 _BackColor;
			uniform half cloudy;
			uniform half _CloudCoverage;
			//uniform half3 _MousePos;
			uniform half2 _iResolution;
			half3 flash;

			sampler2D _NoiseTex;
			half4 _MainTex_ST;
			sampler2D _FallOffTex01;
			half4 _FallOffTex01_ST;

        struct appdata_t {
            half4 vertex : POSITION;
        };
 
        struct v2f {
                half4 pos : SV_POSITION;
                half3 rayDir : TEXCOORD0;    // Vector for incoming ray, normalized ( == -eyeRay )
                half3 cIn : TEXCOORD1;         // In-scatter coefficient
                half3 cOut : TEXCOORD2;        // Out-scatter coefficient
				half3 viewDir : TEXCOORD3;
           };
		
			//============================================
			half Hash(half p)
			{
				half2 p2 = frac(half2(p, p) * MOD2);
				p2 += dot(p2.yx, p2.xy + 19.19);
				return frac(p2.x * p2.y);
			}
			half Hash(half3 p)
			{
				p = frac(p * MOD3);
				p += dot(p.xyz, p.yzx + 19.19);
				return frac(p.x * p.y * p.z);
			}
			//============================================
			#ifdef TEXTURE_NOISE
			//============================================
			half Noise(in half2 f)
			{
				half2 p = floor(f);
				f = frac(f);
				f = f * f * (3.0 - 2.0 * f);
				half3 coord =  half3(( p + f + .5) / 256.0, 0.0) + _Time.x / 100;

				half res = tex2Dlod(_NoiseTex, half4(coord, 0.0)).x;
				return res;//clamp(res - falloff, 0, 1);
			}

			half Noise(in half3 x)
			{
				half3 p = floor(x);
				half3 f = frac(x);
				f = f * f * (3.0 - 2.0 * f);

				half2 uv = (p.xy + half2(37.0, 17.0) * p.z) + f.xy;
				half3 coord =  half3((uv + 0.5) / 256.0, 0.0) + _Time.x / 100;
				half2 rg = tex2Dlod(_NoiseTex, half4(coord, 0.0)).yx;
				return lerp(rg.x, rg.y, f.z);//clamp(lerp(rg.x, rg.y, f.z) - (falloff.xy), 0, 1);
			}
			#else
			//============================================
			//============================================
			half Noise(in half2 x)
			{
				half2 p = floor(x);
				half2 f = frac(x);
				f = f * f * (3.0 - 2.0 * f);
				half n = p.x + p.y * 57.0;
				
				half3 res = lerp(lerp( Hash (n + 0.0), Hash(n+ 1.0), f.x),
								 lerp( Hash (n + 57.0), Hash(n+ 58.0), f.x), f.y);
				return res;
			}
			half Noise(in half3 p)
			{
				half3 i = floor(p);
				half3 f = frac(p);
				f *= f * (3.0 - 2.0 * f);

				return lerp(
					lerp(lerp(Hash(i + half3(0.0,0.0,0.0)), Hash(i + half3(1.0, 0.0, 0.0)), f.x),
						 lerp(Hash(i + half3(0.0,1.0,0.0)), Hash(i + half3(1.0, 1.0, 0.0)), f.x),
						 f.y),
					lerp(lerp(Hash(i + half3(0.0,0.0,1.0)), Hash(i + half3(1.0, 0.0, 1.0)), f.x),
						 lerp(Hash(i + half3(0.0,1.0,1.0)), Hash(i + half3(1.0, 1.0, 1.0)), f.x),
						 f.y),
						 f.z);
			}
			#endif
			//============================================
			//============================================
			half FBM(half3 p)
			{
				p *= .25;
				half f;

				f = 0.5000 * Noise(p); p = p * 3.02; 
				f += 0.2500 * Noise(p); p = p * 3.03;	p+= _Time.x*1.0;
				f += 0.1250 * Noise(p); p = p * 3.01;	p+= _Time.x*0.25;
				f += 0.0625 * Noise(p); p = p * 3.03;	p-= _Time.x*0.125;
				f += 0.03125 * Noise(p); p = p * 3.02;  p-= _Time.x*0.0125;
				f += 0.015625 * Noise(p);

				return f;
			}
			//============================================
			//============================================
			//============================================
			//============================================
			half Map(half3 p)
			{
				p *= 0.002;
				half h = FBM(p);
				return h - cloudy - 0.5;
			}
			//============================================
			//============================================
			//============================================
			//============================================
			//============================================
			//============================================
			#ifdef REAL_SHADOW
			//Real Shadow...
			half Shadow(half3 pos, half3 rd)
			{
				pos += rd * 400.0;
				half s = 0.0;

				for(int i = 0; i < 5; i++)
				{
					s+= max(Map(pos), 0.0) * 5.0;
					//s = clamp(s, 0.0, 1.0);
					pos += rd * 400.0;
				}

				return clamp(s, 0.1, 1.0);
			}
			#endif
			//============================================
			//============================================
			half3 GetSky(in half3 pos, in half3 rd)
			{

				half sunAmount = max(dot(rd, _WorldSpaceLightPos0) , 0.0);
				// Do the Blue and sun..
				half3 sky = lerp(half3(0.0, 0.1, 0.4), half3(0.3, 0.6, 0.8), 1.0 - rd.y);
				sky = sky + _LightColor0 * min(pow(sunAmount, 1500.0) * 5.0, 1.0);
				sky = sky + _LightColor0 * min(pow(sunAmount, 10.0) * 0.6, 1.0);

				//Find the start and end of the cloud layer
				half beg = ((CLOUD_LOWER - pos.y) / rd.y);
				half end = ((CLOUD_UPPER - pos.y) / rd.y);

				// Start Position
				half3 p = half3(pos.x + rd.x * beg, 0.0, pos.z + rd.z * beg);
				//outPos = p.xz;
				beg += Hash(p) * 150.0;

				//Trace clouds through that layer
				half d = 0.0;
				half3 add = rd * ((end - beg) / 45.0);
				half2 shade;
				half2 shadeSum = half2(0.0, 0.0);
				half diffrence = CLOUD_UPPER - CLOUD_LOWER;
				shade.x = .01;
				//I think this is as small as the loop can be
				// for a reasonable cloud density illusion.
				for(int i = 0; i < 55; i++)
				{
					if(shadeSum.y >= 1.35) break;
					half h = Map(p);
					shade.y = max(-h,0.0);
				#ifdef REAL_SHADOW
				shade.x = Shadow(p, _WorldSpaceLightPos0);
				#else
				//shade.x = clamp(1.0 * (-Map(p - _WorldSpaceLightPos0 * 0.0) - Map(p))
									// / 0.01, 0.0, 1.0) * p.y / diffrence;
				shade.x = p.y / diffrence;
				#endif
				shadeSum += shade * (1.0 - shadeSum.y);

				p += add;
				}

				shadeSum.x /= 10.0;
				shadeSum = min(shadeSum, 1.0);

				half shadePow = pow(shadeSum.x, .4);
				half3 clouds = lerp(half3(shadePow, shadePow ,shadePow), _LightColor0, (1.0-shadeSum.y)*.4);
	
				clouds += min((1.0 - sqrt(shadeSum.y)) * pow(sunAmount, 4.0), 1.0) * 2.0;
   
				clouds += flash * (shadeSum.y+shadeSum.x+.2) * .5;

				sky = lerp(sky, min(clouds, 1.0), shadeSum.y);

				return clamp(sky, 0.0, 1.0);
			}

			half3 CameraPath( half t )
			{
			    return half3(4000.0 * sin(.16*t)+12290.0, 0.0, 8800.0 * cos(.145*t+.3));
			} 


        half scale(half inCos)
        {
            half x = 1.0 - inCos;
            return 0.25 * exp(-0.00287 + x*(0.459 + x*(3.83 + x*(-6.80 + x*5.25))));
        }
 
        v2f vert (appdata_t v)
        {
            v2f OUT;
            OUT.pos = UnityObjectToClipPos(v.vertex);
            half3 cameraPos = half3(0,kInnerRadius + kCameraHeight,0);     // The camera's current position
       
            // Get the ray from the camera to the vertex and its length (which is the far point of the ray passing through the atmosphere)
            half3 eyeRay = normalize(mul((half3x3)unity_ObjectToWorld, v.vertex.xyz));
 
            OUT.rayDir = half3(-eyeRay);
 
            half far = 0.0;
            if(eyeRay.y >= 0.0)
            {
                // Sky
                // Calculate the length of the "atmosphere"
                far = sqrt(kOuterRadius2 + kInnerRadius2 * eyeRay.y * eyeRay.y - kInnerRadius2) - kInnerRadius * eyeRay.y;
 
                half3 pos = cameraPos + far * eyeRay;
				OUT.viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.vertex.xyz));

                // Calculate the ray's starting position, then calculate its scattering offset
                half height = kInnerRadius + kCameraHeight;
                half depth = exp(kScaleOverScaleDepth * (-kCameraHeight));
                half startAngle = dot(eyeRay, cameraPos) / height;
                half startOffset = depth*scale(startAngle);
               
           
                // Initialize the scattering loop variables
                half sampleLength = far / kSamples;
                half scaledLength = sampleLength * kScale;
                half3 sampleRay = eyeRay * sampleLength;
                half3 samplePoint = cameraPos + sampleRay * 0.5;
 
                // Now loop through the sample rays
                half3 frontColor = half3(0.0, 0.0, 0.0);
                // WTF BBQ: WP8 and desktop FL_9_1 do not like the for loop here
                // (but an almost identical loop is perfectly fine in the ground calculations below)
                // Just unrolling this manually seems to make everything fine again.
//                for(int i=0; i<int(kSamples); i++)
                {
                    half height = length(samplePoint);
                    half depth = exp(kScaleOverScaleDepth * (kInnerRadius - height));
                    half lightAngle = dot(_WorldSpaceLightPos0.xyz, samplePoint) / height;
                    half cameraAngle = dot(eyeRay, samplePoint) / height;
                    half scatter = (startOffset + depth*(scale(lightAngle) - scale(cameraAngle)));
                    half3 attenuate = exp(-scatter * (kInvWavelength * kKr4PI + kKm4PI));
 
                    frontColor += attenuate * (depth * scaledLength);
                    samplePoint += sampleRay;
                }
                {
                    half height = length(samplePoint);
                    half depth = exp(kScaleOverScaleDepth * (kInnerRadius - height));
                    half lightAngle = dot(_WorldSpaceLightPos0.xyz, samplePoint) / height;
                    half cameraAngle = dot(eyeRay, samplePoint) / height;
                    half scatter = (startOffset + depth*(scale(lightAngle) - scale(cameraAngle)));
                    half3 attenuate = exp(-scatter * (kInvWavelength * kKr4PI + kKm4PI));
 
                    frontColor += attenuate * (depth * scaledLength);
                    samplePoint += sampleRay;
                }
 
 
 
                // Finally, scale the Mie and Rayleigh colors and set up the varying variables for the pixel shader
                OUT.cIn.xyz = frontColor * (kInvWavelength * kKrESun);
                OUT.cOut = frontColor * kKmESun;
            }
            else
            {
                // Ground
                far = (-kCameraHeight) / (min(-0.00001, eyeRay.y));
 
                half3 pos = cameraPos + far * eyeRay;
 
                // Calculate the ray's starting position, then calculate its scattering offset
                half depth = exp((-kCameraHeight) * (1.0/kScaleDepth));
                half cameraAngle = dot(-eyeRay, pos);
                half lightAngle = dot(_WorldSpaceLightPos0.xyz, pos);
                half cameraScale = scale(cameraAngle);
                half lightScale = scale(lightAngle);
                half cameraOffset = depth*cameraScale;
                half temp = (lightScale + cameraScale);
               
                // Initialize the scattering loop variables
                half sampleLength = far / kSamples;
                half scaledLength = sampleLength * kScale;
                half3 sampleRay = eyeRay * sampleLength;
                half3 samplePoint = cameraPos + sampleRay * 0.5;
               
                // Now loop through the sample rays
                half3 frontColor = half3(0.0, 0.0, 0.0);
                half3 attenuate;

                for(int i=0; i<int(kSamples); i++)
                {
                    half height = length(samplePoint);
                    half depth = exp(kScaleOverScaleDepth * (kInnerRadius - height));
                    half scatter = depth*temp - cameraOffset;
                    attenuate = exp(-scatter * (kInvWavelength * kKr4PI + kKm4PI));
                    frontColor += attenuate * (depth * scaledLength);
                    samplePoint += sampleRay;
                }
           
                OUT.cIn.xyz = frontColor * (kInvWavelength * kKrESun + kKmESun);
                OUT.cOut.xyz = clamp(attenuate, 0.0, 1.0);
            }
 
 
            return OUT;
 
        }
 
 
        // Calculates the Mie phase function
        half getMiePhase(half eyeCos, half eyeCos2)
        {
            half temp = 1.0 + MIE_G2 - 2.0 * MIE_G * eyeCos;
            // A somewhat rough approx for :
            // temp = pow(temp, 1.5);
            temp = smoothstep(0.0, 0.01, temp) * temp;
            temp = max(temp,1.0e-4); // prevent division by zero, esp. in half precision
            return 1.5 * ((1.0 - MIE_G2) / (2.0 + MIE_G2)) * (1.0 + eyeCos2) / temp;
        }
 
        // Calculates the Rayleigh phase function
        half getRayleighPhase(half eyeCos2)
        {
            return 0.75 + 0.75*eyeCos2;
        }
		

		half3 blend(half3 A, half3 B)
		{
			half3 C;
			C.rgb = (A.r * A.rgb + (1 - A.r) * B.r * B.rgb);
			return C;
		}


        half4 frag (v2f IN) : SV_Target
        {
			half3 col;
			half3 clouds;
			half3 light;
			half3 finalCol;

			half m = (_Time.y);
			gTime = _Time.y * 0.5 + m + 75.5;
			cloudy = _CloudCoverage;
			half2 xy = IN.pos / _ScreenParams.xy;
			half lightning = 0.0;

			if(cloudy >= 0.2)
			{
				half f = fmod(_Time.x + 1.5, 2.5);

				if(f < .8)
				{
					f = smoothstep(0.8, 0.0, f) * 1.5;
					lightning = fmod(-gTime * (1.5 - Hash(gTime * 0.3) * 0.002), 1.0) *	f;

				}

			}

			flash = clamp (half3(1.0, 1.0, 1.2) * lightning, 0.0, 1.0);
		
			if(IN.rayDir.y < 0.1)
            {
                half eyeCos = dot(_WorldSpaceLightPos0.xyz, normalize(float3(IN.rayDir.x, IN.rayDir.y, IN.rayDir.z)));
                half eyeCos2 = eyeCos * eyeCos;
			  	
			
                col = getRayleighPhase(eyeCos2) * IN.cIn.xyz + getMiePhase(eyeCos, eyeCos2) * _LightColor0 * IN.cOut;
				clouds = pow(GetSky(_WorldSpaceCameraPos, IN.rayDir), 4) + col;

				finalCol =  col;
		
		
            }
            else
            {
                col = IN.cIn.xyz + _GroundColor * IN.cOut;
				clouds = IN.cIn.xyz + _GroundColor * IN.cOut;
				finalCol = col * clouds;
            }
            //Adjust color from HDR

			finalCol *= _HdrExposure;

			//finalCol *= .55+0.45*pow(70.0 * xy.x * xy.y * (1.0 - xy.x ) * (1.0 - xy.y), 0.15 );
            return half4(finalCol,1.0);
 
        }
        ENDCG
    }
}    
 
 
Fallback Off
 
}