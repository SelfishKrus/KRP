#ifndef K_SHADOWS_INCLUDED
#define K_SHADOWS_INCLUDED

#define MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT 4
#define MAX_CASCADE_COUNT 4

TEXTURE2D_SHADOW(_DL_ShadowAtlas);
#define SHADOW_SAMPLER sampler_linear_clamp_compare
SAMPLER_CMP(SHADOW_SAMPLER);

CBUFFER_START(_K_Shadows)
    int _CascadeCount;
    float4 _CascadeCullingSpheres[MAX_CASCADE_COUNT];
    float4x4 _DL_ShadowMatrices[MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT * MAX_CASCADE_COUNT];
CBUFFER_END

struct DL_ShadowData
{
    float strength;
    int tileIndex;
};

float SampleDirectionalShadowAtlas(float3 posSTS)
{
    return SAMPLE_TEXTURE2D_SHADOW(_DL_ShadowAtlas, SHADOW_SAMPLER, posSTS);
}

float GetDirectionalShadowAttenuation (DL_ShadowData data, Surface surfaceWS)
{   
    if (data.strength <= 0.0)
    {
        return 1.0;
    }
    float3 posSTS = mul(_DL_ShadowMatrices[data.tileIndex], float4(surfaceWS.position, 1.0f)).xyz;
    float shadow = SampleDirectionalShadowAtlas(posSTS);
    return lerp(1.0, shadow, data.strength);
}

struct ShadowData
{
    int cascadeIndex;
    float strength;
};

ShadowData GetShadowData (Surface surfaceWS)
{
    ShadowData data;
    data.strength = 1.0;
    int i;
    for (i = 0; i < _CascadeCount; i++)
    {
        float4 sphere = _CascadeCullingSpheres[i];
        float distanceSqr = DistanceSquared(surfaceWS.position, sphere.xyz);
        if (distanceSqr < sphere.w)
        {
            break;
        }
    }

    if (i == _CascadeCount)
    {
        data.strength = 0.0;
    }

    data.cascadeIndex = i;
    return data;
}

#endif 