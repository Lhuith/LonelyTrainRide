Shader "Eugene/SSS/Depth"
{
    Properties
    {
		_MainTex("Thickness Texture", 2D) = "white" {}
    }
 
    SubShader
    {
       Tags { "Queue" = "Transparent" }
        //LOD 200
 
        Pass
        {
            Lighting Off
			Blend One One
            Fog{ Mode Off }
 
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma fragmentoption ARB_precision_hint_fastest
 
            struct a2v
            {
                float4 vertex : POSITION;
                fixed4 color : COLOR;
            };
 
            struct v2f
            {
                float4 pos : SV_POSITION;
                half dist : TEXCOORD0;
            };
 
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                float4 temp = mul(UNITY_MATRIX_IT_MV, v.vertex);
                o.dist = temp.z;
                return o;
            }
 
            fixed4 frag(v2f i) : COLOR
            {            
                float depth = i.dist;
                return half4(depth, depth, depth, 1);
            }
            ENDCG
        }
 
        Pass
        {
            Lighting Off
			Blend One One
            Fog{ Mode Off }
            Cull Front
            ZTest Greater /* This was needed to render the back faces on top of the front faces */
 
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma fragmentoption ARB_precision_hint_fastest
 
            struct a2v
            {
                float4 vertex : POSITION;
                fixed4 color : COLOR;
            };
 
            struct v2f
            {
                float4 pos : SV_POSITION;
                half dist : TEXCOORD0;
            };
 
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                float4 temp = mul(UNITY_MATRIX_IT_MV, v.vertex);
                o.dist = temp.z;
                return o;
            }
 
            fixed4 frag(v2f i) : COLOR
            {
                float depth = -i.dist;
                return half4(depth, depth, depth, 1);
            }
            ENDCG
        }
    }
 
    FallBack Off
}