Shader "Test/SkyGenerator"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_NoiseTex("Noise Texture", 2D) = "white"{}
	}
	SubShader
	{
		Tags { "LightMode" = "ForwardBase" }
		Cull Off
		Zwrite Off
		Fog { Mode off }
		Pass
		{
			CGPROGRAM
			#pragma glsl
			#pragma vertex vert
			#pragma fragment frag		
			#include "UnityCG.cginc"

			#define CLOUD_LOWER 2000.0
			#define CLOUD_UPPER 3000.0

			#define TEXTURE_NOISE
			//#define REAL_SHADOW

			#define MOD2 float2(.16632, .17369)
			#define MOD3 float3(.16532, .17369, .15787)

			uniform float4 _BackColor;
			uniform float cloudy;
			uniform half4 _LightColor0;
			uniform float gTime;
			//uniform float3 _MousePos;
			uniform float2 _iResolution;
			float3 flash;

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 pos : SV_POSITION;
				float4 Wpos: TEXCOORD1;
				float3 normal : NORMAL;
			};

			sampler2D _MainTex;
			sampler2D _NoiseTex;
			float4 _MainTex_ST;

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
				f += 0.2500 * Noise(p); p = p * 3.03;
				f += 0.1250 * Noise(p); p = p * 3.01;
				f += 0.0625 * Noise(p); p = p * 3.03;
				f += 0.03125 * Noise(p); p = p * 3.02;
				f += 0.015625 * Noise(p);
				return f;
			}
			//============================================
			//============================================
			float SeaFBM(float2 p)
			{
				float f;
				f = (sin(sin(p.x * 1.22 + _Time.x) + cos(p.y * .14) + p.x * .15 + p.y * 1.33 - _Time.x)) * 1.0;
				f += (sin(p.x * 0.9 + _Time.x + p.y * 0.3 - _Time.x)) * 1.0;
				f += (cos(p.x * 0.7 + _Time.x + p.y * 0.4 - _Time.x)) * 0.5;
				f += 1.5000 * (0.5 - abs(Noise(p) - 0.5)); p = p * 2.05;
				f += .75000 * (0.5 - abs(Noise(p) - 0.5)); p = p * 2.02;
				f += 0.2500 * Noise(p); p = p * 2.07;
				f += 0.1250 * Noise(p); p = p * 2.13;
				f += 0.0625 * Noise(p);

				return f;
			}
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
			float SeaMap(in float2 pos)
			{
				pos *= 0.0025;
				return SeaFBM(pos) * (20.0 + cloudy * 70.0);
			}
			//============================================
			//============================================
			float3 SeaNormal(in float3 pos, in float d, out float height)
			{
				float p = 0.00f * d * d / _iResolution.x;
				float3 nor = float3(0.0,		SeaMap(pos.xz), 0.0);
				float3 v2 = nor - float3(p,		SeaMap(pos.xz + float2(p, 0.0)), 0.0);
				float3 v3 = nor - float3(0.0,	SeaMap(pos.xz + float2(0.0, -p)), -p);
				height = nor.y;
				nor = cross(v2, v3);
				return normalize (nor);
			}
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
			float3 GetSky(in float3 pos, in float3 rd, out float2 outPos)
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
				outPos = p.xz;
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
				for(int i = 0; i < 25; i++)
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

			v2f vert (appdata_full v)
			{
				v2f o;
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
				o.Wpos = mul(unity_WorldToObject, v.vertex);
				o.uv = v.texcoord;
				o.normal = v.normal;
				return o;
			}
			

			fixed4 frag (v2f i) : SV_Target
			{ 
				float m = (_Time.y);
				gTime = _Time.x * 0.5 + m + 75.5;
				cloudy = cos(gTime * 0.25 + 0.4) * 0.26;
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

				float2 xy = (-1.0 + 2.0 * i.uv);
				float2 uv = (-1.0 + 2.0 * xy);

				float3 cameraPos = _WorldSpaceCameraPos;
				float3 camTar = CameraPath(1 - 0.0);
				//camTar.y = cameraPos.y = sin(_Time.x) * 200.0 + 300.0;
				//camTar.y += 370.0;

				float roll = 0;
				float3 cw = normalize(camTar - cameraPos);
				float3 cp = float3(sin(roll), cos(roll), 0.0);
				float3 cu = cross(cw,cp);
				float3 cv = cross(cu, cw);
				float3 dir = normalize(uv.x * cu + uv.y * cv + 1.3 * cw);
				float3x3 camMat = float3x3(cu, cv, cw);

				float3 col;
				float2 pos;

				if(dir.y < 0.0)
				{
					col = GetSky(float3(1,1,1), dir, pos);
				}
				else
				{
					//col = GetSky(cameraPos, dir, pos);
				}
				float l = exp(-length(pos) * 0.00002);

				col = lerp(float3(0.6 - cloudy * 1.2, 0,0) + 
						flash * 0.3, col, max(1, 0.2));
				// Do te Lends Flare...
				float bri = dot(cw, _WorldSpaceLightPos0) * 2.7 * clamp(-cloudy + .2, 0.0, .2);

				if (bri > 0.0)
	{
		float2 sunPos = float2( dot( _WorldSpaceLightPos0, cu ), dot( _WorldSpaceLightPos0, cv ) );
		float2 uvT = uv-sunPos;
		uvT = uvT*(length(uvT));
		bri = pow(bri, 6.0)*.6;

		float glare1 = max(1.2-length(uvT+sunPos*2.)*2.0, 0.0);
		float glare2 = max(1.2-length(uvT+sunPos*.5)*4.0, 0.0);
		uvT = lerp (uvT, uv, -2.3);
		float glare3 = max(1.2-length(uvT+sunPos*5.0)*1.2, 0.0);

		col += bri * _LightColor0 * float3(1.0, .5, .2)  * pow(glare1, 10.0)*25.0;
		col += bri * float3(.8, .8, 1.0) * pow(glare2, 8.0)*9.0;
		col += bri * _LightColor0 * pow(glare3, 4.0)*10.0;
		}
	
			float2 st =  uv * float2(.5+(xy.y+1.0)*.3, .02)+float2(gTime*.5+xy.y*.2, gTime*.2);
			// Rain...
		#ifdef TEXTURE_NOISE
		 	float f = tex2Dlod(_NoiseTex, float4(st, -100.0, 1.0)).y * tex2Dlod(_NoiseTex, float4( st*.773, -100.0, 1.0)).x * 1.55;
		#else
			float f = Noise( st*200.5 ) * Noise( st*120.5 ) * 1.3;
		#endif
			float rain = clamp(cloudy-.15, 0.0, 1.0);
			f = clamp(pow(abs(f), 15.0) * 5.0 * (rain*rain*125.0), 0.0, (xy.y+.1)*.6);
			col = lerp(col, float3(0.15, .15, .15)+flash, f);
			col = clamp(col, 0.0,1.0);
		
			// Stretch RGB upwards... 
			//col = (1.0 - exp(-col * 2.0)) * 1.1565;
			//col = (1.0 - exp(-col * 3.0)) * 1.052;
			col = pow(col, float3(.7,.7,.7));
			//col = (col*col*(3.0-2.0*col));

			col *= .55+0.45*pow(70.0*xy.x*xy.y*(1.0-xy.x)*(1.0-xy.y), 0.15 );	

				return float4(col, 1.0);
			}
			ENDCG
		}
	}
}
