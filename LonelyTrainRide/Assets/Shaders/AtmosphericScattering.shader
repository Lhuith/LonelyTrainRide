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



Shader "Hidden/AtmosphericScattering"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_ZTest ("ZTest", Float) = 0
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		CGINCLUDE
		#include "UnityCG.cginc"
		#include "UnityDeferredLibrary.cginc"

		#include "AtmosphericScattering.cginc"

		sampler2D _LightShaft1;

		struct appdata
		{
			float4 vertex : POSITION;
		};
		
		float _DistanceScale;

		struct v2f
		{
			float4 pos : SV_POSITION;
			float4 uv : TEXCOORD0;
			float3 wpos : TEXCOORD1;
		};
		               
		ENDCG
            
		// pass 0 - precompute particle density
		Pass
		{
			ZTest Off
			Cull Off
			ZWrite Off
			Blend Off

			CGPROGRAM

            #pragma vertex vertQuad
            #pragma fragment particleDensityLUT
            #pragma target 4.0

            #define UNITY_HDR_ON

            struct v2p
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            struct input
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            v2p vertQuad(input v)
            {
                v2p o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord.xy;
                return o;
            }

			float2 particleDensityLUT(v2p i) : SV_Target
			{
                float cosAngle = i.uv.x * 2.0 - 1.0;
                float sinAngle = sqrt(saturate(1 - cosAngle * cosAngle));
                float startHeight = lerp(0.0, _AtmosphereHeight, i.uv.y);

                float3 rayStart = float3(0, startHeight, 0);
                float3 rayDir = float3(sinAngle, cosAngle, 0);
                
				return PrecomputeParticleDensity(rayStart, rayDir);
			}

			ENDCG
		}
			
		// pass 1 - ambient light LUT
		Pass
		{
			ZTest Off
			Cull Off
			ZWrite Off
			Blend Off

			CGPROGRAM

#pragma vertex vertQuad
#pragma fragment fragDir
#pragma target 4.0

			struct v2p
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			struct input
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			v2p vertQuad(input v)
			{
				v2p o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord.xy;
				return o;
			}

			float4 fragDir(v2f i) : SV_Target
			{
				float cosAngle = i.uv.x * 1.1 - 0.1;// *2.0 - 1.0;
                float sinAngle = sqrt(saturate(1 - cosAngle * cosAngle));
                    
                float3 lightDir = -normalize(float3(sinAngle, cosAngle, 0));

				return PrecomputeAmbientLight(lightDir);
			}
			ENDCG
		}

		// pass 2 - dir light LUT
		Pass
		{
			ZTest Off
			Cull Off
			ZWrite Off
			Blend Off

			CGPROGRAM

#pragma vertex vertQuad
#pragma fragment fragDir
#pragma target 4.0
#include "SparkNoiseSky.cginc"
			struct v2p
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			struct input
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
			};

			v2p vertQuad(input v)
			{
				v2p o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord.xy;
				return o;
			}

			float4 fragDir(v2f i) : SV_Target
			{
				float cosAngle = i.uv.x * 1.1 - 0.1;// *2.0 - 1.0;
				
				float sinAngle = sqrt(saturate(1 - cosAngle * cosAngle));				
				float3 rayDir = normalize(float3(sinAngle, cosAngle, 0));

				return PrecomputeDirLight(rayDir);
			}
			ENDCG
		}

			
		// pass 3 - atmocpheric fog
		Pass
		{
			ZTest Always Cull Off ZWrite Off
			Blend One Zero

			CGPROGRAM

#pragma vertex vertDir
#pragma fragment fragDir
#pragma target 4.0

#define UNITY_HDR_ON

#pragma shader_feature ATMOSPHERE_REFERENCE
#pragma shader_feature LIGHT_SHAFTS

			sampler2D _Background;			
		
 		uniform half gTime;
		uniform half _SUN;
        uniform half _HdrExposure,_RL,_MIE;        // HDR exposure
        uniform half3 _GroundColor;
		uniform fixed _CloudCoverage;
		uniform fixed _CloudThickness;
		uniform fixed _CloudAborbsion;
		uniform fixed _IterationSteps;
		uniform fixed _FBMFrequency;
		uniform float4 _SkyAddColor;


			static const fixed u_time = _Time.x * 10;

		
		/**** TWEAK *****************************************************************/
		#define COVERAGE		_CloudCoverage
		#define THICKNESS		_CloudThickness
		#define ABSORPTION		_CloudAborbsion
		static const float3  WIND	=		float3(0, 0, -u_time * .2);
		
		#define FBM_FREQ		_FBMFrequency
		#define NOISE_VALUE
		//#define NOISE_WORLEY
		//#define NOISE_PERLIN
		
		//#define SIMULATE_LIGHT
		//#define FAKE_LIGHT

		#define STEPS			_IterationSteps
		/******************************************************************************/


        #define _in(T) const in T
        #define _inout(T) inout T
        #define _out(T) out T
        #define _begin(type) {
        #define _end }
        #define _mutable(T) static T
        #define _constant(T) static const T
        #define float2 float2
        #define float3 float3
        #define float4 float4
        #define mat2 float2x2
        #define mat3 float3x3
        #define mat4 float4x4
        #define lerp lerp
        #define fract frac
        #define atan(y, x) atan2(x, y)
        #define mod fmod
		
		sampler2D _NoiseTex;
		half4 _MainTex_ST;
		sampler2D _FallOffTex01;
		half4 _FallOffTex01_ST;


		#define PI 3.14159265359

struct ray_t {
	float3 origin;
	float3 direction;
};
#define BIAS 1e-4 // small offset to avoid self-intersections

struct sphere_t {
	float3 origin;
	fixed radius;
	int material;
};

struct plane_t {
	float3 direction;
	fixed distance;
	int material;
};

struct hit_t {
	fixed t;
	int material_id;
	float3 normal;
	float3 origin;
};
#define max_dist 1e8
_constant(hit_t) no_hit = _begin(hit_t)
	fixed(max_dist + 1e1), // 'infinite' distance
	-1, // material id
	float3(0., 0., 0.), // normal
	float3(0., 0., 0.) // origin
_end;


// ----------------------------------------------------------------------------
// Various 3D utilities functions
// ----------------------------------------------------------------------------

ray_t get_primary_ray(
	_in(float3) cam_local_point,
	_inout(float3) cam_origin,
	_inout(float3) cam_look_at
){
	float3 fwd = normalize(cam_look_at - cam_origin);
	float3 up = float3(0, 1, 0);
	float3 right = cross(up, fwd);
	up = cross(fwd, right);

	ray_t r = _begin(ray_t)
		cam_origin,
		normalize(fwd + up * cam_local_point.y + right * cam_local_point.x)
		_end;
	return r;
}

mat2 rotate_2d(
	_in(fixed) angle_degrees
){
	fixed angle = radians(angle_degrees);
	fixed _sin = sin(angle);
	fixed _cos = cos(angle);
	return mat2(_cos, -_sin, _sin, _cos);
}

mat3 rotate_around_z(
	_in(fixed) angle_degrees
){
	fixed angle = radians(angle_degrees);
	fixed _sin = sin(angle);
	fixed _cos = cos(angle);
	return mat3(_cos, -_sin, 0, _sin, _cos, 0, 0, 0, 1);
}

mat3 rotate_around_y(
	_in(fixed) angle_degrees
){
	fixed angle = radians(angle_degrees);
	fixed _sin = sin(angle);
	fixed _cos = cos(angle);
	return mat3(_cos, 0, _sin, 0, 1, 0, -_sin, 0, _cos);
}

mat3 rotate_around_x(
	_in(fixed) angle_degrees
){
	fixed angle = radians(angle_degrees);
	fixed _sin = sin(angle);
	fixed _cos = cos(angle);
	return mat3(1, 0, 0, 0, _cos, -_sin, 0, _sin, _cos);
}

float3 corect_gamma(
	_in(float3) color,
	_in(fixed) gamma
){
	fixed p = 1.0 / gamma;
	return float3(pow(color.r, p), pow(color.g, p), pow(color.b, p));
}
 
fixed checkboard_pattern(
	_in(float2) pos,
	_in(fixed) scale
){
	float2 pattern = floor(pos * scale);
	return mod(pattern.x + pattern.y, 2.0);
}

fixed band (
	_in(fixed) start,
	_in(fixed) peak,
	_in(fixed) end,
	_in(fixed) t
){
	return
	smoothstep (start, peak, t) *
	(1. - smoothstep (peak, end, t));
}

// ----------------------------------------------------------------------------
// Analytical surface-ray intersection routines
// ----------------------------------------------------------------------------

// geometrical solution
// info: http://www.scratchapixel.com/old/lessons/3d-basic-lessons/lesson-7-intersecting-simple-shapes/ray-sphere-intersection/
void intersect_sphere(
	_in(ray_t) ray,
	_in(sphere_t) sphere,
	_inout(hit_t) hit
){
	float3 rc = sphere.origin - ray.origin;
	fixed radius2 = sphere.radius * sphere.radius;
	fixed tca = dot(rc, ray.direction);
//	if (tca < 0.) return;

	fixed d2 = dot(rc, rc) - tca * tca;
	if (d2 > radius2)
		return;

	fixed thc = sqrt(radius2 - d2);
	fixed t0 = tca - thc;
	fixed t1 = tca + thc;

	if (t0 < 0.) t0 = t1;
	if (t0 > hit.t)
		return; 

	float3 impact = ray.origin + ray.direction * t0;

	hit.t = t0;
	hit.material_id = sphere.material;
	hit.origin = impact;
	hit.normal = (impact - sphere.origin) / sphere.radius;
}

// Plane is defined by normal N and distance to origin P0 (which is on the plane itself)
// a plane eq is: (P - P0) dot N = 0
// which means that any line on the plane is perpendicular to the plane normal
// a ray eq: P = O + t*D
// substitution and solving for t gives:
// t = ((P0 - O) dot N) / (N dot D)
void intersect_plane(
	_in(ray_t) ray,
	_in(plane_t) p,
	_inout(hit_t) hit
){
	fixed denom = dot(p.direction, ray.direction);
	if (denom < 1e-6) return;

	float3 P0 = float3(p.distance, p.distance, p.distance);
	fixed t = dot(P0 - ray.origin, p.direction) / denom;
	if (t < 0. || t > hit.t) return;
	
	hit.t = t;
	hit.material_id = p.material;
	hit.origin = ray.origin + ray.direction * t;
	hit.normal = faceforward(p.direction, ray.direction, p.direction);
}

// ----------------------------------------------------------------------------
// Noise function by iq from https://www.shadertoy.com/view/4sfGzS
// ----------------------------------------------------------------------------

fixed hash(
	_in(fixed) n
){
	return fract(sin(n)*753.5453123);
}

fixed noise_iq(
	_in(float3) x
){
	float3 p = floor(x);
	float3 f = fract(x);
	f = f*f*(3.0 - 2.0*f);

	float2 uv = (p.xy + float2(37.0, 17.0)*p.z) + f.xy;
	float4 coords = float4((uv+.5)/256., 0., 0.);
	float2 rg = tex2Dlod( _NoiseTex, coords).yx;
	return lerp(rg.x, rg.y, f.z);

}
// ----------------------------------------------------------------------------
// Noise function by iq from https://www.shadertoy.com/view/ldl3Dl
// ----------------------------------------------------------------------------

float3 hash_w(in float3 x)
{
	return tex2D(_NoiseTex, (x.xy + float2(3.0, 1.0)*x.z + 0.5) / 256.0).xyz; // ment to be -100.0 in there
}

// returns closest, second closest, and cell id
float3 noise_w(
	_in(float3) x
){
	float3 p = floor(x);
	float3 f = fract(x);

	fixed id = 0.0;
	float2 res = float2(100.0, 100.0);
	for (int k = -1; k <= 1; k++)
		for (int j = -1; j <= 1; j++)
			for (int i = -1; i <= 1; i++)
			{
				float3 b = float3(fixed(i), fixed(j), fixed(k));
				float3 r = float3(b) - f + hash_w(p + b);
				fixed d = dot(r, r);

				if (d < res.x)
				{
					id = dot(p + b, float3(1.0, 57.0, 113.0));
					res = float2(d, res.x);
				}
				else if (d < res.y)
				{
					res.y = d;
				}
			}

	return float3(sqrt(res), abs(id));
}
//
// GLSL textureless classic 3D noise "cnoise",
// with an RSL-style periodic variant "pnoise".
// Author:  Stefan Gustavson (stefan.gustavson@liu.se)
// Version: 2011-10-11
//
// Many thanks to Ian McEwan of Ashima Arts for the
// ideas for permutation and gradient selection.
//
// Copyright (c) 2011 Stefan Gustavson. All rights reserved.
// Distributed under the MIT license. See LICENSE file.
// https://github.com/ashima/webgl-noise
//

float3 mod289(float3 x)
{
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

float4 mod289(float4 x)
{
  return x - floor(x * (1.0 / 289.0)) * 289.0;
}

float4 permute(float4 x)
{
  return mod289(((x*34.0)+1.0)*x);
}

float4 taylorInvSqrt(float4 r)
{
  return 1.79284291400159 - 0.85373472095314 * r;
}

float3 fade(float3 t) {
  return t*t*t*(t*(t*6.0-15.0)+10.0);
}

// Classic Perlin noise
fixed cnoise(float3 P)
{
  float3 Pi0 = floor(P); // Integer part for indexing
  float3 Pi1 = Pi0 + float3(1, 1, 1); // Integer part + 1
  Pi0 = mod289(Pi0);
  Pi1 = mod289(Pi1);
  float3 Pf0 = fract(P); // Fractional part for interpolation
  float3 Pf1 = Pf0 - float3(1, 1, 1); // Fractional part - 1.0
  float4 ix = float4(Pi0.x, Pi1.x, Pi0.x, Pi1.x);
  float4 iy = float4(Pi0.yy, Pi1.yy);
  float4 iz0 = Pi0.zzzz;
  float4 iz1 = Pi1.zzzz;

  float4 ixy = permute(permute(ix) + iy);
  float4 ixy0 = permute(ixy + iz0);
  float4 ixy1 = permute(ixy + iz1);

  float4 gx0 = ixy0 * (1.0 / 7.0);
  float4 gy0 = fract(floor(gx0) * (1.0 / 7.0)) - 0.5;
  gx0 = fract(gx0);
  float4 gz0 = float4(.5, .5, .5, .5) - abs(gx0) - abs(gy0);
  float4 sz0 = step(gz0, float4(0, 0, 0, 0));
  gx0 -= sz0 * (step(0.0, gx0) - 0.5);
  gy0 -= sz0 * (step(0.0, gy0) - 0.5);

  float4 gx1 = ixy1 * (1.0 / 7.0);
  float4 gy1 = fract(floor(gx1) * (1.0 / 7.0)) - 0.5;
  gx1 = fract(gx1);
  float4 gz1 = float4(.5, .5, .5, .5) - abs(gx1) - abs(gy1);
  float4 sz1 = step(gz1, float4(0, 0, 0, 0));
  gx1 -= sz1 * (step(0.0, gx1) - 0.5);
  gy1 -= sz1 * (step(0.0, gy1) - 0.5);

  float3 g000 = float3(gx0.x,gy0.x,gz0.x);
  float3 g100 = float3(gx0.y,gy0.y,gz0.y);
  float3 g010 = float3(gx0.z,gy0.z,gz0.z);
  float3 g110 = float3(gx0.w,gy0.w,gz0.w);
  float3 g001 = float3(gx1.x,gy1.x,gz1.x);
  float3 g101 = float3(gx1.y,gy1.y,gz1.y);
  float3 g011 = float3(gx1.z,gy1.z,gz1.z);
  float3 g111 = float3(gx1.w,gy1.w,gz1.w);

  float4 norm0 = taylorInvSqrt(float4(dot(g000, g000), dot(g010, g010), dot(g100, g100), dot(g110, g110)));
  g000 *= norm0.x;
  g010 *= norm0.y;
  g100 *= norm0.z;
  g110 *= norm0.w;
  float4 norm1 = taylorInvSqrt(float4(dot(g001, g001), dot(g011, g011), dot(g101, g101), dot(g111, g111)));
  g001 *= norm1.x;
  g011 *= norm1.y;
  g101 *= norm1.z;
  g111 *= norm1.w;

  fixed n000 = dot(g000, Pf0);
  fixed n100 = dot(g100, float3(Pf1.x, Pf0.yz));
  fixed n010 = dot(g010, float3(Pf0.x, Pf1.y, Pf0.z));
  fixed n110 = dot(g110, float3(Pf1.xy, Pf0.z));
  fixed n001 = dot(g001, float3(Pf0.xy, Pf1.z));
  fixed n101 = dot(g101, float3(Pf1.x, Pf0.y, Pf1.z));
  fixed n011 = dot(g011, float3(Pf0.x, Pf1.yz));
  fixed n111 = dot(g111, Pf1);

  float3 fade_xyz = fade(Pf0);
  float4 n_z = lerp(float4(n000, n100, n010, n110), float4(n001, n101, n011, n111), fade_xyz.z);
  float2 n_yz = lerp(n_z.xy, n_z.zw, fade_xyz.y);
  fixed n_xyz = lerp(n_yz.x, n_yz.y, fade_xyz.x); 
  return 2.2 * n_xyz;
}

// Classic Perlin noise, periodic variant
fixed pnoise(float3 P, float3 rep)
{
  float3 Pi0 = mod(floor(P), rep); // Integer part, modulo period
  float3 Pi1 = mod(Pi0 + float3(1, 1, 1), rep); // Integer part + 1, mod period
  Pi0 = mod289(Pi0);
  Pi1 = mod289(Pi1);
  float3 Pf0 = fract(P); // Fractional part for interpolation
  float3 Pf1 = Pf0 - float3(1, 1, 1); // Fractional part - 1.0
  float4 ix = float4(Pi0.x, Pi1.x, Pi0.x, Pi1.x);
  float4 iy = float4(Pi0.yy, Pi1.yy);
  float4 iz0 = Pi0.zzzz;
  float4 iz1 = Pi1.zzzz;

  float4 ixy = permute(permute(ix) + iy);
  float4 ixy0 = permute(ixy + iz0);
  float4 ixy1 = permute(ixy + iz1);

  float4 gx0 = ixy0 * (1.0 / 7.0);
  float4 gy0 = fract(floor(gx0) * (1.0 / 7.0)) - 0.5;
  gx0 = fract(gx0);
  float4 gz0 = float4(.5, .5, .5, .5) - abs(gx0) - abs(gy0);
  float4 sz0 = step(gz0, float4(0, 0, 0, 0));
  gx0 -= sz0 * (step(0.0, gx0) - 0.5);
  gy0 -= sz0 * (step(0.0, gy0) - 0.5);

  float4 gx1 = ixy1 * (1.0 / 7.0);
  float4 gy1 = fract(floor(gx1) * (1.0 / 7.0)) - 0.5;
  gx1 = fract(gx1);
  float4 gz1 = float4(.5, .5, .5, .5) - abs(gx1) - abs(gy1);
  float4 sz1 = step(gz1, float4(0, 0, 0, 0));
  gx1 -= sz1 * (step(0.0, gx1) - 0.5);
  gy1 -= sz1 * (step(0.0, gy1) - 0.5);

  float3 g000 = float3(gx0.x,gy0.x,gz0.x);
  float3 g100 = float3(gx0.y,gy0.y,gz0.y);
  float3 g010 = float3(gx0.z,gy0.z,gz0.z);
  float3 g110 = float3(gx0.w,gy0.w,gz0.w);
  float3 g001 = float3(gx1.x,gy1.x,gz1.x);
  float3 g101 = float3(gx1.y,gy1.y,gz1.y);
  float3 g011 = float3(gx1.z,gy1.z,gz1.z);
  float3 g111 = float3(gx1.w,gy1.w,gz1.w);

  float4 norm0 = taylorInvSqrt(float4(dot(g000, g000), dot(g010, g010), dot(g100, g100), dot(g110, g110)));
  g000 *= norm0.x;
  g010 *= norm0.y;
  g100 *= norm0.z;
  g110 *= norm0.w;
  float4 norm1 = taylorInvSqrt(float4(dot(g001, g001), dot(g011, g011), dot(g101, g101), dot(g111, g111)));
  g001 *= norm1.x;
  g011 *= norm1.y;
  g101 *= norm1.z;
  g111 *= norm1.w;

  fixed n000 = dot(g000, Pf0);
  fixed n100 = dot(g100, float3(Pf1.x, Pf0.yz));
  fixed n010 = dot(g010, float3(Pf0.x, Pf1.y, Pf0.z));
  fixed n110 = dot(g110, float3(Pf1.xy, Pf0.z));
  fixed n001 = dot(g001, float3(Pf0.xy, Pf1.z));
  fixed n101 = dot(g101, float3(Pf1.x, Pf0.y, Pf1.z));
  fixed n011 = dot(g011, float3(Pf0.x, Pf1.yz));
  fixed n111 = dot(g111, Pf1);

  float3 fade_xyz = fade(Pf0);
  float4 n_z = lerp(float4(n000, n100, n010, n110), float4(n001, n101, n011, n111), fade_xyz.z);
  float2 n_yz = lerp(n_z.xy, n_z.zw, fade_xyz.y);
  fixed n_xyz = lerp(n_yz.x, n_yz.y, fade_xyz.x); 
  return 2.2 * n_xyz;
}

#ifdef NOISE_VALUE
#define noise(x) noise_iq(x)
#endif
#ifdef NOISE_WORLEY
#define noise(x) (1. - noise_w(x).r)
//#define noise(x) abs( noise_iq(x / 8.) - (1. - (noise_w(x * 2.).r)))
#endif
#ifdef NOISE_PERLIN
#define noise(x) abs(cnoise(x))
#endif
// ----------------------------------------------------------------------------
// Fractal Brownian Motion
// ----------------------------------------------------------------------------

fixed fbm(
	_in(float3) pos,
	_in(fixed) lacunarity
){
	float3 p = pos;
	fixed
	t  = 0.51749673 * noise(p); p *= lacunarity;
	t += 0.25584929 * noise(p); p *= lacunarity;
	t += 0.12527603 * noise(p); p *= lacunarity;
	t += 0.06255931 * noise(p);
	
	return t;
}

fixed get_noise(in float3 x)
{
	return fbm(x, FBM_FREQ);
}

_constant(float3) sun_color = float3(1., .7, .55);

_constant(sphere_t) atmosphere = _begin(sphere_t)
	float3(0, -450, 0), 500., 0
_end;
_constant(sphere_t) atmosphere_2 = _begin(sphere_t)
	atmosphere.origin, atmosphere.radius + 50., 0
_end;
_constant(plane_t) ground = _begin(plane_t)
	float3(0., -1., 0.), 0., 1
_end;

float3 render_sky_color(_in(ray_t) eye, fixed lightAngle){
	float3 rd = eye.direction;
	fixed sun_amount = max(dot(rd, lightAngle), 0.0);

	float3  sky = lerp(float3(.0, .1, .4), float3(.3, .6, .8), 1.0 - rd.y);
	sky = sky + sun_color * min(pow(sun_amount, 1500.0) * 5.0, 1.0);
	sky = sky + sun_color * min(pow(sun_amount, 10.0) * .6, 1.0);

	return sky;
}

fixed density(
	_in(float3) pos,
	_in(float3) offset,
	_in(fixed) t
){
	// signal
	float3 p = pos * .0212242 + offset;
	fixed dens = get_noise(p);
	
	fixed cov = 1. - COVERAGE;
	//dens = band (.1, .3, .6, dens);
	//dens *= step(cov, dens);
	//dens -= cov;
	dens *= smoothstep (cov, cov + .05, dens);

	return clamp(dens, 0., 1.);	
}

fixed light(
	_in(float3) origin, fixed lightAngle
){
	const int steps = 18;
	fixed march_step = 1.5;

	float3 pos = origin;
	float3 dir_step = lightAngle * march_step;
	fixed T = 1.; // transmitance

	for (int i = 0; i < steps; i++) {
		fixed dens = density(pos, WIND, 0.);

		fixed T_i = exp(-ABSORPTION * dens * march_step);
		T *= T_i;
		//if (T < .01) break;

		pos += dir_step;
	}

	return T;
}

float4 render_clouds(_in(ray_t) eye, fixed lightAngle)
{
	hit_t hit = no_hit;
	intersect_sphere(eye, atmosphere, hit);
	//hit_t hit_2 = no_hit;
	//intersect_sphere(eye, atmosphere_2, hit_2);

	const fixed thickness = THICKNESS; // length(hit_2.origin - hit.origin);
	//const fixed r = 1. - ((atmosphere_2.radius - atmosphere.radius) / thickness);
	const int steps = STEPS; // +int(32. * r);
	fixed march_step = thickness / fixed(steps);

	float3 dir_step = eye.direction / eye.direction.y * march_step;
	float3 pos = //eye.origin + eye.direction * 100.; 
		hit.origin;

	fixed T = 1.; // transmitance
	float3 C = float3(0, 0, 0); // color
	fixed alpha = 0.;

	for (int i = 0; i < steps; i++) 
	{
		fixed h = fixed(i) / fixed(steps);
		fixed dens = density (pos, WIND, h);

		fixed T_i = 1;//exp(-ABSORPTION * dens * march_step);
		T *= T_i;
		if (T < .01) break;

		C += T * 
			light(pos, lightAngle) *
			dens * march_step;
		alpha += (1. - T_i) * (1. - alpha);

		pos += dir_step;
		if (length(pos) > 1e3) break;
	}

	return float4(C, 1);
}

			struct VSInput
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				uint vertexId : SV_VertexID;
			};

			struct PSInput
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 wpos : TEXCOORD1;
			};

			PSInput vertDir(VSInput i)
			{
				PSInput o;

				o.pos = UnityObjectToClipPos(i.vertex);
				o.uv = i.uv;
				o.wpos = _FrustumCorners[i.vertexId];

				return o;
			}

			float4 fragDir(v2f i) : COLOR0
			{
				float2 uv = i.uv.xy;
				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv);
				float linearDepth = Linear01Depth(depth);

				float3 wpos = i.wpos;
				float3 rayStart = _WorldSpaceCameraPos;
				float3 rayDir = wpos - _WorldSpaceCameraPos;
				rayDir *= linearDepth;

				float rayLength = length(rayDir);
				rayDir /= rayLength;
					
				float3 planetCenter = _WorldSpaceCameraPos;
				planetCenter = float3(0, -_PlanetRadius, 0);
				float2 intersection = RaySphereIntersection(rayStart, rayDir, planetCenter, _PlanetRadius + _AtmosphereHeight);
				if (linearDepth > 0.99999)
				{
					rayLength = 1e20;
				}
				rayLength = min(intersection.y, rayLength);

				intersection = RaySphereIntersection(rayStart, rayDir, planetCenter, _PlanetRadius);
				if (intersection.x > 0)
					rayLength = min(rayLength, intersection.x);

				float4 extinction;
				_SunIntensity = 0;
				float4 inscattering = IntegrateInscattering(rayStart, rayDir, rayLength, planetCenter, _DistanceScale, _LightDir, 16, extinction);
					
#ifndef ATMOSPHERE_REFERENCE
				inscattering.xyz = tex3D(_InscatteringLUT, float3(uv.x, uv.y, linearDepth));
				extinction.xyz = tex3D(_ExtinctionLUT, float3(uv.x, uv.y, linearDepth));
#endif					
#ifdef LIGHT_SHAFTS
				float shadow = tex2D(_LightShaft1, uv.xy).x;
				shadow = (pow(shadow, 4) + shadow) / 2;
				shadow = max(0.1, shadow);

				inscattering *= shadow;
#endif
				float4 background = tex2D(_Background, uv);

				if (linearDepth > 0.99999)
				{
#ifdef LIGHT_SHAFTS
					background *= shadow;
#endif
					inscattering = 0;
					extinction = 1;
				}
					
				float4 c = background * extinction + inscattering;
				return c;
			}
			ENDCG
		}
	}
}
