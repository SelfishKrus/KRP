#ifndef KRP_LIGHT_INCLUDED
#define KRP_LIGHT_INCLUDED

    #define MAX_DIRENCTIONAL_LIGHT_COUNT 4

    CBUFFER_START(CB_Light)
        int _DirectionalLightCount;
        float4 _DirectionalLightColors[MAX_DIRENCTIONAL_LIGHT_COUNT];
        float4 _DirectionalLightDirections[MAX_DIRENCTIONAL_LIGHT_COUNT];
    CBUFFER_END

    struct Light {
        half3 color;
        half3 direction;
    };

    int GetDirectionalLightCount () {
        return _DirectionalLightCount;
    }

    Light GetDirectionalLight (int index) {
        Light light;
        light.color = _DirectionalLightColors[index].rgb;
        light.direction = _DirectionalLightDirections[index].xyz;
        return light;
    }

#endif