#ifndef KRP_LIT_INPUT_INCLUDED
#define KRP_LIT_INPUT_INCLUDED

    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"

    TEXTURE2D(_BaseMap);        SAMPLER(sampler_BaseMap);
    TEXTURE2D(_EmissionMap);
    TEXTURE2D(_MainTex);
    TEXTURE2D(_MaskMap);
    TEXTURE2D(_NormalMap);

    TEXTURE2D(_DetailMap);      SAMPLER(sampler_DetailMap);
    TEXTURE2D(_DetailNormalMap);

    UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
        UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
        UNITY_DEFINE_INSTANCED_PROP(float4, _DetailMap_ST)
        UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
        UNITY_DEFINE_INSTANCED_PROP(float4, _EmissionColor)
        UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
        UNITY_DEFINE_INSTANCED_PROP(float, _Metallic)
        UNITY_DEFINE_INSTANCED_PROP(float, _Occlusion)
        UNITY_DEFINE_INSTANCED_PROP(float, _Smoothness)
        UNITY_DEFINE_INSTANCED_PROP(float, _Color)
        UNITY_DEFINE_INSTANCED_PROP(float, _Fresnel)
        UNITY_DEFINE_INSTANCED_PROP(float, _DetailAlbedo)
        UNITY_DEFINE_INSTANCED_PROP(float, _DetailSmoothness)
        UNITY_DEFINE_INSTANCED_PROP(float, _DetailNormalScale)
        UNITY_DEFINE_INSTANCED_PROP(float, _NormalScale)
    UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

    struct InputConfig 
    {
	    float2 uv_base;
	    float2 uv_detail;
        bool useMask;
        bool useDetail;
    };

    InputConfig GetInputConfig (float2 uv_base, float2 uv_detail = 0.0) 
    {
	    InputConfig c;
	    c.uv_base = uv_base;
	    c.uv_detail = uv_detail;
        c.useMask = false;
        c.useDetail = false;
	    return c;
    }

    float2 TransformBaseUV (float2 baseUV) 
    {
	    float4 baseST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseMap_ST);
	    return baseUV * baseST.xy + baseST.zw;
    }

    float2 TransformDetailUV (float2 detailUV) 
    {
	    float4 detailST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _DetailMap_ST);
	    return detailUV * detailST.xy + detailST.zw;
    }

    float4 GetMask (InputConfig c) 
    {   
        if (c.useMask)
	        return SAMPLE_TEXTURE2D(_MaskMap, sampler_BaseMap, c.uv_base);
        else 
            return 1.0f;
    }

    float4 GetDetail (InputConfig c) 
    {   
        if (c.useDetail)
        {
        	float4 map = SAMPLE_TEXTURE2D(_DetailMap, sampler_DetailMap, c.uv_detail);
	        return map * 2.0 - 1.0;
        }

        return 0.0;

    }

    float4 GetBaseColor (InputConfig c) 
    {
	    float4 map = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, c.uv_base);
	    float4 color = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);

        if (c.useDetail) 
        { 
            float detail = GetDetail(c).r * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _DetailAlbedo);
            float mask = GetMask(c).b;
            map.rgb = lerp(sqrt(map.rgb), detail < 0.0 ? 0.0 : 1.0, abs(detail) * mask);
            map.rgb *= map.rgb;
        }

	    return map * color;
    }

    float GetCutoff (float2 baseUV) 
    {
	    return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff);
    }

    float GetMetallic (InputConfig c) 
    {
	    float metallic = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Metallic);
	    metallic *= GetMask(c).r;
	    return metallic;
    }

    float GetSmoothness (InputConfig c) 
    {   
        float smoothness = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Smoothness);
        smoothness *= GetMask(c).a;

        if (c.useDetail) 
        { 
            float detail = GetDetail(c).b * UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _DetailSmoothness);
	        float mask = GetMask(c).b;
	        smoothness = lerp(smoothness, detail < 0.0 ? 0.0 : 1.0, abs(detail) * mask);
        }

	    return smoothness;
    }

    float3 GetEmission (InputConfig c)
    {
	    float4 map = SAMPLE_TEXTURE2D(_EmissionMap, sampler_BaseMap, c.uv_base);
	    float4 color = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _EmissionColor);
	    return map.rgb * color.rgb;
    }

    float GetFresnel (float2 baseUV) 
    {
	    return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Fresnel);
    }

    float GetOcclusion (InputConfig c) 
    {   
        float strength = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Occlusion);
        float occlusion = GetMask(c).g;
        occlusion = lerp(1.0f, occlusion, strength);
	    return occlusion;
    }

    float3 GetNormalTS (InputConfig c) 
    {
	    float4 map = SAMPLE_TEXTURE2D(_NormalMap, sampler_BaseMap, c.uv_base);
	    float scale = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _NormalScale);
	    float3 normal = DecodeNormal(map, scale);

        if (c.useDetail) 
        {
            map = SAMPLE_TEXTURE2D(_DetailNormalMap, sampler_DetailMap, c.uv_detail);
	        scale = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _DetailNormalScale) * GetMask(c).b;
	        float3 detail = DecodeNormal(map, scale);
	        normal = BlendNormalRNM(normal, detail);
        }

	    return normal;
    }

    float3 NormalTangentToWorld (float3 normalTS, float3 normalWS, float4 tangentWS) 
    {
	    float3x3 tangentToWorld = CreateTangentToWorld(normalWS, tangentWS.xyz, tangentWS.w);
	    return TransformTangentToWorld(normalTS, tangentToWorld);
    }

#endif 