#ifndef K_SURFACE_INCLUDED
#define K_SURFACE_INCLUDED

struct Surface 
{	
	float3 position;
	float3 normal;
	float3 viewDirection;
	float3 color;
	float alpha;
	float metallic;
	float smoothness;
};

#endif 