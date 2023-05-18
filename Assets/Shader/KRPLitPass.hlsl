#ifndef KRP_LIT_PASS_INCLUDED
#define KRP_LIT_PASS_INCLUDED

    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"

    #include "Assets/Shader/KRPSurface.hlsl"
    #include "Assets/Shader/KRPLight.hlsl"
    #include "Assets/Shader/KRPLighting.hlsl"

    sampler2D _MainTex;

    struct Attributes
    {
        float4 posOS : POSITION;
        float2 uv : TEXCOORD0;
        half3 normalOS : NORMAL;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct Varyings
    {
        float4 pos : SV_POSITION;
        float2 uv : VAR_UV;
        half3 normalWS : VAR_NORMAL;
        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    Varyings LitPassVertex (Attributes input)
    {
        Varyings output;
        output.uv = input.uv;
        output.pos = TransformObjectToHClip(input.posOS.xyz);
        output.normalWS = TransformObjectToWorldNormal(input.normalOS);
        UNITY_SETUP_INSTANCE_ID(input);
        return output;
    }

    half4 LitPassFragment (Varyings input) : SV_Target
    {   
        half4 mainTex = tex2D(_MainTex, input.uv);

        Surface surface;
        surface.normal = normalize(input.normalWS);
        surface.color = mainTex.rgb;
        surface.alpha = mainTex.a;
        
        half3 color = GetLighting(surface);
        return half4(color, surface.alpha);
    }

#endif