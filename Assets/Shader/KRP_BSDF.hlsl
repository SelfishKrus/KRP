#ifndef KRP_BSDF_INCLUDED
#define KRP_BSDF_INCLUDED

    // === PBR ITEMS === // 
    // NDF - GGX //
    half GetD_GGX(half nh, half roughness) 
    {
        half a2 = roughness * roughness;
        half nh2 = nh * nh;
        half nom = a2;
        half denom = nh2 * (a2 - 1) + 1;
        denom = denom * denom * PI;
        return nom / denom;
    }

    // Geometry Function - Schlick-GGX //
    half GetG_SlkGGX(half nv, half nl, half roughness)
    {
        half k = pow(roughness+1, 2) * 0.125;
        half G_in = nl / lerp(nl, 1, k);
        half G_out = nv / lerp(nv, 1, k);
        return G_in * G_out;
    }
    
    // Fresnel_direct_light - UE Schilick //
    // cosTheta = hv or nv
    half3 GetF_Slk(half3 F0, half cosTheta)
    {
        half Fre = exp2((-5.55473*cosTheta - 6.98316) * cosTheta);
        return lerp(Fre, 1, F0);
    }

    // Fresnel - Sébastien Lagarde //
    // cosTheta = hv or nv
    half3 GetF_SL(half3 F0, half cosTheta, half roughness)
    {
        return F0 + (max(half3(1.0 - roughness, 1.0 - roughness, 1.0 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
    }



    // === BRDF === //
    half3 GetBRDF_CookTorrance(PbrSurface pbrSurface, PbrVectors pbrVectors, half3 F) {
        half D = GetD_GGX(pbrVectors.nh, pbrSurface.roughness);
        half G = GetG_SlkGGX(pbrVectors.nv, pbrVectors.nl, pbrSurface.roughness);
        half3 BRDF_CookTorrance = D * G * F / ( 4*pbrVectors.nv*pbrVectors.nl );
        return BRDF_CookTorrance;
    }


    // approximate BRDF - indirect light - specular
    // unity fitting curve instead of UE LUT
    half3 GetEnvBRDF_CookTorrance(PbrSurface pbrSurface, PbrVectors pbrVectors, half3 BRDF_spec)
    {
        #ifdef UNITY_COLORSPACE_GAMMA
        half SurReduction = 1-0.28*pbrSurface.roughness;
        #else
        half SurReduction = 1 / (pbrSurface.roughness*pbrSurface.roughness+1);
        #endif

        #if defined(SHADER_API_GLES)
        half Reflectivity = BRDF_spec.x;
        #else
        half Reflectivity = max(max(BRDF_spec.x,BRDF_spec.y),BRDF_spec.z);
        #endif

        half GrazingTSection = saturate(Reflectivity + pbrSurface.smoothness);
        half Fre = Pow4(1-pbrVectors.nv);

        return lerp(pbrSurface.F0,GrazingTSection,Fre)*SurReduction;
    }

    // Specular BRDF - Kelemen/Szirmay-Kalos // 
    half3  GetBRDF_KS(PbrSurface pbrSurface, PbrVectors pbrVectors, sampler2D _LUT_BeckmannNDF) {
        // NDF - Beckmann
        half2 uvBeckmannNDF = {pbrVectors.nh, pbrSurface.roughness};
        half D = pow(2 * max(tex2D(_LUT_BeckmannNDF, uvBeckmannNDF).r, 0), 10);
        half3 F = GetF_SL(pbrVectors.hv, pbrSurface.F0, pbrSurface.roughness);
        half3 BRDF_KS = D * F / ( 4 * dot(pbrVectors.h, pbrVectors.h));
        // BRDF_KS = D * F.r / ( 4 * lh * lh);

        return BRDF_KS;
    }

#endif