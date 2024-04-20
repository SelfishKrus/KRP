Shader "KRP/Lit"
{
    Properties
    {   
        _BaseMap ("Texture", 2D) = "white" {}
        _BaseCol ("Color", Color) = (1,1,1,1)
        _Cutoff ("Alpha Cutoff", Range(0.0, 1.0)) = 0.0
		[Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend", Float) = 1
		[Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend", Float) = 0
        [Enum(Off, 0, On, 1)] _ZWrite ("Z Write", Float) = 1
        [Toggle(_CLIPPING)] _Clipping ("Alpha Clipping", Float) = 0
        [KeywordEnum(On, Clip, Dither, Off)] _Shadows ("Shadows", Float) = 0
        [Toggle(_RECEIVE_SHADOWS)] _ReceiveShadows ("Receive Shadows", Float) = 1

        [Header(PBR ARGS)]
        _Metallic ("Metallic", Range(0.0, 1.0)) = 0.0
        _Smoothness ("Smoothness", Range(0.0, 1.0)) = 0.5
        [Toggle(_PREMULTIPLY_ALPHA)] _PremultiplyAlpha ("Premultiply Alpha", Float) = 0
    }
    SubShader
    {
        Tags {}
        LOD 100

        Pass
        {
            Tags {"LightMode"="KRPLit"}

            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]

            HLSLPROGRAM
            #pragma target 3.5
            #pragma multi_compile_instancing
            #pragma shader_feature _ _CLIPPING
            #pragma shader_feature _ _PREMULTIPLY_ALPHA
            #pragma shader_feature _RECEIVE_SHADOWS
            #pragma multi_compile _ _DIRECTIONAL_PCF3 _DIRECTIONAL_PCF5 _DIRECTIONAL_PCF7
            #pragma multi_compile _ _CASCADE_BLEND_SOFT _CASCADE_BLEND_DITHER

            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

            #include "KRP_LitPass.hlsl"

            ENDHLSL
        }

        Pass
        {   
            Name "ShadowCaster"

            Tags {"LightMode"="ShadowCaster"}
            ColorMask 0

            HLSLPROGRAM
			#pragma target 3.5
            #pragma shader_feature _ _SHADOWS_CLIP _SHADOWS_DITHER
			#pragma multi_compile_instancing

			#pragma vertex ShadowCasterPassVertex
			#pragma fragment ShadowCasterPassFragment

            #include "KRP_ShadowCasterPass.hlsl"

			ENDHLSL
        }
    }
    CustomEditor "KRPShaderGUI"
}