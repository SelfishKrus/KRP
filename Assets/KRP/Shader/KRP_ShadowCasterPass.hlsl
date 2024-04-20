#ifndef KRP_SHADOW_CASTER_PASS_INCLUDED
#define KRP_SHADOW_CASTER_PASS_INCLUDED

    #include "KRP_Common.hlsl"

    TEXTURE2D(_BaseMap);    SAMPLER(sampler_BaseMap);

    UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)
        UNITY_DEFINE_INSTANCED_PROP(float4, _BaseMap_ST)
        UNITY_DEFINE_INSTANCED_PROP(float4, _BaseCol)
        UNITY_DEFINE_INSTANCED_PROP(float, _Cutoff)
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
        float2 uv : VAR_UV;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    Varyings ShadowCasterPassVertex (Attributes i)
    {   
        Varyings o;
        UNITY_SETUP_INSTANCE_ID(i);
        UNITY_TRANSFER_INSTANCE_ID(i, o);
        float3 posWS = TransformObjectToWorld(i.posOS.xyz);
        o.posCS = TransformWorldToHClip(posWS.xyz);

        #if UNITY_REVERSED_Z
		    o.posCS.z =
			    min(o.posCS.z, o.posCS.w * UNITY_NEAR_CLIP_VALUE);
	    #else
		    output.posCS.z =
			    max(o.posCS.z, o.posCS.w * UNITY_NEAR_CLIP_VALUE);
	    #endif

        float4 baseMapST = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseMap_ST);
        o.uv = i.uv * baseMapST.xy + baseMapST.zw;
        return o;
    }

    void ShadowCasterPassFragment (Varyings i)
    {   
        UNITY_SETUP_INSTANCE_ID(i);

        half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
        half3 baseCol = UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _BaseCol).rgb;
        half3 col = baseCol * baseMap.rgb;

        #ifdef _SHADOWS_CLIP
            clip(baseMap.a - UNITY_ACCESS_INSTANCED_PROP(UnityPerMaterial, _Cutoff));
        #elif defined(_SHADOWS_DITHER)
            float dither = InterleavedGradientNoise(i.posCS.xy, 0);
            clip(baseMap.a - dither);
        #endif
    }

#endif 