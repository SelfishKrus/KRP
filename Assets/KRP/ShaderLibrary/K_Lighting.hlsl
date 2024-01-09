#ifndef K_LIGHTING_INCLUDED
#define K_LIGHTING_INCLUDED

    #include "K_Surface.hlsl"
    #include "K_Light.hlsl"
    #include "K_BRDF.hlsl"

    float3 IncomingLighting (Surface surface, Light light)
    {
        return max(0.00001, dot(surface.normal, light.direction)) * light.color * light.attenuation;
    }

    float3 GetLighting (Surface surface, Light light)
    {   
        BRDF brdf = GetBRDF_DL(surface, light);
        return IncomingLighting(surface, light) * (brdf.diffuse + brdf.specular);
    }

    float3 GetLighting (Surface surfaceWS)
    {   
        ShadowData shadowData = GetShadowData(surfaceWS);
        float3 color = 0.0;
        for (int i = 0; i < GetDirectionalLightCount(); i++)
        {   
            Light light = GetDirectionalLight(i, surfaceWS, shadowData);
            color += GetLighting(surfaceWS, GetDirectionalLight(i, surfaceWS, shadowData));
        }
        return color;
    }

#endif