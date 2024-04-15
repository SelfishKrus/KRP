#ifndef KRP_LIGHT_INCLUDED
#define KRP_LIGHT_INCLUDED

#define MAX_DIRECTIONAL_LIGHT_COUNT 4

CBUFFER_START(_K_Light)
    int _DL_Count;
    float3 _DL_Colors[MAX_DIRECTIONAL_LIGHT_COUNT];
    float3 _DL_Directions[MAX_DIRECTIONAL_LIGHT_COUNT];
CBUFFER_END

struct Light 
{
    float3 color;
    float3 direction;
};

Light GetDirectionalLight(int index)
{
    Light light;
    light.color = _DL_Colors[index].rgb;
    light.direction = _DL_Directions[index].xyz;
    return light;
}

int GetDirectionalLightCount()
{
    return _DL_Count;
}

#endif