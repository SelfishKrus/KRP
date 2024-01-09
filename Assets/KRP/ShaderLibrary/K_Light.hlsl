#ifndef K_LIGHT_INCLUDED
#define K_LIGHT_INCLUDED

// #include "K_Shadows.hlsl"

#define MAX_DIRECTIONAL_LIGHT_COUNT 4

CBUFFER_START(_K_Light)
    int _DL_Count;
    float3 _DL_Colors[MAX_DIRECTIONAL_LIGHT_COUNT];
    float3 _DL_Directions[MAX_DIRECTIONAL_LIGHT_COUNT];
    float3 _DL_ShadowData[MAX_DIRECTIONAL_LIGHT_COUNT];
CBUFFER_END

struct Light 
{
    float3 color;
    float3 direction;
    float attenuation;
};

DL_ShadowData GetDirectionalShadowData(int lightIndex, ShadowData shadowData)
{
    DL_ShadowData data;
    data.strength = _DL_ShadowData[lightIndex].x * shadowData.strength;
    data.tileIndex = _DL_ShadowData[lightIndex].y + shadowData.cascadeIndex;
    return data;
}

Light GetDirectionalLight(int index, Surface surfaceWS, ShadowData shadowData)
{
    Light light;
    light.color = _DL_Colors[index].rgb;
    light.direction = _DL_Directions[index].xyz;
    DL_ShadowData dl_shadowData = GetDirectionalShadowData(index, shadowData);
    light.attenuation = GetDirectionalShadowAttenuation(dl_shadowData, surfaceWS);
    return light;
}

int GetDirectionalLightCount()
{
    return _DL_Count;
}

#endif