
using System.Linq;
using UnityEngine;
using UnityEngine.Rendering;

namespace KRP
{

    public partial class KrusRenderPipeline : RenderPipeline
    {
        bool useDynamicBatching, useGPUInstancing, useLightsPerObject;
        ShadowSettings shadowSettings;

        public KrusRenderPipeline
        (
            bool useDynamicBatching, bool useGPUInstancing, bool useSRPBatcher, bool useLightsPerObject, ShadowSettings shadowSettings
        )
        {
            this.useDynamicBatching = useDynamicBatching;
            this.useGPUInstancing = useGPUInstancing;
            this.shadowSettings = shadowSettings;
            this.useLightsPerObject = useLightsPerObject;
            GraphicsSettings.useScriptableRenderPipelineBatching = useSRPBatcher;
            GraphicsSettings.lightsUseLinearIntensity = true;

            InitializeForEditor();
        }

        CameraRenderer renderer = new CameraRenderer();


        protected override void Render(ScriptableRenderContext context, Camera[] cameras)
        {
            // Loop through all cameras and render images
            for (int i = 0; i < cameras.Length; i++)
            {
                renderer.Render(context, cameras[i], useDynamicBatching, useGPUInstancing, useLightsPerObject, shadowSettings);
            }
        }
    }

}
