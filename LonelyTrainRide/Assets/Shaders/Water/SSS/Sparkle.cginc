fixed3 mod289(fixed3 x) {
				return x - floor(x * (1.0 / 289.0)) * 289.0;
			}

			fixed4 mod289(fixed4 x) {
				return x - floor(x * (1.0 / 289.0)) * 289.0;
			}

			fixed4 permute(fixed4 x) {
				return mod289(((x*34.0) + 1.0)*x);
			}

			fixed4 taylorInvSqrt(fixed4 r)
			{
				return 1.79284291400159 - 0.85373472095314 * r;
			}

			fixed snoise(fixed3 v)
			{
				const fixed2  C = fixed2(1.0 / 6.0, 1.0 / 3.0);
				const fixed4  D = fixed4(0.0, 0.5, 1.0, 2.0);

				// First corner
				fixed3 i = floor(v + dot(v, C.yyy));
				fixed3 x0 = v - i + dot(i, C.xxx);

				// Other corners
				fixed3 g = step(x0.yzx, x0.xyz);
				fixed3 l = 1.0 - g;
				fixed3 i1 = min(g.xyz, l.zxy);
				fixed3 i2 = max(g.xyz, l.zxy);

				//   x0 = x0 - 0.0 + 0.0 * C.xxx;
				//   x1 = x0 - i1  + 1.0 * C.xxx;
				//   x2 = x0 - i2  + 2.0 * C.xxx;
				//   x3 = x0 - 1.0 + 3.0 * C.xxx;
				fixed3 x1 = x0 - i1 + C.xxx;
				fixed3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
				fixed3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y

										   // Permutations
				i = mod289(i);
				fixed4 p = permute(permute(permute(
					i.z + fixed4(0.0, i1.z, i2.z, 1.0))
					+ i.y + fixed4(0.0, i1.y, i2.y, 1.0))
					+ i.x + fixed4(0.0, i1.x, i2.x, 1.0));

				// Gradients: 7x7 points over a square, mapped onto an octahedron.
				// The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
				fixed n_ = 0.142857142857; // 1.0/7.0
				fixed3  ns = n_ * D.wyz - D.xzx;

				fixed4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  fmod(p,7*7)

				fixed4 x_ = floor(j * ns.z);
				fixed4 y_ = floor(j - 7.0 * x_);    // fmod(j,N)

				fixed4 x = x_ *ns.x + ns.yyyy;
				fixed4 y = y_ *ns.x + ns.yyyy;
				fixed4 h = 1.0 - abs(x) - abs(y);

				fixed4 b0 = fixed4(x.xy, y.xy);
				fixed4 b1 = fixed4(x.zw, y.zw);

				//fixed4 s0 = fixed4(lessThan(b0,0.0))*2.0 - 1.0;
				//fixed4 s1 = fixed4(lessThan(b1,0.0))*2.0 - 1.0;
				fixed4 s0 = floor(b0)*2.0 + 1.0;
				fixed4 s1 = floor(b1)*2.0 + 1.0;
				fixed4 sh = -step(h, fixed4(0.0, 0.0, 0.0, 0.0));

				fixed4 a0 = b0.xzyw + s0.xzyw*sh.xxyy;
				fixed4 a1 = b1.xzyw + s1.xzyw*sh.zzww;

				fixed3 p0 = fixed3(a0.xy, h.x);
				fixed3 p1 = fixed3(a0.zw, h.y);
				fixed3 p2 = fixed3(a1.xy, h.z);
				fixed3 p3 = fixed3(a1.zw, h.w);

				//Normalise gradients
				fixed4 norm = taylorInvSqrt(fixed4(dot(p0, p0), dot(p1, p1), dot(p2, p2), dot(p3, p3)));
				p0 *= norm.x;
				p1 *= norm.y;
				p2 *= norm.z;
				p3 *= norm.w;

				// lerp final noise value
				fixed4 m = max(0.6 - fixed4(dot(x0, x0), dot(x1, x1), dot(x2, x2), dot(x3, x3)), 0.0);
				m = m * m;
				return 42.0 * dot(m*m, fixed4(dot(p0, x0), dot(p1, x1),
					dot(p2, x2), dot(p3, x3)));
			}

			fixed3 hsv(fixed h, fixed s, fixed v)
			{
				return lerp(fixed3(1.0, 1.0, 1.0), clamp((abs(frac(
					h + fixed3(3.0, 2.0, 1.0) / 3.0) * 6.0 - 3.0) - 1.0), 0.0, 1.0), s) * v;
			}

		
