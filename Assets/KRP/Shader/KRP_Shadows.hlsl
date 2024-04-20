#ifndef KRP_SHADOWS_INCLUDED
#define KRP_SHADOWS_INCLUDED

	#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Shadow/ShadowSamplingTent.hlsl"

	#if defined(_DIRECTIONAL_PCF3)
		#define DIRECTIONAL_FILTER_SAMPLES 4
		#define DIRECTIONAL_FILTER_SETUP SampleShadow_ComputeSamples_Tent_3x3
	#elif defined(_DIRECTIONAL_PCF5)
		#define DIRECTIONAL_FILTER_SAMPLES 9
		#define DIRECTIONAL_FILTER_SETUP SampleShadow_ComputeSamples_Tent_5x5
	#elif defined(_DIRECTIONAL_PCF7)
		#define DIRECTIONAL_FILTER_SAMPLES 16
		#define DIRECTIONAL_FILTER_SETUP SampleShadow_ComputeSamples_Tent_7x7
	#endif

	#define MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT 4
	#define MAX_CASCADE_COUNT 4

	TEXTURE2D_SHADOW(_DirectionalShadowAtlas);
	#define SHADOW_SAMPLER sampler_linear_clamp_compare
	SAMPLER_CMP(SHADOW_SAMPLER);

	CBUFFER_START(KRP_Shadows)
		int _CascadeCount;
		float4 _CascadeCullingSpheres[MAX_CASCADE_COUNT];
		float4 _CascadeData[MAX_CASCADE_COUNT];
		float4x4 _DirectionalShadowMatrices[MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT * MAX_CASCADE_COUNT];
		float4 _ShadowAtlasSize;
		float4 _ShadowDistanceFade;
	CBUFFER_END

	struct ShadowData
	{
		int cascadeIndex;
		float cascadeBlend;
		float strength;
	};

	float FadedShadowStrength (float distance, float scale, float fade) 
	{
		return saturate((1.0 - distance * scale) * fade);
	}

	ShadowData GetShadowData (Surface surfaceWS) 
	{
		ShadowData data;
		data.cascadeBlend = 1.0f;
		data.strength = FadedShadowStrength(surfaceWS.depth, _ShadowDistanceFade.x, _ShadowDistanceFade.y);
		int i;
		for (i = 0; i < _CascadeCount; i++) 
		{
			float4 sphere = _CascadeCullingSpheres[i];
			float distanceSqr = DistanceSquared(surfaceWS.position, sphere.xyz);
			if (distanceSqr < sphere.w) 
			{	
				float fade = FadedShadowStrength(distanceSqr, _CascadeData[i].x, _ShadowDistanceFade.z);
				if (i == _CascadeCount - 1)
				{
					data.strength *= fade;
				}
				else 
				{
					data.cascadeBlend = fade;
				}

				break;
			};
		}

		if (i == _CascadeCount) 
		{
			data.strength = 0.0f;
		}
		#ifdef _CASCADE_BLEND_DITHER
			else if (data.cascadeBlend < surfaceWS.dither) 
			{
				i += 1;
			}
		#endif

		#ifndef _CASCADE_BLEND_SOFT
			data.cascadeBlend = 1.0f;
		#endif 

		data.cascadeIndex = i;
		return data;
	}

	struct DirectionalShadowData
    {
        float strength;
        int tileIndex;
		float normalBias;
    };

	float SampleDirectionalShadowAtlas (float3 posSTS)
	{
		return SAMPLE_TEXTURE2D_SHADOW(_DirectionalShadowAtlas, SHADOW_SAMPLER, posSTS);
	}

	float FilterDirectionalShadow (float3 posSTS) 
	{
		#if defined(DIRECTIONAL_FILTER_SETUP)
			float weights[DIRECTIONAL_FILTER_SAMPLES];
			float2 poss[DIRECTIONAL_FILTER_SAMPLES];
			float4 size = _ShadowAtlasSize.yyxx;
			DIRECTIONAL_FILTER_SETUP(size, posSTS.xy, weights, poss);
			float shadow = 0;
			for (int i = 0; i < DIRECTIONAL_FILTER_SAMPLES; i++) {
				shadow += weights[i] * SampleDirectionalShadowAtlas(
					float3(poss[i].xy, posSTS.z)
				);
			}
			return shadow;
		#else
			return SampleDirectionalShadowAtlas(posSTS);
		#endif
	}

	float GetDirectionalShadowAttenuation (DirectionalShadowData directionalData, ShadowData globalData, Surface surfaceWS) 
	{
		#ifndef _RECEIVE_SHADOWS
			return 1.0f;
		#endif 

		if (directionalData.strength <= 0.0f)	
			return 1.0f;
		float3 normalBias = 
			surfaceWS.normal * 
			(directionalData.normalBias *_CascadeData[globalData.cascadeIndex].y);
		float3 posSTS = mul(_DirectionalShadowMatrices[directionalData.tileIndex],float4(surfaceWS.position+normalBias, 1.0)).xyz;
		float shadow = FilterDirectionalShadow(posSTS);

		// cascade blend 
		if (globalData.cascadeBlend < 1.0) 
		{
			normalBias = surfaceWS.normal * (directionalData.normalBias * _CascadeData[globalData.cascadeIndex + 1].y);
			posSTS = mul(_DirectionalShadowMatrices[directionalData.tileIndex + 1],float4(surfaceWS.position + normalBias, 1.0)).xyz;
			shadow = lerp(FilterDirectionalShadow(posSTS), shadow, globalData.cascadeBlend);
		}

		return lerp(1.0f, shadow, directionalData.strength);
	}

#endif 