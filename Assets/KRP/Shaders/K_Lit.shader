Shader "KRP/K_Lit"
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
            #pragma vertex vert
            #pragma fragment frag

            #include "../ShaderLibrary/K_Common.hlsl"
            #include "../ShaderLibrary/K_Surface.hlsl"
            #include "../ShaderLibrary/K_Light.hlsl"
            #include "../ShaderLibrary/K_BRDF.hlsl"
            #include "../ShaderLibrary/K_Lighting.hlsl"

            TEXTURE2D(_BaseMap);    SAMPLER(sampler_BaseMap);

            UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
                UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
                UNITY_DEFINE_INSTANCED_PROP(float4, _BaseCol)
                UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
                UNITY_DEFINE_INSTANCED_PROP(float, _Metallic)
                UNITY_DEFINE_INSTANCED_PROP(float, _Smoothness)
            UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

            struct Attributes
            {
                float4 posOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
                // Object index
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 posCS : SV_POSITION;
                float3 posWS : VAR_POSITION;
                float2 uv : VAR_UV;
                float3 normalWS : VAR_NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings vert (Attributes i)
            {   
                Varyings o;
                UNITY_SETUP_INSTANCE_ID(i);
                UNITY_TRANSFER_INSTANCE_ID(i, o);
                float4 baseMapST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseMap_ST);
                o.uv = i.uv * baseMapST.xy + baseMapST.zw;
                o.posWS = TransformObjectToWorld(i.posOS.xyz);
                o.posCS = TransformWorldToHClip(o.posWS.xyz);
                o.normalWS = TransformObjectToWorldNormal(i.normalOS);
                return o;
            }

            half4 frag (Varyings i) : SV_Target
            {   
                UNITY_SETUP_INSTANCE_ID(i);

                half3 baseCol = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseCol).rgb;
                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                half3 col = baseCol * baseMap.rgb;

                #ifdef _CLIPPING
                    clip(baseMap.a - UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff));
                #endif

                Surface surface;
                surface.normal = normalize(i.normalWS);
                surface.color = col;
                surface.alpha = baseMap.a;
                surface.metallic = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Metallic);
                surface.smoothness = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Smoothness);
                surface.viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWS);

                col = GetLighting(surface);

                return half4(col, surface.alpha);
            }
            ENDHLSL
        }
    }
    CustomEditor "KRPShaderGUI"
}