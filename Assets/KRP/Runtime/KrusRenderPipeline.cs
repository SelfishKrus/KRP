
using UnityEngine;
using UnityEngine.Rendering;


public class KrusRenderPipeline : RenderPipeline{

    bool useDynamicBatching, useGPUInstancing;
    
    public KrusRenderPipeline(
        bool useDynamicBatching, bool useGPUInstancing, bool useSRPBatcher
    ) {
        this.useDynamicBatching = useDynamicBatching;
        this.useGPUInstancing = useGPUInstancing;
        GraphicsSettings.useScriptableRenderPipelineBatching = useSRPBatcher;
        GraphicsSettings.lightsUseLinearIntensity = true;
    }

    CameraRenderer renderer = new CameraRenderer();

    // evoked per frame
    // context - a struct that contains all the information 
    //           about the current rendering pass
    protected override void Render(ScriptableRenderContext context, Camera[] cameras) {
        foreach (Camera camera in cameras) {
            renderer.Render(context, camera, useDynamicBatching, useGPUInstancing);
        }
    }    
}
