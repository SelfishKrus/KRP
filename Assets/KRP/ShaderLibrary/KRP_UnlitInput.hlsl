#ifndef KRP_UNLIT_INPUT_INCLUDED
#define KRP_UNLIT_INPUT_INCLUDED

    TEXTURE2D(_BaseMap);    SAMPLER(sampler_BaseMap);
    TEXTURE2D(_MainTex);

    UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
        UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
        UNITY_DEFINE_INSTANCED_PROP(float4, _BaseColor)
        UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
        UNITY_DEFINE_INSTANCED_PROP(float4, _Color)
    UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

    struct InputConfig 
    {
	    float2 uv_base;
	    float2 uv_detail;
    };

    InputConfig GetInputConfig (float2 uv_base, float2 uv_detail = 0.0) 
    {
	    InputConfig c;
	    c.uv_base = uv_base;
	    c.uv_detail = uv_detail;
	    return c;
    }

    float2 TransformBaseUV (float2 baseUV) 
    {
	    float4 baseST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseMap_ST);
	    return baseUV * baseST.xy + baseST.zw;
    }

    float4 GetBaseColor (InputConfig c) 
    {
	    float4 map = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, c.uv_base);
	    float4 color = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseColor);
	    return map * color;
    }

    float GetCutoff (float2 baseUV) 
    {
	    return UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff);
    }

    float GetMetallic (InputConfig c) 
    {
	    return 0;
    }

    float GetSmoothness (InputConfig c) 
    {
	    return 0;
    }

    float3 GetEmission (InputConfig c) 
    {
	    return GetBaseColor(c).rgb;
    }

    // dummy function to avoid error
    float GetFresnel (float2 baseUV) 
    {
	    return 0.0;
    }

#endif 