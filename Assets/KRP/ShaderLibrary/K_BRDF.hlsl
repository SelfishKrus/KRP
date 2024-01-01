#ifndef K_BRDF_INCLUDED
#define K_BRDF_INCLUDED

	struct BRDF
	{
		float3 diffuse;
		float3 specular;
		float roughness;
	};

	#define DIELECTRIC_F0 0.04

	float PerceptualSmoothnessToPerceptualRoughness(float perceptualSmoothness)
	{
		return (1.0 - perceptualSmoothness);
	}

	float PerceptualRoughnessToRoughness(float perceptualRoughness)
	{
		return perceptualRoughness * perceptualRoughness;
	}

	// NDF - GGX
	float NDF_GGX(float NoH, float roughness) 
    {
        half a2 = roughness * roughness;
        half NoH2 = NoH * NoH;
        half nom = a2;
        half denom = NoH2 * (a2 - 1) + 1;
        denom = denom * denom * PI;
        return nom / denom;
    }

	// Fresnel - UE Schilick 
	float3 Fresnel_Slk(float F0, float cosTheta)
    {
        float Fre = exp2((-5.55473 * cosTheta - 6.98316) * cosTheta);
        return lerp(Fre, 1, F0);
    }

	// Fresnel - Sébastien Lagarde
    float3 Fresnel_SL(float cosTheta, float3 F0, float roughness)
    {
        return F0 + (max(float3(1.0 - roughness, 1.0 - roughness, 1.0 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
    }

	// Geometry - Schlick-GGX
	float Geometry_SlkGGX(float NoV, float NoL, float roughness)
	{
		float k = pow(roughness+1, 2) * 0.125;
		float G_in = NoL / lerp(NoL, 1, k);
		float G_out = NoV / lerp(NoV, 1, k);
		return G_in * G_out;
	}

	BRDF GetBRDF_DL (Surface surface, Light light) 
	{
		BRDF brdf;
		float perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness(surface.smoothness);
		brdf.roughness = PerceptualRoughnessToRoughness(perceptualRoughness);
		float3 H = normalize(light.direction + surface.viewDirection);
		float HoV = max(0.00001, dot(H, surface.viewDirection));
		float NoH = max(0.00001, dot(surface.normal, H));
		float NoV = max(0.00001, dot(surface.normal, surface.viewDirection));
		float NoL = max(0.00001, dot(surface.normal, light.direction));

		float3 F0 = lerp(DIELECTRIC_F0, surface.color, surface.metallic);
		float3 fresnel = Fresnel_SL(HoV, F0, brdf.roughness);
		float NDF = NDF_GGX(NoH, brdf.roughness);
		float G = Geometry_SlkGGX(NoV, NoL, brdf.roughness);

		brdf.diffuse = (1.0 - fresnel) * surface.color;
		#ifdef _PREMULTIPLY_ALPHA
			brdf.diffuse *= surface.alpha;
		#endif
		brdf.specular = NDF * fresnel * G / (4.0 * NoV * NoL);
		return brdf;
	}

#endif 