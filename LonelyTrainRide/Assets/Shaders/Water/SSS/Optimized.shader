// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader"EugeneShader/ShaderTestDemos/9_Optomize"{
Properties{
	_Color("ColorTint", Color) = (1.0, 1.0, 1.0, 1.0)
	_MainTex("Diffuse Texture", 2D) = "white" {}
	_BumpMap("Normal Texture", 2D) = "bump" {}
	_EmitMap("Emission Texture", 2D) = "black" {}
	_BumpDepth("Bump Depth", Range(0, 1.0)) = 1
	_SpecColor("Specular Color", Color) = (1.0, 1.0, 1.0, 1.0)
	_Shininess("Shininess", Float) = 10
	_RimColor("Rim Color", Color) = (1.0, 1.0, 1.0, 1.0)
	_RimPower("Rim Power", Range(0.1, 10.0)) = 0.3
	_EmitStrength("Emission Strength Depth", Range(0.0, 2.0)) = 0
}
SubShader{
		Pass{
		Tags{"LightMode" = "ForwardBase"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			//user defined veriables
			uniform sampler2D _MainTex;
			uniform half4 _MainTex_ST;
			uniform sampler2D _BumpMap;
			uniform half4 _BumpMap_ST;
			uniform sampler2D _EmitMap;
			uniform half4 _EmitMap_ST;
			uniform fixed4 _Color;
			uniform fixed4 _SpecColor;
			uniform fixed4 _RimColor;
			uniform float _Shininess;
			uniform float _RimPower;
			uniform fixed _BumpDepth;
			uniform fixed _EmitStrength;
			
			//unity defined veriables
			uniform half4 _LightColor0;
			
			//structs
			struct vertexInput{
				half4 vertex : POSITION;
				half3 normal : NORMAL;
				half4 texcoord : TEXCOORD0;
				half4 tangent : TANGENT;
			};
			
			struct vertexOutput{
			half4 pos : SV_POSITION;
			half4 tex : TEXCOORD0;
			fixed4 lightDirection : TEXCOORD1;
			fixed3 viewDirection : TEXCOORD2;
			fixed3 normalWorld : TEXCOORD3;
			fixed3 tangentWorld : TEXCOORD4;
			fixed3 binormalWorld : TEXCOORD5;
			};
			
			
			
			//Vertex Function
			vertexOutput vert(vertexInput v){
			
			vertexOutput o;
			
			o.normalWorld = normalize(mul(half4(v.normal, 0.0), unity_WorldToObject).xyz);
			o.tangentWorld = normalize(mul(unity_ObjectToWorld, v.tangent).xyz);
			o.binormalWorld = normalize(cross(o.normalWorld, o.tangentWorld) * v.tangent.w);
			
			half4 posWorld = mul(unity_ObjectToWorld, v.vertex);
			o.pos = UnityObjectToClipPos(v.vertex);
			o.tex = v.texcoord;
			
			o.viewDirection = normalize(_WorldSpaceCameraPos.xyz - posWorld.xyz);
			
			 
			half3 fragmentToLightSource = _WorldSpaceLightPos0.xyz - posWorld.xyz;
				
			o.lightDirection = fixed4(
			normalize(lerp(_WorldSpaceLightPos0.xyz,fragmentToLightSource, _WorldSpaceLightPos0.w)),
			lerp(1.0,1.0/length(fragmentToLightSource), _WorldSpaceLightPos0.w)
			);
			
			
			return o;
			}
			
			
			//Fragment Function
			fixed4 frag(vertexOutput i) : COLOR
			{

			
			//Texture Maps
			fixed4 tex = tex2D(_MainTex, i.tex.xy * _MainTex_ST.xy + _MainTex_ST.zw);
			fixed4 texN = tex2D(_BumpMap, i.tex.xy * _MainTex_ST.xy + _BumpMap_ST.zw);
			fixed4 texE = tex2D(_EmitMap, i.tex.xy * _MainTex_ST.xy + _EmitMap_ST.zw);
			
			//unpackNormal function
			fixed3 localCoords = float3(2.0 * texN.ag - float2(1.0, 1.0),	_BumpDepth);
			
			//normal transpose matrix
			fixed3x3 local2WorldTranspose = fixed3x3(
			i.tangentWorld,
			i.binormalWorld,
			i.normalWorld
			);
			
			//calculate normal direction
			fixed3 normalDirection = normalize( mul(localCoords, local2WorldTranspose));
			
			//Lighting
			//dot product
			fixed nNdotL = saturate(dot(normalDirection, i.lightDirection.xyz));
			
			fixed3 diffuseReflection = i.lightDirection.w * _LightColor0.xyz * nNdotL;
			fixed3 specularReflection = diffuseReflection * _SpecColor.xyz * pow(saturate(dot(reflect(-i.lightDirection.xyz, normalDirection), i.viewDirection)) , _Shininess); 
				
			//Rim Lighting
			fixed rim = 1 - nNdotL; 
			fixed3 rimLighting = nNdotL * _RimColor.xyz * _LightColor0.xyz * pow(rim, _RimPower);
			
			fixed3 lightFinal = UNITY_LIGHTMODEL_AMBIENT.xyz + diffuseReflection + (specularReflection * tex.a) + rimLighting + (texE.xyz * _EmitStrength);
			
			
			return fixed4(tex.xyz * lightFinal * _Color.xyz, 1.0);
			}
			ENDCG
			}
			
	Pass{
		Tags{"LightMode" = "ForwardAdd"}
		Blend One One
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			//user defined veriables
			uniform sampler2D _MainTex;
			uniform half4 _MainTex_ST;
			uniform sampler2D _BumpMap;
			uniform half4 _BumpMap_ST;
			uniform sampler2D _EmitMap;
			uniform half4 _EmitMap_ST;
			uniform fixed4 _Color;
			uniform fixed4 _SpecColor;
			uniform fixed4 _RimColor;
			uniform float _Shininess;
			uniform float _RimPower;
			uniform fixed _BumpDepth;
			uniform fixed _EmitStrength;
			
			//unity defined veriables
			uniform half4 _LightColor0;
			
			//structs
			struct vertexInput{
				half4 vertex : POSITION;
				half3 normal : NORMAL;
				half4 texcoord : TEXCOORD0;
				half4 tangent : TANGENT;
			};
			
			struct vertexOutput{
			half4 pos : SV_POSITION;
			half4 tex : TEXCOORD0;
			fixed4 lightDirection : TEXCOORD1;
			fixed3 viewDirection : TEXCOORD2;
			fixed3 normalWorld : TEXCOORD3;
			fixed3 tangentWorld : TEXCOORD4;
			fixed3 binormalWorld : TEXCOORD5;
			};
			
			
			
			//Vertex Function
			vertexOutput vert(vertexInput v){
			
			vertexOutput o;
			
			o.normalWorld = normalize(mul(half4(v.normal, 0.0), unity_WorldToObject).xyz);
			o.tangentWorld = normalize(mul(unity_ObjectToWorld, v.tangent).xyz);
			o.binormalWorld = normalize(cross(o.normalWorld, o.tangentWorld) * v.tangent.w);
			
			half4 posWorld = mul(unity_ObjectToWorld, v.vertex);
			o.pos = UnityObjectToClipPos(v.vertex);
			o.tex = v.texcoord;
			
			o.viewDirection = normalize(_WorldSpaceCameraPos.xyz - posWorld.xyz);
			
			 
			half3 fragmentToLightSource = _WorldSpaceLightPos0.xyz - posWorld.xyz;
				
			o.lightDirection = fixed4(
			normalize(lerp(_WorldSpaceLightPos0.xyz,fragmentToLightSource, _WorldSpaceLightPos0.w)),
			lerp(1.0,1.0/length(fragmentToLightSource), _WorldSpaceLightPos0.w)
			);
			
			
			return o;
			}
			
			
			//Fragment Function
			fixed4 frag(vertexOutput i) : COLOR
			{

			
			//Texture Maps
			fixed4 tex = tex2D(_MainTex, i.tex.xy * _MainTex_ST.xy + _MainTex_ST.zw);
			fixed4 texN = tex2D(_BumpMap, i.tex.xy * _MainTex_ST.xy + _BumpMap_ST.zw);
			
			//unpackNormal function
			fixed3 localCoords = float3(2.0 * texN.ag - float2(1.0, 1.0),	_BumpDepth);
			
			//normal transpose matrix
			fixed3x3 local2WorldTranspose = fixed3x3(
			i.tangentWorld,
			i.binormalWorld,
			i.normalWorld
			);
			
			//calculate normal direction
			fixed3 normalDirection = normalize( mul(localCoords, local2WorldTranspose));
			
			//Lighting
			//dot product
			fixed nNdotL = saturate(dot(normalDirection, i.lightDirection.xyz));
			
			fixed3 diffuseReflection = i.lightDirection.w * _LightColor0.xyz *nNdotL;
			fixed3 specularReflection = diffuseReflection * _SpecColor.xyz * pow(saturate(dot(reflect(-i.lightDirection.xyz, normalDirection), i.viewDirection)) , _Shininess); 
				
			//Rim Lighting
			fixed rim = 1 - nNdotL; 
			fixed3 rimLighting = nNdotL * _RimColor.xyz * _LightColor0.xyz * pow(rim, _RimPower);
			
			fixed3 lightFinal = diffuseReflection + (specularReflection * tex.a) + rimLighting;
			
			
			return fixed4(lightFinal, 1.0);
			}
			ENDCG
			}
			
	}
//FallBack "Specular"
}
