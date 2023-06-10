
using UnityEngine;
using UnityEngine.Rendering;

public partial class CameraRenderer{
    ScriptableRenderContext context;
    Camera camera;
    Lighting lighting = new Lighting();

    CullingResults cullingResults; // store the result of culling
    const string bufferName = "Render Camera";
    
    // MAIN FUNCTION // 
    public void Render (
        ScriptableRenderContext context, Camera camera,
        bool useDynamicBatching, bool useGPUInstancing,
        ShadowSettings shadowSettings
    ) {
        this.context = context;
        this.camera = camera;

        PrepareBuffer();
        PrepareForSceneWindow();
        if (!Cull(shadowSettings.maxDistance)) {
            return;
        }

        Setup(); 
        lighting.Setup(context, cullingResults, shadowSettings);
        DrawUnsupportedShaders();
        DrawVisibleGeometry(useDynamicBatching, useGPUInstancing);  
        DrawGizmos();
        Submit();  
    }



    CommandBuffer buffer = new CommandBuffer {
        name = bufferName
    };

    static ShaderTagId 
        unlitShaderTagId = new ShaderTagId("SRPDefaultUnlit"),
        litShaderTagId = new ShaderTagId("KRPLit");
    

    // to check if the camera is setting up correctly
    // correct - cull the scene
    // incorrect - skip rendering
    bool Cull(float maxShadowDistance) {
        if (camera.TryGetCullingParameters(out ScriptableCullingParameters p)) {
            p.shadowDistance = maxShadowDistance;
            cullingResults = context.Cull(ref p); // cull the scene
            return true;
        }
        return false;
    }

    void Setup() {
        context.SetupCameraProperties(camera); // setup matrix & properties
        CameraClearFlags flags = camera.clearFlags;
        buffer.ClearRenderTarget(
            flags <= CameraClearFlags.Depth, 
            flags == CameraClearFlags.Color,
            flags == CameraClearFlags.Color ? camera.backgroundColor.linear : Color.clear
        );  // clear the screen
        buffer.BeginSample(SampleName); // mark starts
        ExcuteBuffer(); 
    }

    void DrawVisibleGeometry(bool useDynamicBatching, bool useGPUInstancing) {
        var sortingSettings = new SortingSettings(camera) {
            criteria = SortingCriteria.CommonOpaque // sort by distance
        };
        var drawingSettings = new DrawingSettings(unlitShaderTagId, sortingSettings) {
            enableDynamicBatching = useDynamicBatching,
            enableInstancing = useGPUInstancing
        };
        var filteringSettings = new FilteringSettings(RenderQueueRange.opaque); // allow all
        drawingSettings.SetShaderPassName(1, litShaderTagId);

        context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
        context.DrawSkybox(camera);

        sortingSettings.criteria = SortingCriteria.CommonTransparent;
        drawingSettings.sortingSettings = sortingSettings;
        filteringSettings.renderQueueRange = RenderQueueRange.transparent;
        
        context.DrawRenderers(
            cullingResults, ref drawingSettings, ref filteringSettings
        );

    }

    void Submit() {
        buffer.EndSample(SampleName); // mark ends
        ExcuteBuffer();
        context.Submit();
    }

    void ExcuteBuffer() {
        context.ExecuteCommandBuffer(buffer); // send the commands to the GPU
        buffer.Clear();
    }
}
