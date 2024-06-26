Shader "KRP/Unlit"
{
    Properties
    {   
        [HideInInspector] _MainTex("Texture for Lightmap", 2D) = "white" {}
		[HideInInspector] _Color("Color for Lightmap", Color) = (0.5, 0.5, 0.5, 1.0)

        _BaseMap ("Texture", 2D) = "white" {}
        [HDR] _BaseColor ("Color", Color) = (1,1,1,1)
        _Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.0
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend", Float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend", Float) = 0
        [Enum(Off, 0, On, 1)] _ZWrite ("Z Write", Float) = 1
        [Toggle(_CLIPPING)] _Clipping ("Alpha Clipping", Float) = 0
    }
    SubShader
    {
        Tags {}
        LOD 100

        HLSLINCLUDE
        #include "../ShaderLibrary/KRP_Common.hlsl"
        #include "../ShaderLibrary/KRP_UnlitInput.hlsl"
        ENDHLSL

        Pass
        {   
            Name "UnlitPass"

            Tags {}

            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]

            HLSLPROGRAM
            #pragma target 3.5
            #pragma multi_compile_instancing
            #pragma shader_feature _ _CLIPPING
            #pragma vertex vert
            #pragma fragment frag

            struct Attributes
            {
                float4 posOS : POSITION;
                float2 uv_base : TEXCOORD0;
                // Object index
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float2 uv_base : VAR_UV_BASE;
                float4 pos : SV_POSITION;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert (Attributes i)
            {   
                Varyings o;
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_TRANSFER_INSTANCE_ID(i, o);
                o.uv_base = TransformBaseUV(i.uv_base);
                o.pos = TransformObjectToHClip(i.posOS.xyz);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {   
                UNITY_SETUP_INSTANCE_ID(i);

                InputConfig config = GetInputConfig(i.uv_base);
                half4 col = GetBaseColor(config);

                #ifdef _CLIPPING
                    clip(col.a - UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff));
                #endif

                return col;
            }
            ENDHLSL
        }

        Pass 
        {   
            Name "MetaPass"

			Tags 
            {
				"LightMode" = "Meta"
			}

			Cull Off

			HLSLPROGRAM
			#pragma target 3.5
			#pragma vertex MetaPassVertex
			#pragma fragment MetaPassFragment

            #pragma multi_compile _ LIT_SHADER UNLIT_SHADER

			#include "KRP_MetaPass.hlsl"

			ENDHLSL
		}
    }

    CustomEditor "KRPShaderGUI"
}