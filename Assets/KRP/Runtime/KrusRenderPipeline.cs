
using UnityEngine;
using UnityEngine.Rendering;

public class KrusRenderPipeline : RenderPipeline{
    
    CameraRenderer renderer = new CameraRenderer();

    // evoked per frame
    // context - a struct that contains all the information 
    //           about the current rendering pass
    protected override void Render(ScriptableRenderContext context, Camera[] cameras) {
        foreach (Camera camera in cameras) {
            renderer.Render(context, camera);
        }
    }

    
}
