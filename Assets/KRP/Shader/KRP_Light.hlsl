#ifndef KRP_LIGHT_INCLUDED
#define KRP_LIGHT_INCLUDED


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

    DirectionalShadowData GetDirectionalShadowData (int lightIndex)
    {
        DirectionalShadowData data;
        data.strength = _DL_ShadowData[lightIndex].x;
        data.tileIndex = _DL_ShadowData[lightIndex].y;
        return data;
    }

    Light GetDirectionalLight(int index, Surface surfaceWS)
    {
        Light light;
        light.color = _DL_Colors[index].rgb;
        light.direction = _DL_Directions[index].xyz;
        DirectionalShadowData shadowData = GetDirectionalShadowData(index);
        light.attenuation = GetDirectionalShadowAttenuation(shadowData, surfaceWS);
        return light;
    }

    int GetDirectionalLightCount()
    {
        return _DL_Count;
    }



#endif