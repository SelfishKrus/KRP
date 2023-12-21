// To store rendering settings

using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(menuName = "Rendering/Krus Render Pipeline")]
public class KrusRenderPipelineAsset : RenderPipelineAsset
{
    protected override RenderPipeline CreatePipeline()
    {
        return new KrusRenderPipeline();
    }
}
