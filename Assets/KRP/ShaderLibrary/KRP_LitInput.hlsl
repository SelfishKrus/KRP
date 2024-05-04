#ifndef KRP_LIT_INPUT_INCLUDED
#define KRP_LIT_INPUT_INCLUDED

    TEXTURE2D(_BaseMap);        SAMPLER(sampler_BaseMap);
    TEXTURE2D(_EmissionMap);
    TEXTURE2D(_MainTex);
    TEXTURE2D(_MaskMap);

    UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
        UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
        UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
        UNITY_DEFINE_INSTANCED_PROP(float4, _EmissionColor)
        UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
        UNITY_DEFINE_INSTANCED_PROP(float, _Metallic)
        UNITY_DEFINE_INSTANCED_PROP(float, _Occlusion)
        UNITY_DEFINE_INSTANCED_PROP(float, _Smoothness)
        UNITY_DEFINE_INSTANCED_PROP(float, _Color)
        UNITY_DEFINE_INSTANCED_PROP(float, _Fresnel)
    UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

    float2 TransformBaseUV (float2 baseUV) 
    {
	    float4 baseST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseMap_ST);
	    return baseUV * baseST.xy + baseST.zw;
    }

    float4 GetMask (float2 baseUV) 
    {
	    return SAMPLE_TEXTURE2D(_MaskMap, sampler_BaseMap, baseUV);
    }

    float4 GetBaseColor (float2 baseUV) 
    {
	    float4 map = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, baseUV);
	    float4 color = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);
	    return map * color;
    }

    float GetCutoff (float2 baseUV) 
    {
	    return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff);
    }

    float GetMetallic (float2 baseUV) 
    {
	    float metallic = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Metallic);
	    metallic *= GetMask(baseUV).r;
	    return metallic;
    }

    float GetSmoothness (float2 baseUV) 
    {   
        float smoothness = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Smoothness);
        smoothness *= GetMask(baseUV).a;
	    return smoothness;
    }

    float3 GetEmission (float2 baseUV)
    {
	    float4 map = SAMPLE_TEXTURE2D(_EmissionMap, sampler_BaseMap, baseUV);
	    float4 color = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _EmissionColor);
	    return map.rgb * color.rgb;
    }

    float GetFresnel (float2 baseUV) 
    {
	    return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Fresnel);
    }

    float GetOcclusion (float2 baseUV) 
    {   
        float strength = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Occlusion);
        float occlusion = GetMask(baseUV).g;
        occlusion = lerp(1.0f, occlusion, strength);
	    return occlusion;
    }

#endif 