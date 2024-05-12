#ifndef KRP_UNITY_INPUT_INCLUDED
#define KRP_UNITY_INPUT_INCLUDED

	CBUFFER_START(UnityPerDraw)
		float4x4 unity_ObjectToWorld;
		float4x4 unity_WorldToObject;
		float4 unity_LODFade;
		float4 unity_WorldTransformParams;

		real4 unity_LightData;	// y - num of lights
		real4 unity_LightIndices[2];	// Each channel of the two vectors contains a light index,

		float4 unity_ProbesOcclusion; // occlusion data for light probes

		float4 unity_SpecCube0_HDR;

		// Lightmap
		float4 unity_LightmapST;
		float4 unity_DynamicLightmapST;

		// Light Probe
		float4 unity_SHAr;
		float4 unity_SHAg;
		float4 unity_SHAb;
		float4 unity_SHBr;
		float4 unity_SHBg;
		float4 unity_SHBb;
		float4 unity_SHC;

		// Light Probe Proxy Volume
		// x = Disabled(0)/Enabled(1)
        // y = Computation are done in global space(0) or local space(1)
        // z = Texel size on U texture coordinate
		float4 unity_ProbeVolumeParams;

		float4x4 unity_ProbeVolumeWorldToObject;
		float4 unity_ProbeVolumeSizeInv;
		float4 unity_ProbeVolumeMin;
	CBUFFER_END

	float4x4 unity_MatrixVP;
	float4x4 unity_MatrixV;
	float4x4 unity_MatrixInvV;
	float4x4 unity_prev_MatrixM;
	float4x4 unity_prev_MatrixIM;
	float4x4 glstate_matrix_projection;

	float3 _WorldSpaceCameraPos;

#endif