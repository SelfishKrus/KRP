#ifndef KRP_GI_INCLUDED
#define KRP_GI_INCLUDED

    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/EntityLighting.hlsl"

    TEXTURE2D(unity_Lightmap);  
    SAMPLER(sampler_unity_Lightmap);

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
			float4 coefficients[7];
			coefficients[0] = unity_SHAr;
			coefficients[1] = unity_SHAg;
			coefficients[2] = unity_SHAb;
			coefficients[3] = unity_SHBr;
			coefficients[4] = unity_SHBg;
			coefficients[5] = unity_SHBb;
			coefficients[6] = unity_SHC;
			return max(0.0, SampleSH9(coefficients, surfaceWS.normal));
		#endif
	}


    struct GI
    {
        float3 diffuse;
    };

    GI GetGI (float2 uv_lightmap, Surface surfaceWS) 
    {
	    GI gi;
	    gi.diffuse = SampleLightMap(uv_lightmap) + SampleLightProbe(surfaceWS);
	    return gi;
    }

#endif 