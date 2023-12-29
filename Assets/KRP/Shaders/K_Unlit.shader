Shader "KRP/K_Unlit"
{
    Properties
    {
        _BaseCol ("Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags {}
        LOD 100

        Pass
        {
            Tags {}

            HLSLPROGRAM
            #pragma multi_compile_instancing
            #pragma vertex vert
            #pragma fragment frag

            #include "../ShaderLibrary/K_Common.hlsl"

            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float4, _BaseCol)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

            struct Attributes
            {
                float4 posOS : POSITION;
                float2 uv : TEXCOORD0;
                // Object index
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert (Attributes i)
            {   
                Varyings o;
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_TRANSFER_INSTANCE_ID(i, o);
                o.uv = i.uv;
                o.pos = TransformObjectToHClip(i.posOS.xyz);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {   
                UNITY_SETUP_INSTANCE_ID(i);
                half3 col;
                col = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseCol).rgb;

                return half4(col, 1);
            }
            ENDHLSL
        }
    }
}