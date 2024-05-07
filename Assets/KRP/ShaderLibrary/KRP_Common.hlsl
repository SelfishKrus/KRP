#ifndef KRP_COMMON_INCLUDED
#define KRP_COMMON_INCLUDED

    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"
    #include "KRP_UnityInput.hlsl"

    #define UNITY_MATRIX_M unity_ObjectToWorld
    #define UNITY_MATRIX_I_M unity_WorldToObject
    #define UNITY_MATRIX_V unity_MatrixV
    #define UNITY_MATRIX_I_V unity_MatrixInvV
    #define UNITY_MATRIX_VP unity_MatrixVP
    #define UNITY_PREV_MATRIX_M unity_prev_MatrixM
    #define UNITY_PREV_MATRIX_I_M unity_prev_MatrixIM
    #define UNITY_MATRIX_P glstate_matrix_projection

    #if defined(_SHADOW_MASK_ALWAYS) || defined(_SHADOW_MASK_DISTANCE)
        #define SHADOWS_SHADOWMASK
    #endif 

    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"

    float Square(float v)
    {
        return v * v;
    }

    float DistanceSquared(float3 pA, float3 pB) 
    {
	    return dot(pA - pB, pA - pB);
    }

    void ClipLOD (float2 posCS, float fade) 
    {
	    #if defined(LOD_FADE_CROSSFADE)
		    float dither = InterleavedGradientNoise(posCS.xy, 0);
            // take account of negated case
		    clip(fade + (fade < 0.0 ? dither : -dither));
	    #endif
    }

    float3 DecodeNormal (float4 sample, float scale) 
    {
	    #if defined(UNITY_NO_DXT5nm)
	        return normalize(UnpackNormalRGB(sample, scale));
	    #else
	        return normalize(UnpackNormalmapRGorAG(sample, scale));
	    #endif
    }

#endif