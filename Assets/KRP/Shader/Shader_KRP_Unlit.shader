Shader "KRP/Unlit"
{
    Properties
    {   
        _BaseMap ("Texture", 2D) = "white" {}
        [PerRendererData] _BaseCol ("Color", Color) = (1,1,1,1)
        [PerRendererData] _Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.0
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend", Float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend", Float) = 0
        [Enum(Off, 0, On, 1)] _ZWrite ("Z Write", Float) = 1
        [Toggle(_CLIPPING)] _Clipping ("Alpha Clipping", Float) = 0
    }
    SubShader
    {
        Tags {}
        LOD 100

        Pass
        {
            Tags {}

            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]

            HLSLPROGRAM
            #pragma target 3.5
            #pragma multi_compile_instancing
            #pragma shader_feature _ _CLIPPING
            #pragma vertex vert
            #pragma fragment frag

            #include "KRP_Common.hlsl"

            TEXTURE2D(_BaseMap);    SAMPLER(sampler_BaseMap);

            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
                UNITY_DEFINE_INSTANCED_PROP(float4, _BaseCol)
                UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
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
                float2 uv : VAR_UV;
                float4 pos : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert (Attributes i)
            {   
                Varyings o;
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_TRANSFER_INSTANCE_ID(i, o);
                float4 baseMapST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseMap_ST);
                o.uv = i.uv * baseMapST.xy + baseMapST.zw;
                o.pos = TransformObjectToHClip(i.posOS.xyz);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {   
                UNITY_SETUP_INSTANCE_ID(i);

                half4 baseCol = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseCol);
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                half4 col = baseCol * baseMap;

                #ifdef _CLIPPING
                    clip(col.a - UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff));
                #endif

                return col;
            }
            ENDHLSL
        }
    }
}