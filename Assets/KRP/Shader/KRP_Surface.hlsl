#ifndef KRP_SURFACE_INCLUDED
#define KRP_SURFACE_INCLUDED

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