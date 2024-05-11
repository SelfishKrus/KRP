#ifndef KRP_LIGHT_INCLUDED
#define KRP_LIGHT_INCLUDED

    #include "KRP_Shadows.hlsl"

    #define MAX_DIRECTIONAL_LIGHT_COUNT 4
    #define MAX_OTHER_LIGHT_COUNT 64

    // _K_Light
    CBUFFER_START(KRP_Light)
        int _DL_Count;
        float3 _DL_Colors[MAX_DIRECTIONAL_LIGHT_COUNT];
        float3 _DL_Directions[MAX_DIRECTIONAL_LIGHT_COUNT];
        float4 _DL_ShadowData[MAX_DIRECTIONAL_LIGHT_COUNT];

        int _OL_Count;
	    float4 _OL_Colors[MAX_OTHER_LIGHT_COUNT];
	    float4 _OL_Positions[MAX_OTHER_LIGHT_COUNT];
        float4 _OL_Directions[MAX_OTHER_LIGHT_COUNT];
        float4 _OL_SpotAngles[MAX_OTHER_LIGHT_COUNT];
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
        data.strength = _DL_ShadowData[lightIndex].x;
        data.tileIndex = _DL_ShadowData[lightIndex].y + shadowData.cascadeIndex;
        data.normalBias = _DL_ShadowData[lightIndex].z;
        data.shadowMaskChannel = _DL_ShadowData[lightIndex].w;
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

    // Other Light 
    Light GetOtherLight (int index, Surface surfaceWS, ShadowData shadowData) 
    {
	    Light light;
	    light.color = _OL_Colors[index].rgb;

	    float3 ray = _OL_Positions[index].xyz - surfaceWS.position;
	    light.direction = normalize(ray);

        float distanceSqr = max(dot(ray, ray), 0.00001);
        float rangeAttenuation = Square(saturate(1.0 - Square(distanceSqr * _OL_Positions[index].w)));
        float4 spotAngles = _OL_SpotAngles[index];
        float spotAttenuation = Square(
		    saturate(dot(_OL_Directions[index].xyz, light.direction) *
		    spotAngles.x + spotAngles.y));
	    light.attenuation = spotAttenuation * rangeAttenuation / distanceSqr;

	    return light;
    }

    int GetOtherLightCount () 
    {
	    return _OL_Count;
    }

#endif