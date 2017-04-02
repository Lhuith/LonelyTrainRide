// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Skybox/ProceduralUpgrade" {
Properties {
    _HdrExposure("HDR Exposure", Float) = 1.3
    _GroundColor ("Ground", Color) = (.369, .349, .341, 1)
    _RL("Rayleigh", Float) = 0.0025
    _MIE ("MIE", Float) = 0.0010
    _SUN("Sun brightness", Float) = 20.0
	_NoiseTex("Noise Texture", 2D) = "white"{}
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
 		uniform float gTime;
		uniform half _SUN;
        uniform half _HdrExposure,_RL,_MIE;        // HDR exposure
        uniform half3 _GroundColor;

        // RGB wavelengths
        #define WR 0.65
        #define WG 0.57
        #define WB 0.475
        static const float3 kInvWavelength = float3(1.0 / (WR*WR*WR*WR), 1.0 / (WG*WG*WG*WG), 1.0 / (WB*WB*WB*WB));
        #define OUTER_RADIUS 1.025
        static const float kOuterRadius = OUTER_RADIUS;
        static const float kOuterRadius2 = OUTER_RADIUS*OUTER_RADIUS;
        static const float kInnerRadius = 1.0;
        static const float kInnerRadius2 = 1.0;
 
        static const float kCameraHeight = 0.0001;
 
        //#define kRAYLEIGH 0.0025        // Rayleigh constant
        //#define kMIE 0.0010              // Mie constant
        //#define kSUN_BRIGHTNESS 20.0     // Sun brightness
        #define kRAYLEIGH _RL        // Rayleigh constant
        #define kMIE _MIE             // Mie constant
        #define kSUN_BRIGHTNESS _SUN     // Sun brightness
 
        static const float kKrESun = kRAYLEIGH * kSUN_BRIGHTNESS;
        static const float kKmESun = kMIE * kSUN_BRIGHTNESS;
        static const float kKr4PI = kRAYLEIGH * 4.0 * 3.14159265;
        static const float kKm4PI = kMIE * 4.0 * 3.14159265;
        static const float kScale = 1.0 / (OUTER_RADIUS - 1.0);
        static const float kScaleDepth = 0.25;
        static const float kScaleOverScaleDepth = (1.0 / (OUTER_RADIUS - 1.0)) / 0.25;
        static const float kSamples = 2.0; // THIS IS UNROLLED MANUALLY, DON'T TOUCH
 
        #define MIE_G (-0.990)
        #define MIE_G2 0.9801
 
		
			#define CLOUD_LOWER 2000.0
			#define CLOUD_UPPER 3800.0

			#define TEXTURE_NOISE
			#define REAL_SHADOW

			#define FLATTEN .2
			#define NUM_STEPS 70

			#define MOD2 float2(.16632, .17369)
			#define MOD3 float3(.16532, .17369, .15787)

			uniform float4 _BackColor;
			uniform float cloudy;
		
			//uniform float3 _MousePos;
			uniform float2 _iResolution;
			float3 flash;

			sampler2D _NoiseTex;
			float4 _MainTex_ST;

        struct appdata_t {
            float4 vertex : POSITION;
        };
 
        struct v2f {
                float4 pos : SV_POSITION;
                half3 rayDir : TEXCOORD0;    // Vector for incoming ray, normalized ( == -eyeRay )
                half3 cIn : TEXCOORD1;         // In-scatter coefficient
                half3 cOut : TEXCOORD2;        // Out-scatter coefficient
           };
		
			//============================================
			float Hash(float p)
			{
				float2 p2 = frac(float2(p, p) * MOD2);
				p2 += dot(p2.yx, p2.xy + 19.19);
				return frac(p2.x * p2.y);
			}
			float Hash(float3 p)
			{
				p = frac(p * MOD3);
				p += dot(p.xyz, p.yzx + 19.19);
				return frac(p.x * p.y * p.z);
			}
			//============================================
			#ifdef TEXTURE_NOISE
			//============================================
			float Noise(in float2 f)
			{
				float2 p = floor(f);
				f = frac(f);
				f = f * f * (3.0 - 2.0 * f);
				float3 coord =  float3(( p + f + .5) / 256.0, 0.0);
				float res = tex2Dlod(_NoiseTex, float4(coord, 0.0)).x;
				return res;
			}

			float Noise(in float3 x)
			{
				float3 p = floor(x);
				float3 f = frac(x);
				f = f * f * (3.0 - 2.0 * f);

				float2 uv = (p.xy + float2(37.0, 17.0) * p.z) + f.xy;
				float3 coord =  float3((uv + 0.5) / 256.0, 0.0);
				float2 rg = tex2Dlod(_NoiseTex, float4(coord, 0.0)).yx;

				return lerp(rg.x, rg.y, f.z);
			}
			#else
			//============================================
			//============================================
			float Noise(in float2 x)
			{
				float2 p = floor(x);
				float2 f = frac(x);
				f = f * f * (3.0 - 2.0 * f);
				float n = p.x + p.y * 57.0;
				
				float res = lerp(lerp( Hash (n + 0.0), Hash(n+ 1.0), f.x),
								 lerp( Hash (n + 57.0), Hash(n+ 58.0), f.x), f.y);
				return res;
			}
			float Noise(in float3 p)
			{
				float3 i = floor(p);
				float3 f = frac(p);
				f *= f * (3.0 - 2.0 * f);

				return lerp(
					lerp(lerp(Hash(i + float3(0.0,0.0,0.0)), Hash(i + float3(1.0, 0.0, 0.0)), f.x),
						 lerp(Hash(i + float3(0.0,1.0,0.0)), Hash(i + float3(1.0, 1.0, 0.0)), f.x),
						 f.y),
					lerp(lerp(Hash(i + float3(0.0,0.0,1.0)), Hash(i + float3(1.0, 0.0, 1.0)), f.x),
						 lerp(Hash(i + float3(0.0,1.0,1.0)), Hash(i + float3(1.0, 1.0, 1.0)), f.x),
						 f.y),
						 f.z);
			}
			#endif
			//============================================
			//============================================
			float FBM(float3 p)
			{
				p *= .25;
				float f;

				f = 0.5000 * Noise(p); p = p * 3.02; 
				f += 0.2500 * Noise(p); p = p * 3.03;	p+= _Time.y*1.0;
				f += 0.1250 * Noise(p); p = p * 3.01;	p+= _Time.y*0.25;
				f += 0.0625 * Noise(p); p = p * 3.03;	p+= _Time.y*0.125;
				f += 0.03125 * Noise(p); p = p * 3.02; p+= _Time.y*0.0125;
				f += 0.015625 * Noise(p);

				return f;
			}
			//============================================
			//============================================
			//============================================
			//============================================
			float Map(float3 p)
			{
				p *= 0.002;
				float h = FBM(p);
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
			float Shadow(float3 pos, float3 rd)
			{
				pos += rd * 400.0;
				float s = 0.0;

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
			float3 GetSky(in float3 pos, in float3 rd)
			{
				float sunAmount = max(dot(rd, _WorldSpaceLightPos0) , 0.0);
				// Do the Blue and sun..
				float3 sky = lerp(float3(0.0, 0.1, 0.4), float3(0.3, 0.6, 0.8), 1.0 - rd.y);
				sky = sky + _LightColor0 * min(pow(sunAmount, 1500.0) * 5.0, 1.0);
				sky = sky + _LightColor0 * min(pow(sunAmount, 10.0) * 0.6, 1.0);

				//Find the start and end of the cloud layer
				float beg = ((CLOUD_LOWER - pos.y) / rd.y);
				float end = ((CLOUD_UPPER - pos.y) / rd.y);

				// Start Position
				float3 p = float3(pos.x + rd.x * beg, 0.0, pos.z + rd.z * beg);
				//outPos = p.xz;
				beg += Hash(p) * 150.0;

				//Trace clouds through that layer
				float d = 0.0;
				float3 add = rd * ((end - beg) / 45.0);
				float2 shade;
				float2 shadeSum = float2(0.0, 0.0);
				float diffrence = CLOUD_UPPER - CLOUD_LOWER;
				shade.x = .01;
				//I think this is as small as the loop can be
				// for a reasonable cloud density illusion.
				for(int i = 0; i < 20; i++)
				{
					if(shadeSum.y >= 1.0) break;
					float h = Map(p);
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

				float shadePow = pow(shadeSum.x, .4);
				float3 clouds = lerp(float3(shadePow, shadePow ,shadePow), _LightColor0, (1.0-shadeSum.y)*.4);
	
				clouds += min((1.0-sqrt(shadeSum.y)) * pow(sunAmount, 4.0), 1.0) * 2.0;
   
				clouds += flash * (shadeSum.y+shadeSum.x+.2) * .5;

				sky = lerp(sky, min(clouds, 1.0), shadeSum.y);

				return clamp(sky, 0.0, 1.0);
			}

		   float2 RadialCoords(float3 a_coords)
			{
			    float3 a_coords_n = normalize(a_coords);
			    float lon = atan2(a_coords_n.z, a_coords_n.x);
			    float lat = acos(a_coords_n.y);
			    float2 sphereCoords = float2(lon, lat) * (1.0 / 3.14159265359);
			    return float2(sphereCoords.x * 0.5 + 0.5, 1 - sphereCoords.y);
			}
			
			float3 CameraPath( float t )
			{
			    return float3(4000.0 * sin(.16*t)+12290.0, 0.0, 8800.0 * cos(.145*t+.3));
			} 


			float3 IntoSphere(float2 uv)
			{
				float3 dir;
				uv = (-1.0 + 2.0 * uv);
				dir.x = uv.x;
				dir.z = uv.y;
				dir.y = sqrt(1.0 - dir.x * dir.x - dir.z * dir.z) * FLATTEN;
				if(length(dir) >= 1.0) return float3(0.0, .001, .999);
				dir = normalize(dir);

				return dir;
			}

			float2 IntoCartesian(float3 dir)
			{
				float2 uv;
				dir.y /= FLATTEN;
				dir = normalize(dir);
				uv.x = dir.x;
				uv.y = dir.z;
				uv = .5 + (.5 * uv);
				return uv;
			}


        float scale(float inCos)
        {
            float x = 1.0 - inCos;
            return 0.25 * exp(-0.00287 + x*(0.459 + x*(3.83 + x*(-6.80 + x*5.25))));
        }
 
        v2f vert (appdata_t v)
        {
            v2f OUT;
            OUT.pos = mul(UNITY_MATRIX_MVP, v.vertex);
            float3 cameraPos = float3(0,kInnerRadius + kCameraHeight,0);     // The camera's current position
       
            // Get the ray from the camera to the vertex and its length (which is the far point of the ray passing through the atmosphere)
            float3 eyeRay = normalize(mul((float3x3)unity_ObjectToWorld, v.vertex.xyz));
 
            OUT.rayDir = half3(-eyeRay);
 
            float far = 0.0;
            if(eyeRay.y >= 0.0)
            {
                // Sky
                // Calculate the length of the "atmosphere"
                far = sqrt(kOuterRadius2 + kInnerRadius2 * eyeRay.y * eyeRay.y - kInnerRadius2) - kInnerRadius * eyeRay.y;
 
                float3 pos = cameraPos + far * eyeRay;
               
                // Calculate the ray's starting position, then calculate its scattering offset
                float height = kInnerRadius + kCameraHeight;
                float depth = exp(kScaleOverScaleDepth * (-kCameraHeight));
                float startAngle = dot(eyeRay, cameraPos) / height;
                float startOffset = depth*scale(startAngle);
               
           
                // Initialize the scattering loop variables
                float sampleLength = far / kSamples;
                float scaledLength = sampleLength * kScale;
                float3 sampleRay = eyeRay * sampleLength;
                float3 samplePoint = cameraPos + sampleRay * 0.5;
 
                // Now loop through the sample rays
                float3 frontColor = float3(0.0, 0.0, 0.0);
                // WTF BBQ: WP8 and desktop FL_9_1 do not like the for loop here
                // (but an almost identical loop is perfectly fine in the ground calculations below)
                // Just unrolling this manually seems to make everything fine again.
//                for(int i=0; i<int(kSamples); i++)
                {
                    float height = length(samplePoint);
                    float depth = exp(kScaleOverScaleDepth * (kInnerRadius - height));
                    float lightAngle = dot(_WorldSpaceLightPos0.xyz, samplePoint) / height;
                    float cameraAngle = dot(eyeRay, samplePoint) / height;
                    float scatter = (startOffset + depth*(scale(lightAngle) - scale(cameraAngle)));
                    float3 attenuate = exp(-scatter * (kInvWavelength * kKr4PI + kKm4PI));
 
                    frontColor += attenuate * (depth * scaledLength);
                    samplePoint += sampleRay;
                }
                {
                    float height = length(samplePoint);
                    float depth = exp(kScaleOverScaleDepth * (kInnerRadius - height));
                    float lightAngle = dot(_WorldSpaceLightPos0.xyz, samplePoint) / height;
                    float cameraAngle = dot(eyeRay, samplePoint) / height;
                    float scatter = (startOffset + depth*(scale(lightAngle) - scale(cameraAngle)));
                    float3 attenuate = exp(-scatter * (kInvWavelength * kKr4PI + kKm4PI));
 
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
 
                float3 pos = cameraPos + far * eyeRay;
 
                // Calculate the ray's starting position, then calculate its scattering offset
                float depth = exp((-kCameraHeight) * (1.0/kScaleDepth));
                float cameraAngle = dot(-eyeRay, pos);
                float lightAngle = dot(_WorldSpaceLightPos0.xyz, pos);
                float cameraScale = scale(cameraAngle);
                float lightScale = scale(lightAngle);
                float cameraOffset = depth*cameraScale;
                float temp = (lightScale + cameraScale);
               
                // Initialize the scattering loop variables
                float sampleLength = far / kSamples;
                float scaledLength = sampleLength * kScale;
                float3 sampleRay = eyeRay * sampleLength;
                float3 samplePoint = cameraPos + sampleRay * 0.5;
               
                // Now loop through the sample rays
                float3 frontColor = float3(0.0, 0.0, 0.0);
                float3 attenuate;

                for(int i=0; i<int(kSamples); i++)
                {
                    float height = length(samplePoint);
                    float depth = exp(kScaleOverScaleDepth * (kInnerRadius - height));
                    float scatter = depth*temp - cameraOffset;
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
 
        half4 frag (v2f IN) : SV_Target
        {
            half3 col;
			float3 clouds;
			float3 light;
			float3 finalCol;

			float m = (_Time.y);
			gTime = _Time.y * 0.5 + m + 75.5;
			cloudy = cos(gTime * 0.25 + 0.4) * 0.26;
			float2 xy = IN.pos / _ScreenParams.xy;
			float lightning = 0.0;
			if(cloudy >= 0.2)
			{
				float f = fmod(_Time.x + 1.5, 2.5);

				if(f < .8)
				{
					f = smoothstep(0.8, 0.0, f) * 1.5;
					lightning = fmod(-gTime * (1.5 - Hash(gTime * 0.3) * 0.002), 1.0) *	f;

				}
			}

			flash = clamp (float3(1.0, 1.0, 1.2) * lightning, 0.0, 1.0);
		
			if(IN.rayDir.y < 0.0)
            {
                half eyeCos = dot(_WorldSpaceLightPos0.xyz, normalize(IN.rayDir.xyz));
                half eyeCos2 = eyeCos * eyeCos;
			    clouds =  GetSky(float3(0,0,0), IN.rayDir) + getRayleighPhase(eyeCos2) * IN.cIn.xyz + getMiePhase(eyeCos, eyeCos2) * IN.cOut * _LightColor0;
		

                col = getRayleighPhase(eyeCos2) * IN.cIn.xyz + getMiePhase(eyeCos, eyeCos2) * IN.cOut * _LightColor0;			
		
				clouds *= lerp(clouds, col, col);
				finalCol = col + clouds;
            }
            else
            {
                col = IN.cIn.xyz + _GroundColor * IN.cOut;
				clouds = IN.cIn.xyz + _GroundColor * IN.cOut;
				finalCol = col + clouds;
            }
            //Adjust color from HDR

            finalCol *= _HdrExposure;
			finalCol *= .55+0.45*pow(70.0 * xy.x * xy.y * (1.0 - xy.x ) * (1.0 - xy.y), 0.15 );

			//finalCol += gTime;
            return half4(finalCol,1.0);
 
        }
        ENDCG
    }
}    
 
 
Fallback Off
 
}