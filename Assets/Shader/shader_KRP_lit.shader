Shader "KRP/Lit"
{   

    Properties
    {   
        _MainTex ("Texture", 2D) = "" {}
        [Enum(UnityEngine.Rendering.BlendMode)] _SrcBlend ("Src Blend", Float) = 1
        [Enum(UnityEngine.Rendering.BlendMode)] _DstBlend ("Dst Blend", Float) = 0
        [Enum(Off, 0, On, 1)] _ZWrite ("ZWrite", Float) = 1
        [Toggle(_CLIPPING)] _Clipping ("Alpha Clipping", Float) = 1

        _Tint ("Tint", Color) = (1,1,1,1)
        _BaseTex ("Base Color", 2D) = "" {}
        _NormalTex ("Normal Map", 2D) = "normal" {}
        _NormalScale ("Normal Scale", Range(0, 3)) = 1.0
        _MetallicTex ("Metallic Map", 2D) = "black" {}
        _RoughnessTex ("Roughness Map", 2D) = "white" {}
        _RoughnessScale ("Roughness Scale", Range(0, 1)) = 1.0
        _AOTex ("AO Map", 2D) = "white" {}
        _AOScale ("AO Scale", Range(0, 3)) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalRenderPipeline" "Queue"="Geometry" "IgnoreProjector"="True"}
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
            
            #pragma vertex LitPassVertex
            #pragma fragment LitPassFragment

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

            #include "KRP_LitPass.hlsl"

            ENDHLSL
        }
    }

    CustomEditor "KRPLitShaderGUI"

}
