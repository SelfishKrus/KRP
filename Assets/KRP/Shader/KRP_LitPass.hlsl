#ifndef KRP_LIT_PASS_INCLUDED
#define KRP_LIT_PASS_INCLUDED

    //#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Random.hlsl"

    #include "../ShaderLibrary/KRP_Surface.hlsl"
    #include "../ShaderLibrary/KRP_Shadows.hlsl"
    #include "../ShaderLibrary/KRP_Light.hlsl"
    #include "../ShaderLibrary/KRP_BRDF.hlsl"
    #include "../ShaderLibrary/KRP_Lighting.hlsl"

    struct Attributes
    {
        float4 posOS : POSITION;
        float2 uv_base : TEXCOORD0;
        float3 normalOS : NORMAL;

        GI_ATTRIBUTE_DATA
        // Object index
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct Varyings
    {
        float4 posCS : SV_POSITION;
        float3 posWS : VAR_POSITION;
        float2 uv_base : VAR_UV;
        float3 normalWS : VAR_NORMAL;

        GI_VARYINGS_DATA
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    Varyings LitPassVertex (Attributes i)
    {   
        Varyings o;
        UNITY_SETUP_INSTANCE_ID(i);
        UNITY_TRANSFER_INSTANCE_ID(i, o);
        TRANSFER_GI_DATA(i, o);

        o.uv_base = TransformBaseUV(i.uv_base);
        o.posWS = TransformObjectToWorld(i.posOS.xyz);
        o.posCS = TransformWorldToHClip(o.posWS.xyz);
        o.normalWS = TransformObjectToWorldNormal(i.normalOS);
        return o;
    }

    half4 LitPassFragment (Varyings i) : SV_Target
    {   
        UNITY_SETUP_INSTANCE_ID(i);

        ClipLOD(i.posCS.xy, unity_LODFade.x);

        half4 baseCol = GetBaseColor(i.uv_base);

        #ifdef _CLIPPING
            clip(baseCol.a - GetCutoff(i.uv_base));
        #endif

        Surface surface;
        surface.position = i.posWS;
        surface.normal = normalize(i.normalWS);
        surface.color = baseCol.rgb;
        surface.alpha = baseCol.a;
        surface.metallic = GetMetallic(i.uv_base);
        surface.occlusion = GetOcclusion(i.uv_base);
        surface.smoothness = GetSmoothness(i.uv_base);
        surface.fresnelStrength = GetFresnel(i.uv_base);
        surface.dither = InterleavedGradientNoise(i.posCS.xy, 0);
        surface.viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWS);
        surface.depth = -TransformWorldToView(i.posWS).z;

        BRDF brdf = GetBRDF(surface);
        GI gi = GetGI(GI_FRAGMENT_DATA(i), surface, brdf);
        half3 col = GetLighting(surface, gi, brdf);
        col += GetEmission(i.uv_base);

        return half4(col, surface.alpha);
    }

#endif 