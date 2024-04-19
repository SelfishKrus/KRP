#ifndef KRP_LIGHT_INCLUDED
#define KRP_LIGHT_INCLUDED

    #include "KRP_Shadows.hlsl"

    #define MAX_DIRECTIONAL_LIGHT_COUNT 4

    // _K_Light
    CBUFFER_START(KRP_Light)
        int _DL_Count;
        float3 _DL_Colors[MAX_DIRECTIONAL_LIGHT_COUNT];
        float3 _DL_Directions[MAX_DIRECTIONAL_LIGHT_COUNT];
        float4 _DL_ShadowData[MAX_DIRECTIONAL_LIGHT_COUNT];
    CBUFFER_END

    struct Light 
    {
        float3 color;
        float3 direction;
        float attenuation;
    };

    DirectionalShadowData GetDirectionalShadowData (int lightIndex, ShadowData shadowData)
    {
        DirectionalShadowData data;
        data.strength = _DL_ShadowData[lightIndex].x * shadowData.strength;
        data.tileIndex = _DL_ShadowData[lightIndex].y + shadowData.cascadeIndex;
        data.normalBias = _DL_ShadowData[lightIndex].z;
        return data;
    }

    Light GetDirectionalLight(int index, Surface surfaceWS, ShadowData shadowData)
    {
        Light light;
        light.color = _DL_Colors[index].rgb;
        light.direction = _DL_Directions[index].xyz;
        DirectionalShadowData dirShadowData = GetDirectionalShadowData(index, shadowData);
        light.attenuation = GetDirectionalShadowAttenuation(dirShadowData, shadowData, surfaceWS);
        //light.attenuation = shadowData.cascadeIndex * 0.25f;
        return light;
    }

    int GetDirectionalLightCount()
    {
        return _DL_Count;
    }



#endif