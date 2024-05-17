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

	#if defined(_OTHER_PCF3)
		#define OTHER_FILTER_SAMPLES 4
		#define OTHER_FILTER_SETUP SampleShadow_ComputeSamples_Tent_3x3
	#elif defined(_OTHER_PCF5)
		#define OTHER_FILTER_SAMPLES 9
		#define OTHER_FILTER_SETUP SampleShadow_ComputeSamples_Tent_5x5
	#elif defined(_OTHER_PCF7)
		#define OTHER_FILTER_SAMPLES 16
		#define OTHER_FILTER_SETUP SampleShadow_ComputeSamples_Tent_7x7
	#endif

	#define MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT 4
	#define MAX_SHADOWED_OTHER_LIGHT_COUNT 16
	#define MAX_CASCADE_COUNT 4

	TEXTURE2D_SHADOW(_DirectionalShadowAtlas);
	TEXTURE2D_SHADOW(_OtherShadowAtlas);
	#define SHADOW_SAMPLER sampler_linear_clamp_compare
	SAMPLER_CMP(SHADOW_SAMPLER);

	CBUFFER_START(KRP_Shadows)
		int _CascadeCount;
		float4 _CascadeCullingSpheres[MAX_CASCADE_COUNT];
		float4 _CascadeData[MAX_CASCADE_COUNT];
		float4x4 _DirectionalShadowMatrices[MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT * MAX_CASCADE_COUNT];
		float4x4 _OtherShadowMatrices[MAX_SHADOWED_OTHER_LIGHT_COUNT];
		float4 _OtherShadowTiles[MAX_SHADOWED_OTHER_LIGHT_COUNT];
		float4 _ShadowAtlasSize;
		float4 _ShadowDistanceFade;
	CBUFFER_END

	struct ShadowMask 
	{	
		bool always;
		bool distance;
		float4 shadows;
	};

	struct ShadowData
	{
		int cascadeIndex;
		float cascadeBlend;
		float strength;
		ShadowMask shadowMask;
	};

	float FadedShadowStrength (float distance, float scale, float fade) 
	{
		return saturate((1.0 - distance * scale) * fade);
	}

	ShadowData GetShadowData (Surface surfaceWS) 
	{
		ShadowData data;
		data.shadowMask.always = false;
		data.shadowMask.distance = false;
		data.shadowMask.shadows = 1.0;
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

		if (i == _CascadeCount && _CascadeCount > 0) 
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
		int shadowMaskChannel;
    };

	float SampleDirectionalShadowAtlas (float3 posSTS)
	{
		return SAMPLE_TEXTURE2D_SHADOW(_DirectionalShadowAtlas, SHADOW_SAMPLER, posSTS);
	}

	float SampleOtherShadowAtlas  (float3 posSTS, float3 bounds)
	{	
		posSTS.xy = clamp(posSTS.xy, bounds.xy, bounds.xy + bounds.z);
		return SAMPLE_TEXTURE2D_SHADOW(_OtherShadowAtlas, SHADOW_SAMPLER, posSTS);
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

	float FilterOtherShadow  (float3 posSTS, float3 bounds) 
	{
		#if defined(OTHER_FILTER_SETUP)
			float weights[DIRECTIONAL_FILTER_SAMPLES];
			float2 poss[DIRECTIONAL_FILTER_SAMPLES];
			float4 size = _ShadowAtlasSize.yyxx;
			OTHER_FILTER_SETUP(size, posSTS.xy, weights, poss);
			float shadow = 0;
			for (int i = 0; i < OTHER_FILTER_SAMPLES; i++) {
				shadow += weights[i] * SampleOtherShadowAtlas(
					float3(poss[i].xy, posSTS.z), bounds
				);
			}
			return shadow;
		#else
			return SampleOtherShadowAtlas(posSTS, bounds);
		#endif
	}

	float GetCascadedShadow (DirectionalShadowData directionalData, ShadowData globalData, Surface surfaceWS) 
	{
		float3 normalBias = 
			surfaceWS.interpolatedNormal * 
			(directionalData.normalBias *_CascadeData[globalData.cascadeIndex].y);
		float3 posSTS = mul(_DirectionalShadowMatrices[directionalData.tileIndex],float4(surfaceWS.position+normalBias, 1.0)).xyz;
		float shadow = FilterDirectionalShadow(posSTS);

		// cascade blend 
		if (globalData.cascadeBlend < 1.0) 
		{
			normalBias = surfaceWS.interpolatedNormal * (directionalData.normalBias * _CascadeData[globalData.cascadeIndex + 1].y);
			posSTS = mul(_DirectionalShadowMatrices[directionalData.tileIndex + 1],float4(surfaceWS.position + normalBias, 1.0)).xyz;
			shadow = lerp(FilterDirectionalShadow(posSTS), shadow, globalData.cascadeBlend);
		}

		return shadow;
	}

	float GetBakedShadow (ShadowMask mask, int channel) 
	{
		float shadow = 1.0;
		if (mask.always || mask.distance) 
		{
			if (channel >= 0) 
			{
				shadow = mask.shadows[channel];
			}
		}
		return shadow;
	}

	float GetBakedShadow (ShadowMask mask, int channel, float strength) 
	{
		if (mask.always || mask.distance) 
		{
			return lerp(1.0f, GetBakedShadow(mask, channel), strength);
		}
		return 1.0f;
	}

	float MixBakedAndRealtimeShadows (ShadowData globalData, float shadow, int shadowMaskChannel, float strength) 
	{
		float baked = GetBakedShadow(globalData.shadowMask, shadowMaskChannel);
		if (globalData.shadowMask.always) 
		{
			shadow = lerp(1.0, shadow, globalData.strength);
			shadow = min(baked, shadow);
			return lerp(1.0, shadow, strength);
		}
		if (globalData.shadowMask.distance) 
		{	
			shadow = lerp(baked, shadow, globalData.strength);
			return lerp(1.0f, shadow, strength);
		}
		return lerp(1.0, shadow, strength * globalData.strength);
	}

	float GetDirectionalShadowAttenuation (DirectionalShadowData directionalData, ShadowData globalData, Surface surfaceWS) 
	{
		#ifndef _RECEIVE_SHADOWS
			return 1.0f;
		#endif 

		float shadow;
		if (directionalData.strength * globalData.strength <= 0.0f)
		{
			shadow = GetBakedShadow(globalData.shadowMask, directionalData.shadowMaskChannel, abs(directionalData.strength));
		}
		else 
		{
			shadow = GetCascadedShadow(directionalData, globalData, surfaceWS);
			shadow = MixBakedAndRealtimeShadows(globalData, shadow, directionalData.shadowMaskChannel, directionalData.strength);
			shadow = lerp(1.0, shadow, directionalData.strength);
		}
		return shadow;
	}

	struct OtherShadowData 
	{
		float strength;
		int tileIndex;
		bool isPoint;
		int shadowMaskChannel;
		float3 lightPosWS;
		float3 lightDirWS;
		float3 spotDirWS;
	};

	static const float3 pointShadowPlanes[6] = 
	{
		float3(-1.0, 0.0, 0.0),
		float3(1.0, 0.0, 0.0),
		float3(0.0, -1.0, 0.0),
		float3(0.0, 1.0, 0.0),
		float3(0.0, 0.0, -1.0),
		float3(0.0, 0.0, 1.0)
	};

	float GetOtherShadow (OtherShadowData other, ShadowData global, Surface surfaceWS) 
	{	
		float tileIndex = other.tileIndex;
		float3 lightPlane = other.spotDirWS;
		if (other.isPoint) 
		{
			float faceOffset = CubeMapFaceID(-other.lightDirWS);
			tileIndex += faceOffset;
			lightPlane = pointShadowPlanes[faceOffset];
		}
		float4 tileData = _OtherShadowTiles[tileIndex];
		float3 surfaceToLight = other.lightPosWS - surfaceWS.position;
		float distanceToLightPlane = dot(surfaceToLight, lightPlane);
		float3 normalBias = surfaceWS.interpolatedNormal * (distanceToLightPlane * tileData.w);
		float4 posSTS = mul(
			_OtherShadowMatrices[tileIndex],
			float4(surfaceWS.position + normalBias, 1.0)
		);
		return FilterOtherShadow(posSTS.xyz / posSTS.w, tileData.xyz);
	}

	float GetOtherShadowAttenuation (OtherShadowData other, ShadowData global, Surface surfaceWS) 
	{
		#if !defined(_RECEIVE_SHADOWS)
			return 1.0;
		#endif
	
		float shadow;
		if (other.strength * global.strength <= 0.0) 
		{
			shadow = GetBakedShadow(global.shadowMask, other.shadowMaskChannel, abs(other.strength));
		}
		else 
		{
			shadow = GetOtherShadow(other, global, surfaceWS);
			shadow = MixBakedAndRealtimeShadows(global, shadow, other.shadowMaskChannel, other.strength);
		}

		return shadow;
	}

#endif 