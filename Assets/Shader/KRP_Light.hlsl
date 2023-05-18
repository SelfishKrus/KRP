#ifndef KRP_LIGHT_INCLUDED
#define KRP_LIGHT_INCLUDED

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

    #define MAX_DIRENCTIONAL_LIGHT_COUNT 4

    CBUFFER_START(CB_Light)
        int _DirectionalLightCount;
        float4 _DirectionalLightColors[MAX_DIRENCTIONAL_LIGHT_COUNT];
        float4 _DirectionalLightDirections[MAX_DIRENCTIONAL_LIGHT_COUNT];
    CBUFFER_END

    struct DirectionalLight {
        half3 color;
        half3 direction;
    };

    int GetDirectionalLightCount () {
        return _DirectionalLightCount;
    }

    DirectionalLight GetDirectionalLight (int index) {
        DirectionalLight light;
        light.color = _DirectionalLightColors[index].rgb;
        light.direction = _DirectionalLightDirections[index].xyz;
        return light;
    }

    // IBL //
    half3 GetIBL(half3 normalWS, half3 viewDir, half roughness)
    {
        half3 reflectViewDir = reflect(-viewDir, normalWS);
        // curve fitting
        roughness = roughness * (1.7 - 0.7 * roughness);
        // sample the cubemap at different mip levels based on roughness
        half3 mipLevel = roughness * 6;
        half4 specCol = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, samplerunity_SpecCube0, reflectViewDir, mipLevel);
        
        #if !defined(UNITY_USE_NATIVE_HDR)
        return DecodeHDREnvironment(specCol, unity_SpecCube0_HDR);
        #else 
        return specCol.xyz;
        #endif
    }

#endif