
using UnityEngine;
using UnityEngine.Rendering;

[CreateAssetMenu(menuName = "Rendering/Krus Render Pipeline")]
public class KrusRenderPipelineAsset : RenderPipelineAsset{
    
    [SerializeField]
    bool useDynamicBatching = true, useGPUInstancing = true, useSRPBatcher = true;

    protected override RenderPipeline CreatePipeline(){
        return new KrusRenderPipeline(useDynamicBatching,useGPUInstancing,useSRPBatcher);
    }
}
