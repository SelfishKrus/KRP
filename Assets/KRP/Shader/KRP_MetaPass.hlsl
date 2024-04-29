#ifndef KRP_META_PASS_INCLUDED
#define KRP_META_PASS_INCLUDED

	#include "../ShaderLibrary/KRP_Surface.hlsl"
	#include "../ShaderLibrary/KRP_Shadows.hlsl"
	#include "../ShaderLibrary/KRP_Light.hlsl"
	#include "../ShaderLibrary/KRP_BRDF.hlsl"

	// x = return albedo
    // y = return normal
	bool4 unity_MetaFragmentControl;
	float unity_OneOverOutputBoost;
	float unity_MaxOutputValue;

	struct Attributes 
	{
		float3 posOS : POSITION;
		float2 uv_base : TEXCOORD0;
		float2 uv_lightmap : TEXCOORD1;
	};

	struct Varyings 
	{
		float4 posCS : SV_POSITION;
		float2 uv_base : VAR_BASE_UV;
	};

	Varyings MetaPassVertex (Attributes i) 
	{
		Varyings o;
		i.posOS.xy = i.uv_lightmap * unity_LightmapST.xy + unity_LightmapST.zw;
		i.posOS.z = i.posOS.z > 0.0 ? FLT_MIN : 0.0;
		//i.posOS.z = i.posOS.z > 0.0 ? REAL_MIN : 0.0;
		o.posCS = TransformWorldToHClip(i.posOS);
		o.uv_base = TransformBaseUV(i.uv_base);
		return o;
	}

	float4 MetaPassFragment (Varyings i) : SV_TARGET 
	{	

		float4 baseColor = GetBaseColor(i.uv_base);
		Surface surface;
		ZERO_INITIALIZE(Surface, surface);
		surface.color = baseColor.rgb;
		surface.metallic = GetMetallic(i.uv_base);
		surface.smoothness = GetSmoothness(i.uv_base);

		ShadowData shadowData = GetShadowData(surface);
		Light light = GetDirectionalLight(0, surface, shadowData);
		BRDF brdf = GetBRDF_DL(surface, light);

		float4 meta = 0.0;
		if (unity_MetaFragmentControl.x) 
		{
			meta = float4(brdf.diffuse, 1.0);
			meta.rgb += brdf.specular * brdf.roughness * 0.5;
			meta.rgb = min(PositivePow(meta.rgb, unity_OneOverOutputBoost), unity_MaxOutputValue);
		}
		else if (unity_MetaFragmentControl.y) 
		{
			meta = float4(GetEmission(i.uv_base), 1.0);
		}

		return meta;
	}

#endif 