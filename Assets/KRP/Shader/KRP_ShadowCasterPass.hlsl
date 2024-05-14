#ifndef KRP_SHADOW_CASTER_PASS_INCLUDED
#define KRP_SHADOW_CASTER_PASS_INCLUDED

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

    bool _ShadowPancaking;

    Varyings ShadowCasterPassVertex (Attributes i)
    {   
        Varyings o;
        UNITY_SETUP_INSTANCE_ID(i);
        UNITY_TRANSFER_INSTANCE_ID(i, o);
        float3 posWS = TransformObjectToWorld(i.posOS.xyz);
        o.posCS = TransformWorldToHClip(posWS.xyz);

        if (_ShadowPancaking)
        { 
        #if UNITY_REVERSED_Z
		    o.posCS.z =
			    min(o.posCS.z, o.posCS.w * UNITY_NEAR_CLIP_VALUE);
	    #else
		    output.posCS.z =
			    max(o.posCS.z, o.posCS.w * UNITY_NEAR_CLIP_VALUE);
	    #endif
        }

        o.uv = TransformBaseUV(i.uv);
        return o;
    }

    void ShadowCasterPassFragment (Varyings i)
    {   
        UNITY_SETUP_INSTANCE_ID(i);

        ClipLOD(i.posCS.xy, unity_LODFade.x);

        InputConfig config = GetInputConfig(i.uv);
        half4 baseCol = GetBaseColor(config);

        #ifdef _SHADOWS_CLIP
            clip(baseCol.a - GetCutoff(i.uv));
        #elif defined(_SHADOWS_DITHER)
            float dither = InterleavedGradientNoise(i.posCS.xy, 0);
            clip(baseCol.a - dither);
        #endif
    }

#endif 