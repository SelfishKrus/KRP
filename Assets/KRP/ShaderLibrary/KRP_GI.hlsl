#ifndef KRP_GI_INCLUDED
#define KRP_GI_INCLUDED

    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"
	#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/ImageBasedLighting.hlsl"
	#include "KRP_Surface.hlsl"
	#include "KRP_Shadows.hlsl"

    TEXTURE2D(unity_Lightmap);  
    SAMPLER(sampler_unity_Lightmap);

	TEXTURE2D(unity_ShadowMask);
	SAMPLER(sampler_unity_ShadowMask);

	TEXTURE3D_FLOAT(unity_ProbeVolumeSH);
	SAMPLER(sampler_unity_ProbeVolumeSH);

	TEXTURECUBE(unity_SpecCube0);
	SAMPLER(sampler_unity_SpecCube0);

    #ifdef LIGHTMAP_ON
	    #define GI_ATTRIBUTE_DATA float2 uv_lightmap : TEXCOORD1;
	    #define GI_VARYINGS_DATA float2 uv_lightmap : VAR_LIGHT_MAP_UV;
	    #define TRANSFER_GI_DATA(i, o) o.uv_lightmap = i.uv_lightmap * unity_LightmapST.xy + unity_LightmapST.zw;
	    #define GI_FRAGMENT_DATA(i) i.uv_lightmap 
    #else
        #define GI_ATTRIBUTE_DATA
        #define GI_VARYINGS_DATA
        #define TRANSFER_GI_DATA(i, o)
        #define GI_FRAGMENT_DATA(i) 0.0
    #endif 

	float4 SampleBakedShadows (float2 uv_lightmap, Surface surfaceWS) 
	{
		#ifdef LIGHTMAP_ON
			return SAMPLE_TEXTURE2D(
				unity_ShadowMask, sampler_unity_ShadowMask, uv_lightmap
			);
		#else
			if (unity_ProbeVolumeParams.x) 
			{
				return SampleProbeOcclusion(
					TEXTURE3D_ARGS(unity_ProbeVolumeSH, sampler_unity_ProbeVolumeSH),
					surfaceWS.position, unity_ProbeVolumeWorldToObject,
					unity_ProbeVolumeParams.y, unity_ProbeVolumeParams.z,
					unity_ProbeVolumeMin.xyz, unity_ProbeVolumeSizeInv.xyz
				);
			}
			else 
			{
				return unity_ProbesOcclusion;
			}
		#endif
	}

    float3 SampleLightMap (float2 uv_lightmap) 
    {
	    #ifdef LIGHTMAP_ON
		    return SampleSingleLightmap(
                TEXTURE2D_ARGS(unity_Lightmap, sampler_unity_Lightmap),
                uv_lightmap,
                float4(1.0, 1.0, 0.0, 0.0),
                #ifdef UNITY_LIGHTMAP_FULL_HDR
			        false,
		        #else
			        true,
		        #endif
                float4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0.0, 0.0)
                );
	    #else
		    return 0.0;
	    #endif
    }

    float3 SampleLightProbe (Surface surfaceWS) 
	{
		#ifdef LIGHTMAP_ON
			return 0.0;
		#else
			if (unity_ProbeVolumeParams.x) 
			{
				return SampleProbeVolumeSH4(
					TEXTURE3D_ARGS(unity_ProbeVolumeSH, sampler_unity_ProbeVolumeSH),
					surfaceWS.position, surfaceWS.normal,
					unity_ProbeVolumeWorldToObject,
					unity_ProbeVolumeParams.y, unity_ProbeVolumeParams.z,
					unity_ProbeVolumeMin.xyz, unity_ProbeVolumeSizeInv.xyz
				);
			}
			else 
			{
				float4 coefficients[7];
				coefficients[0] = unity_SHAr;
				coefficients[1] = unity_SHAg;
				coefficients[2] = unity_SHAb;
				coefficients[3] = unity_SHBr;
				coefficients[4] = unity_SHBg;
				coefficients[5] = unity_SHBb;
				coefficients[6] = unity_SHC;
				return max(0.0, SampleSH9(coefficients, surfaceWS.normal));
			}
		#endif
	}

	float3 SampleEnvironment (Surface surfaceWS, BRDF brdf) 
	{
		float3 uvw = reflect(-surfaceWS.viewDirection, surfaceWS.normal);
		float mip = PerceptualRoughnessToMipmapLevel(brdf.perceptualRoughness);
		float4 environment = SAMPLE_TEXTURECUBE_LOD(unity_SpecCube0, sampler_unity_SpecCube0, uvw, mip);
		return DecodeHDREnvironment(environment, unity_SpecCube0_HDR);
	}


    struct GI
    {
        float3 diffuse;
		float3 specular;
		ShadowMask shadowMask;
    };

    GI GetGI (float2 uv_lightmap, Surface surfaceWS, BRDF brdf) 
    {
	    GI gi;
	    gi.diffuse = SampleLightMap(uv_lightmap) + SampleLightProbe(surfaceWS);
		gi.specular = SampleEnvironment(surfaceWS, brdf);
		gi.shadowMask.always = false;
		gi.shadowMask.distance = false;
		gi.shadowMask.shadows = 1.0;

		#if defined(_SHADOW_MASK_ALWAYS)
			gi.shadowMask.always = true;
			gi.shadowMask.shadows = SampleBakedShadows(uv_lightmap, surfaceWS);
		#elif defined(_SHADOW_MASK_DISTANCE)
			gi.shadowMask.distance = true;
			gi.shadowMask.shadows = SampleBakedShadows(uv_lightmap, surfaceWS);
		#endif

	    return gi;
    }


#endif 