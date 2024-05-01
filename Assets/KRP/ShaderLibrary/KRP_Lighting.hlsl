#ifndef KRP_LIGHTING_INCLUDED
#define KRP_LIGHTING_INCLUDED

    #include "KRP_Surface.hlsl"
    #include "KRP_Light.hlsl"
    #include "KRP_BRDF.hlsl"
    #include "KRP_GI.hlsl"

    float3 IncomingLighting (Surface surface, Light light)
    {
        return max(0.00001, dot(surface.normal, light.direction) * light.attenuation) * light.color;
    }

    float3 GetLighting (Surface surface, Light light, BRDF brdf)
    {   
        return IncomingLighting(surface, light) * (brdf.diffuse + brdf.specular);
    }

    float3 GetLighting (Surface surfaceWS, GI gi, BRDF brdf)
    {   
        ShadowData shadowData = GetShadowData(surfaceWS);
        shadowData.shadowMask = gi.shadowMask;
        float3 color = IndirectBRDF(surfaceWS, brdf, gi.diffuse, gi.specular);
        for (int i = 0; i < GetDirectionalLightCount(); i++)
        {   
            Light light = GetDirectionalLight(i, surfaceWS, shadowData);
            color += GetLighting(surfaceWS, light, brdf);
        }
        return color;
    }

#endif