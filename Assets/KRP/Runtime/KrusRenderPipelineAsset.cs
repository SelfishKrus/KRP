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
        bool useDynamicBatching = true, useGPUInstancing = true, useSRPBatcher = true;

        [SerializeField]
        ShadowSettings shadows = default;

        protected override RenderPipeline CreatePipeline()
        {
            return new KrusRenderPipeline(useDynamicBatching, useGPUInstancing, useSRPBatcher, shadows);
        }


    }
}

