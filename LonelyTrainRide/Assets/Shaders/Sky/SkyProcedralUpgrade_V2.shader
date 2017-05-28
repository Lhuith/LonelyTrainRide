// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Eugene/Enviroment/Sky/ProceduralUpgrade_V2" {
Properties {
    _HdrExposure("HDR Exposure", float) = 1.3
    _GroundColor ("Ground", Color) = (.369, .349, .341, 1)
	_SkyAddColor ("Additional Sky Color Add", Color) = (.369, .349, .341, 1)

    _RL("Rayleigh", float) = 0.0025
    _MIE ("MIE", float) = 0.0010
    _SUN("Sun brightness", float) = 20.0
	_NoiseTex("Noise Texture", 2D) = "white"{}
	_FallOffTex01("FallOff Texture 01", 2D) = "white"{}
	_CloudCoverage("Cloud Density", Range(-1,1)) = 0
	_CloudThickness("Cloud Thickness", Range(0,150)) = 50
	_CloudAborbsion("Cloud Light Absorbstion Factor", Range(0.0000, 2.0000)) = 1.030725
	_IterationSteps("Cloud Resolution", Range(1, 200)) = 55
	_FBMFrequency("Cloud SmoothNess", Range(0,5)) = 2.76434
}
 
SubShader {

    Tags { "Queue"="Background" "RenderType"="Sky" "PreviewType"="Skybox" }
    Pass 
	{
       Name "CLOUDS"
        CGPROGRAM
		//#pragma pack_matrix(row_major)
        #pragma vertex vert
        #pragma fragment frag

        #include "UnityCG.cginc"
        #include "Lighting.cginc"
		#include "SparkNoiseSky.cginc"
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

float4 render_clouds(
	_in(ray_t) eye, fixed lightAngle
){
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

	for (int i = 0; i < steps; i++) {
		fixed h = fixed(i) / fixed(steps);
		fixed dens = density (pos, WIND, h);

		fixed T_i = exp(-ABSORPTION * dens * march_step);
		T *= T_i;
		if (T < .01) break;

		C += T * 
			light(pos, lightAngle) *
			dens * march_step;
		alpha += (1. - T_i) * (1. - alpha);

		pos += dir_step;
		if (length(pos) > 1e3) break;
	}

	return float4(C, alpha);
}
        struct appdata_t {
            half4 vertex : POSITION;
        };
 
        struct v2f {
                half4 pos : SV_POSITION;
                half3 rayDir : TEXCOORD0;    // Vector for incoming ray, normalized ( == -eyeRay )
                half3 cIn : TEXCOORD1;         // In-scatter coefficient
                half3 cOut : TEXCOORD2;        // Out-scatter coefficient
				half3 viewDir : TEXCOORD3;
				half3 tex : TEXCOORD4;
				half lightDirAngle : TEXCOORD5;

           };
		
	

        half scale(half inCos)
        {
            half x = 1.0 - inCos;
            return 0.25 * exp(-0.00287 + x*(0.459 + x*(3.83 + x*(-6.80 + x*5.25))));
        }
 
        v2f vert (appdata_base v)
        {
            v2f OUT;
            OUT.pos = UnityObjectToClipPos(v.vertex);
            half3 cameraPos = half3(0,kInnerRadius + kCameraHeight,0);     // The camera's current position
			OUT.tex = v.texcoord;
            // Get the ray from the camera to the vertex and its length (which is the far point of the ray passing through the atmosphere)
            half3 eyeRay = normalize(mul((half3x3)unity_ObjectToWorld, v.vertex.xyz));
 
            OUT.rayDir = half3(-eyeRay);
 
            half far = 0.0;


			half3 fragmentToLightSource = _WorldSpaceLightPos0.xyz - mul(unity_ObjectToWorld, v.vertex);
					OUT.lightDirAngle = float4(
					normalize(lerp(_WorldSpaceLightPos0.xyz, fragmentToLightSource, _WorldSpaceLightPos0.w)),
					lerp(1.0, 1.0/length(fragmentToLightSource), _WorldSpaceLightPos0.w)
					);

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

	fixed fov = tan(radians(45.0));

	float3 cloudcol = float3(0, 0, 0);

			float3 col;
			float3 stars = float3(0,0,0);

			if(IN.rayDir.y < 0.01)
            {
						    // Add stars.
				float s = pow(max(0.0, snoise(IN.tex * 1e2)), 18.0);
				 stars += float3(s, s, s);
				
				float3 eye = float3(0, 1.02, 0);
				float3 point_cam = float3(0, 0.91, 0);
				float2 point_ndc = IN.pos.xy;
				point_ndc.y = 1. - point_ndc.y;

                fixed eyeCos = dot(_WorldSpaceLightPos0.xyz, normalize(float3(IN.rayDir.x, IN.rayDir.y, IN.rayDir.z)));
                fixed eyeCos2 = eyeCos * eyeCos;
			
				float3 look_at = float3(IN.rayDir.x, .3 - IN.rayDir.y, IN.rayDir.z);
				//ray_t eye_ray = get_primary_ray(point_cam, eye, look_at);
				
			    ray_t eye_ray = get_primary_ray(point_cam, eye, look_at);

				 fixed lightCos = dot(_WorldSpaceLightPos0.xyz , normalize(float3(IN.rayDir.x, -IN.rayDir.y, IN.rayDir.z)));
                fixed lightCos2 = lightCos * lightCos;

				float4 cld = render_clouds(eye_ray, _WorldSpaceLightPos0);

				fixed mie =  getMiePhase(eyeCos, eyeCos2);


				cloudcol = lerp(cld, mie, mie);

				stars -= cld;

                col = (getRayleighPhase(eyeCos2)) * IN.cIn.xyz + cld.rgb + (mie) * _LightColor0 * IN.cOut + stars;
				//float3 sky = render_sky_color(eye_ray, IN.lightDirAngle);


				col = lerp(col, cld,  cld.a);
				//cloudcol = lerp(col, cld.rgb/(0.000001+cld.a), cld.a) * _LightColor0;
				//cloudcol *= mie + getRayleighPhase(eyeCos2);
		
            }
            else
            {
				cloudcol = IN.cIn.xyz + _GroundColor * IN.cOut;
                col = IN.cIn.xyz + _GroundColor * IN.cOut;
            }
            //Adjust color from HDR

			col *= _HdrExposure;
			cloudcol *=  _HdrExposure;
			//finalCol *= .55+0.45*pow(70.0 * xy.x * xy.y * (1.0 - xy.x ) * (1.0 - xy.y), 0.15 );
            return  float4(col, 1.0);
 
        }
        ENDCG
    }
}    
 
 
Fallback Off
 
}