#ifndef KRP_SHADOWS_INCLUDED
#define KRP_SHADOWS_INCLUDED

	#define MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT 4
	#define MAX_CASCADE_COUNT 4

	TEXTURE2D_SHADOW(_DirectionalShadowAtlas);
	#define SHADOW_SAMPLER sampler_linear_clamp_compare
	SAMPLER_CMP(SHADOW_SAMPLER);

	CBUFFER_START(KRP_Shadows)
		int _CascadeCount;
		float4 _CascadeCullingSpheres[MAX_CASCADE_COUNT];
		float4x4 _DirectionalShadowMatrices[MAX_SHADOWED_DIRECTIONAL_LIGHT_COUNT * MAX_CASCADE_COUNT];
		float4 _ShadowDistanceFade;
	CBUFFER_END

	struct ShadowData
	{
		int cascadeIndex;
		float strength;
	};

	float FadedShadowStrength (float distance, float scale, float fade) 
	{
		return saturate((1.0 - distance * scale) * fade);
	}

	ShadowData GetShadowData (Surface surfaceWS) 
	{
		ShadowData data;
		data.strength = FadedShadowStrength(surfaceWS.depth, _ShadowDistanceFade.x, _ShadowDistanceFade.y);
		int i;
		for (i = 0; i < _CascadeCount; i++) 
		{
			float4 sphere = _CascadeCullingSpheres[i];
			float distanceSqr = DistanceSquared(surfaceWS.position, sphere.xyz);
			if (distanceSqr < sphere.w) break;
		}

		if (i == _CascadeCount) data.strength = 0.0f;

		data.cascadeIndex = i;
		return data;
	}

	struct DirectionalShadowData
    {
        float strength;
        int tileIndex;
    };

	float SampleDirectionalShadowAtlas (float3 posSTS)
	{
		return SAMPLE_TEXTURE2D_SHADOW(_DirectionalShadowAtlas, SHADOW_SAMPLER, posSTS);
	}

	float GetDirectionalShadowAttenuation (DirectionalShadowData data, Surface surfaceWS) 
	{
		if (data.strength <= 0.0f)	
			return 1.0f;

		float3 posSTS = mul(_DirectionalShadowMatrices[data.tileIndex],float4(surfaceWS.position, 1.0)).xyz;
		float shadow = SampleDirectionalShadowAtlas(posSTS);

		return lerp(1.0f, shadow, data.strength);
	}

#endif 