#ifndef KRP_LIT_PASS_INCLUDED
#define KRP_LIT_PASS_INCLUDED

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

    struct Attributes
    {
        float4 posOS : POSITION;
        float2 uv : TEXCOORD0;
        half4 normalOS : NORMAL;
        half4 tangentOS : TANGENT;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct Varyings
    {
        float2 uv : TEXCOORD0;
        float4 pos : SV_POSITION;
        float4 TBN0 : TEXCOORD1;
        float4 TBN1 : TEXCOORD2;
        float4 TBN2 : TEXCOORD3;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    UNITY_INSTANCING_BUFFER_START(UnityPerMaterial)

    UNITY_INSTANCING_BUFFER_END(UnityPerMaterial)

    float4 _BaseTex_ST;
    half _NormalScale;
    half _RoughnessScale;
    float _AOScale;
    float4 _Tint;

    float _TestFactor;
    
    sampler2D _MainTex;
    sampler2D _BaseTex;
    sampler2D _NormalTex;
    sampler2D _MetallicTex;
    sampler2D _RoughnessTex;
    sampler2D _AOTex;

    #include "Assets/Shader/KRP_Light.hlsl"
    #include "Assets/Shader/KRP_Surface.hlsl"
    #include "Assets/Shader/KRP_BSDF.hlsl"

    Varyings LitPassVertex (Attributes i)
    {
        Varyings o;
        o.pos = TransformObjectToHClip(i.posOS.xyz);
        o.uv = TRANSFORM_TEX(i.uv, _BaseTex);

        float3 posWS = TransformObjectToWorld(i.posOS.xyz);
        half3 normalWS = TransformObjectToWorldNormal(i.normalOS.xyz, true);
        half3 tangentWS = TransformObjectToWorldDir(i.tangentOS.xyz, true);
        half3 binormalWS = cross(normalWS, tangentWS) * i.tangentOS.w;

        // TBN matrix
        o.TBN0 = float4(tangentWS.x, binormalWS.x, normalWS.x, posWS.x);
        o.TBN1 = float4(tangentWS.y, binormalWS.y, normalWS.y, posWS.y);
        o.TBN2 = float4(tangentWS.z, binormalWS.z, normalWS.z, posWS.z);
        

        return o;
    }

    half4 LitPassFragment (Varyings input) : SV_Target
    {   
        // === PREPARATION === //
        PbrSurface pbrSurface;
        SetupSurface(input, pbrSurface);
        PbrVectors pbrVectors;
        SetupVectors(input, pbrVectors);

        DirectionalLight mainLight = GetDirectionalLight(0);
        
        // === DIRECT LIGHT === //
        half3 F_DL = GetF_SL(pbrSurface.F0, pbrVectors.hv, pbrSurface.roughness);
        // Specular - Cook-Torrance BRDF //
        half3 BRDF = GetBRDF_CookTorrance(pbrSurface, pbrVectors, F_DL);
        half3 specCol_DL = BRDF * mainLight.color * pbrVectors.nl * PI;   // to compensate for PI igonred in diffuse part      
        // Diffuse - Lambert // 
        half3 k_d_DL = (1 - F_DL) * (1 - pbrSurface.metallic);
        half3 diffCol_DL = k_d_DL * pbrSurface.baseCol * mainLight.color * pbrVectors.nl;
        // Color from Direct Light // 
        half3 directCol = diffCol_DL + specCol_DL;

        // === INDIRECT LIGHT === //
        // Specular //
        // Li - IBL 
        half3 IBLCol = GetIBL(pbrVectors.n, pbrVectors.v, pbrSurface.roughness);
        // BRDF - Cook-Torrance
        half3 F_IDL = GetF_SL(pbrSurface.F0, pbrVectors.nv, pbrSurface.roughness);
        half3 envBRDF = GetEnvBRDF_CookTorrance(pbrSurface, pbrVectors, BRDF);
        half3 specCol_IDL = IBLCol * envBRDF * PI;   // to compensate for PI igonred in diffuse part
        // Diffuse - Lambert // 
        // Li - SH
        half3 SHCol = SampleSH(pbrVectors.n);
        // BRDF - Lambert
        half3 k_d_IDL = (1 - F_IDL) * (1 - pbrSurface.metallic);
        half3 diffCol_IDL = SHCol * k_d_IDL * pbrSurface.baseCol;
        // Color from Indirect Light // 
        half3 indirectCol = specCol_IDL + diffCol_IDL;

        // === FINAL COLOR === //
        half3 col = directCol + indirectCol;

        return half4(col, pbrSurface.alpha);
    }

#endif