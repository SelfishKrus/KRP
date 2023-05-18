#ifndef KRP_SURFACE_INCLUDED
#define KRP_SURFACE_INCLUDED

    struct PbrSurface {
        half metallic;
        half AO;
        half tempRoughness;
        half roughness;
        half smoothness;

        half3 baseCol;
        half alpha;

        half3 F0;
    };

    struct PbrVectors
    {   
        half3 nTS;  // normal tangent space
        half3 n;    // normal
        half3 l;    // light direction
        half3 v;    // view direction
        half3 h;    // half vector

        half nv;    // dot(n, v)
        half nl;    // dot(n, l)
        half hv;    // dot(h, v)
        half nh;    // dot(n, h)
        half lh;    // dot(l, h)
    };

    void SetupSurface(Varyings i, inout PbrSurface pbrSurface) {
        
        // Masks decompression
        // r - metallic, g - AO, b - roughness
        pbrSurface.metallic = tex2D(_MetallicTex, i.uv).r;
        pbrSurface.AO = clamp(tex2D(_AOTex,i.uv).r, 0, 1);
        pbrSurface.AO = pow(pbrSurface.AO, _AOScale);
        pbrSurface.tempRoughness = tex2D(_RoughnessTex, i.uv).r;
        pbrSurface.tempRoughness = (pbrSurface.tempRoughness+_RoughnessScale) / (1+_RoughnessScale);
        pbrSurface.roughness = pow(pbrSurface.tempRoughness, 2);
        pbrSurface.smoothness = 1 - pbrSurface.tempRoughness;
        
        half4 texCol = tex2D(_BaseTex, i.uv);
        pbrSurface.baseCol = texCol.rgb;
        pbrSurface.alpha = texCol.a;
        pbrSurface.baseCol *= _Tint.rgb;
        pbrSurface.F0 = lerp(0.04, pbrSurface.baseCol, pbrSurface.metallic);

        return;
    }

    void SetupVectors(Varyings i, inout PbrVectors pbrVectors) {

        float3 posWS = float3(i.TBN0.w, i.TBN1.w, i.TBN2.w);

        half4 normalCol = tex2D(_NormalTex, i.uv);
        half3 normalTS = UnpackNormalScale(normalCol, _NormalScale);
        half3 normalWS = normalize(half3(dot(i.TBN0.xyz, normalTS), dot(i.TBN1.xyz, normalTS), dot(i.TBN2.xyz, normalTS)));

        DirectionalLight mainLight = GetDirectionalLight(0);

        pbrVectors.nTS = normalTS;
        pbrVectors.n = normalWS;
        pbrVectors.l = normalize(mainLight.direction);
        pbrVectors.v = SafeNormalize(_WorldSpaceCameraPos - posWS);
        pbrVectors.h = normalize(pbrVectors.v+pbrVectors.l);
        pbrVectors.nv = max(saturate(dot(pbrVectors.n, pbrVectors.v)), 0.00001);
        pbrVectors.nl = max(saturate(dot(pbrVectors.n, pbrVectors.l)), 0.00001);
        pbrVectors.hv = max(saturate(dot(pbrVectors.h, pbrVectors.v)), 0.00001);
        pbrVectors.nh = max(saturate(dot(pbrVectors.n, pbrVectors.h)), 0.00001);
        pbrVectors.lh = max(saturate(dot(pbrVectors.l, pbrVectors.h)), 0.00001);

        return;
    }

#endif