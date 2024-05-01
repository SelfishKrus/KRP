#ifndef KRP_BRDF_INCLUDED
#define KRP_BRDF_INCLUDED

	struct BRDF
	{
		float3 diffuse;
		float3 specular;
		float roughness;
		float perceptualRoughness;
	};

	#define DIELECTRIC_F0 0.04

	float PerceptualSmoothnessToPerceptualRoughness_KRP(float perceptualSmoothness)
	{
		return (1.0 - perceptualSmoothness);
	}

	float PerceptualRoughnessToRoughness_KRP(float perceptualRoughness)
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

	float OneMinusReflectivity (float metallic) 
	{
		float range = 1.0 - DIELECTRIC_F0;
		return range - metallic * range;
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

	BRDF GetBRDF (Surface surface) 
	{
		BRDF brdf;
		float oneMinusReflectivity = OneMinusReflectivity(surface.metallic);

		brdf.perceptualRoughness = PerceptualSmoothnessToPerceptualRoughness_KRP(surface.smoothness);
		brdf.roughness = PerceptualRoughnessToRoughness_KRP(brdf.perceptualRoughness);

		brdf.diffuse = surface.color * oneMinusReflectivity;
		#ifdef _PREMULTIPLY_ALPHA
			brdf.diffuse *= surface.alpha;
		#endif
		brdf.specular = lerp(DIELECTRIC_F0, surface.color, surface.metallic);
		return brdf;
	}

	float3 IndirectBRDF (Surface surface, BRDF brdf, float3 diffuse, float3 specular) 
	{	
		float3 reflection = specular * brdf.specular;
		reflection /= brdf.roughness * brdf.roughness + 1.0;
		return diffuse * brdf.diffuse + reflection;
	}

#endif 