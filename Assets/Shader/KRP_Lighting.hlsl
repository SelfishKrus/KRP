#ifndef KRP_LIGHTING_INCLUDED
#define KRP_LIGHTING_INCLUDED

    half3 IncomingLight (Surface surface, Light light) {
        return saturate(dot(surface.normal, light.direction)) * light.color;
    }
    
    half3 GetLighting (Surface surface, BRDF brdf, Light light) {
        return IncomingLight(surface, light) * brdf.diffuse;
    }

    half3 GetLighting (Surface surface, BRDF brdf) {
        half3 color = 0;
        for (int i = 0; i < GetDirectionalLightCount(); i++) {
            color += GetLighting(surface, brdf, GetDirectionalLight(i));
        }
        return color;
    }



#endif