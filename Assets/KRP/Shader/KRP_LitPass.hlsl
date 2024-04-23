#ifndef KRP_LIT_PASS_INCLUDED
#define KRP_LIT_PASS_INCLUDED

    //#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Random.hlsl"

    #include "KRP_Surface.hlsl"
    #include "KRP_Shadows.hlsl"
    #include "KRP_Light.hlsl"
    #include "KRP_BRDF.hlsl"
    #include "KRP_Lighting.hlsl"

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

        half4 baseCol = GetBaseColor(i.uv_base);

        #ifdef _CLIPPING
            clip(baseMap.a - GetCutoff(i.uv_base));
        #endif

        Surface surface;
        surface.position = i.posWS;
        surface.normal = normalize(i.normalWS);
        surface.color = baseCol.rgb;
        surface.alpha = baseCol.a;
        surface.metallic = GetMetallic(i.uv_base);
        surface.smoothness = GetSmoothness(i.uv_base);
        surface.dither = InterleavedGradientNoise(i.posCS.xy, 0);
        surface.viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWS);
        surface.depth = -TransformWorldToView(i.posWS).z;

        GI gi = GetGI(GI_FRAGMENT_DATA(i), surface);
        half3 col = GetLighting(surface, gi);
        col += GetEmission(i.uv_base);

        return half4(col, surface.alpha);
    }

#endif 