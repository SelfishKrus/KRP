#ifndef KRP_BRDF_INCLUDED
#define KRP_BRDF_INCLUDED

    struct BRDF {
        half3 diffuse;
        half3 specular;
        half roughness;
    };

    BRDF GetBRDF (Surface surface) {
        BRDF brdf;
        brdf.diffuse = surface.color;
        brdf.specular = 0.0;
        brdf.roughness = 1.0;
        return brdf;
    }

#endif