
using System.Linq;
using UnityEngine;
using UnityEngine.Rendering;

namespace KRP
{

    public class KrusRenderPipeline : RenderPipeline
    {
        bool useDynamicBatching, useGPUInstancing, useSRPBatcher;
        ShadowSettings shadowSettings;

        public KrusRenderPipeline
        (
            bool useDynamicBatching, bool useGPUInstancing, bool useSRPBatcher, ShadowSettings shadowSettings
        )
        {
            this.useDynamicBatching = useDynamicBatching;
            this.useGPUInstancing = useGPUInstancing;
            this.shadowSettings = shadowSettings;
            GraphicsSettings.useScriptableRenderPipelineBatching = useSRPBatcher;
            GraphicsSettings.lightsUseLinearIntensity = true;
        }

        CameraRenderer renderer = new CameraRenderer();


        protected override void Render(ScriptableRenderContext context, Camera[] cameras)
        {
            // Loop through all cameras and render images
            for (int i = 0; i < cameras.Length; i++)
            {
                renderer.Render(context, cameras[i], useDynamicBatching, useGPUInstancing, shadowSettings);
            }
        }
    }

}
