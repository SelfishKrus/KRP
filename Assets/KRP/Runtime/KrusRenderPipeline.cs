
using System.Linq;
using UnityEngine;
using UnityEngine.Rendering;

public class KrusRenderPipeline : RenderPipeline
{   
    public KrusRenderPipeline()
    {
        GraphicsSettings.useScriptableRenderPipelineBatching = true;
    }

    CameraRenderer renderer = new CameraRenderer();

	protected override void Render (ScriptableRenderContext context, Camera[] cameras) 
    {   
        // Loop through all cameras and render images
        for (int i = 0; i < cameras.Length; i++)
        {
            renderer.Render(context, cameras[i]);
        }
    }

	protected RenderPipeline CreatePipeline() 
    {
		return new KrusRenderPipeline();
	}
}
