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
        float4 tangentOS : TANGENT;

        GI_ATTRIBUTE_DATA
        // Object index
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct Varyings
    {
        float4 posCS : SV_POSITION;
        float3 posWS : VAR_POSITION;
        float2 uv_base : VAR_UV_BASE;
        #if defined(_DETAIL_MAP)
            float2 uv_detail : VAR_UV_DETAIL;
        #endif 
        float3 normalWS : VAR_NORMAL;
        #if defined(_NORMAL_MAP)
		    float4 tangentWS : VAR_TANGENT;
	    #endif

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
        #if defined(_DETAIL_MAP)
            o.uv_detail = TransformDetailUV(i.uv_base);
        #endif 
        o.posWS = TransformObjectToWorld(i.posOS.xyz);
        o.posCS = TransformWorldToHClip(o.posWS.xyz);
        o.normalWS = TransformObjectToWorldNormal(i.normalOS);
        #if defined(_NORMAL_MAP)
            o.tangentWS = float4(TransformObjectToWorldDir(i.tangentOS.xyz), i.tangentOS.w);
        #endif
        return o;
    }

    half4 LitPassFragment (Varyings i) : SV_Target
    {   
        UNITY_SETUP_INSTANCE_ID(i);

        ClipLOD(i.posCS.xy, unity_LODFade.x);

        InputConfig config = GetInputConfig(i.uv_base);
        #if defined(_MASK_MAP) 
            config.useMask = true;
        #endif 
        #if defined(_DETAIL_MAP)
            config.uv_detail = i.uv_detail;
            config.useDetail = true;
        #endif 

        half4 baseCol = GetBaseColor(config);

        #ifdef _CLIPPING
            clip(baseCol.a - GetCutoff(i.uv_base));
        #endif

        Surface surface;
        surface.position = i.posWS;
        #if defined(_NORMAL_MAP)
            surface.normal = NormalTangentToWorld(GetNormalTS(config), i.normalWS, i.tangentWS);
            surface.interpolatedNormal = i.normalWS;
        #else
		    surface.normal = normalize(i.normalWS);
		    surface.interpolatedNormal = surface.normal;
	    #endif
        surface.color = baseCol.rgb;
        surface.alpha = baseCol.a;
        surface.metallic = GetMetallic(config);
        surface.occlusion = GetOcclusion(config);
        surface.smoothness = GetSmoothness(config);
        surface.fresnelStrength = GetFresnel(i.uv_base);
        surface.dither = InterleavedGradientNoise(i.posCS.xy, 0);
        surface.viewDirection = normalize(_WorldSpaceCameraPos.xyz - i.posWS);
        surface.depth = -TransformWorldToView(i.posWS).z;

        BRDF brdf = GetBRDF(surface);
        GI gi = GetGI(GI_FRAGMENT_DATA(i), surface, brdf);
        half3 col = GetLighting(surface, gi, brdf);
        col += GetEmission(config);

        return half4(col, surface.alpha);
    }

#endif 