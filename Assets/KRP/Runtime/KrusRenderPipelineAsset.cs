// To store rendering settings

using KRP;
using UnityEngine;
using UnityEngine.Rendering;


namespace KRP
{
    [CreateAssetMenu(menuName = "Rendering/Krus Render Pipeline")]
    public class KrusRenderPipelineAsset : RenderPipelineAsset
    {
        [SerializeField]
        bool 
            useDynamicBatching = true, 
            useGPUInstancing = true, 
            useSRPBatcher = true, 
            useLightsPerObject = true;

        [SerializeField]
        ShadowSettings shadows = default;

        Shader KrpDefaultShader => Shader.Find("KRP/Lit"); 
        public override Shader defaultShader => KrpDefaultShader;
        public override Material defaultMaterial => KrpDefaultShader != null ? new Material(KrpDefaultShader) : null;

        protected override RenderPipeline CreatePipeline()
        {
            return new KrusRenderPipeline(useDynamicBatching, useGPUInstancing, useSRPBatcher, useLightsPerObject, shadows);
        }


    }
}

