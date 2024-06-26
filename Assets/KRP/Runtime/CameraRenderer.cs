// To render a camera's image

using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Profiling;
using UnityEngine.Rendering;

namespace KRP
{

    public partial class CameraRenderer
    {
        ScriptableRenderContext context;
        Camera camera;

        const string bufferName = "Render Camera";
        CommandBuffer buffer = new CommandBuffer { name = bufferName };

        CullingResults cullingResults;

        static ShaderTagId
            unlitShaderTagId = new ShaderTagId("SRPDefaultUnlit"),
            litShaderTagId = new ShaderTagId("KRPLit");

        Lighting lighting = new Lighting();

        // Main // 

        public void Render
        (
            ScriptableRenderContext context, Camera camera,
            bool useDynamicBatching, bool useGPUInstancing, bool useLightsPerObject, 
            ShadowSettings shadowSettings
        )
        {
            this.context = context;
            this.camera = camera;

            PrepareBuffer();
            PrepareForSceneWindow();
            if (!Cull(shadowSettings.maxDistance))
            {
                return;
            }

            buffer.BeginSample(SampleName);
            ExecuteBuffer();
            lighting.Setup(context, cullingResults, shadowSettings, useLightsPerObject);
            buffer.EndSample(SampleName);

            Setup();
            DrawVisibleGeometry(useDynamicBatching, useGPUInstancing, useLightsPerObject);
            DrawUnsupportedShaders();
            DrawGizmos();
            lighting.Cleanup();
            Submit();

        }

        // Private Function // 

        void Setup()
        {
            context.SetupCameraProperties(camera);
            CameraClearFlags flags = camera.clearFlags;
            buffer.ClearRenderTarget(
                flags <= CameraClearFlags.Depth,
                flags == CameraClearFlags.Color,
                flags == CameraClearFlags.Color ? camera.backgroundColor.linear : Color.clear);
            buffer.BeginSample(SampleName);
            ExecuteBuffer();

        }

        void DrawVisibleGeometry(bool useDynamicBatching, bool useGPUInstancing, bool useLightsPerObject)
        {
            PerObjectData lightsPerObjectFlags = useLightsPerObject ? 
                PerObjectData.LightData | PerObjectData.LightIndices : PerObjectData.None;
            var sortingSettings = new SortingSettings(camera)
            {
                criteria = SortingCriteria.CommonOpaque
            };
            var drawingSettings = new DrawingSettings(unlitShaderTagId, sortingSettings)
            {
                enableDynamicBatching = useDynamicBatching,
                enableInstancing = useGPUInstancing,
                perObjectData =
                    PerObjectData.Lightmaps |
                    PerObjectData.ReflectionProbes |
                    PerObjectData.ShadowMask |
                    PerObjectData.LightProbe |
                    PerObjectData.OcclusionProbe |
                    PerObjectData.LightProbeProxyVolume |
                    PerObjectData.OcclusionProbeProxyVolume |
                    lightsPerObjectFlags
            };
            drawingSettings.SetShaderPassName(1, litShaderTagId);
            var filteringSettings = new FilteringSettings(RenderQueueRange.opaque);
            context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);

            context.DrawSkybox(camera);

            sortingSettings.criteria = SortingCriteria.CommonTransparent;
            drawingSettings.sortingSettings = sortingSettings;
            filteringSettings.renderQueueRange = RenderQueueRange.transparent;

            context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
        }

        void Submit()
        {
            buffer.EndSample(SampleName);
            ExecuteBuffer();

            context.Submit();
        }

        void ExecuteBuffer()
        {
            context.ExecuteCommandBuffer(buffer);
            buffer.Clear();
        }

        bool Cull(float maxShadowDistance)
        {
            if (camera.TryGetCullingParameters(out ScriptableCullingParameters p))
            {
                p.shadowDistance = Mathf.Min(maxShadowDistance, camera.farClipPlane);
                cullingResults = context.Cull(ref p);
                return true;
            }
            return false;
        }

    }

}