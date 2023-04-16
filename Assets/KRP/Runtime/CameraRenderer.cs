
using UnityEngine;
using UnityEngine.Rendering;

public partial class CameraRenderer{
    ScriptableRenderContext context;
    Camera camera;
    
    public void Render (ScriptableRenderContext context, Camera camera) {
        this.context = context;
        this.camera = camera;

        PrepareForSceneWindow();
        if (!Cull()) {
            return;
        }

        Setup(); 
        DrawVisibleGeometry();  
        DrawUnsupportedShaders();
        DrawGizmos();
        Submit();  
    }

    CullingResults cullingResults; // store the result of culling
    const string bufferName = "Render Camera";
    CommandBuffer buffer = new CommandBuffer {
        name = bufferName
    };

    static ShaderTagId unlitShaderTagId = new ShaderTagId("SRPDefaultUnlit");

    // to check if the camera is setting up correctly
    // correct - cull the scene
    // incorrect - skip rendering
    bool Cull() {
        if (camera.TryGetCullingParameters(out ScriptableCullingParameters p)) {
            cullingResults = context.Cull(ref p); // cull the scene
            return true;
        }
        return false;
    }

    void Setup() {
        context.SetupCameraProperties(camera); // setup matrix & properties
        buffer.ClearRenderTarget(true, true, Color.clear);  // clear the screen
        buffer.BeginSample(bufferName); // mark starts
        ExcuteBuffer(); 
    }

    void DrawVisibleGeometry() {
        var sortingSettings = new SortingSettings(camera) {
            criteria = SortingCriteria.CommonOpaque // sort by distance
        };
        var drawingSettings = new DrawingSettings(unlitShaderTagId, sortingSettings);
        var filteringSettings = new FilteringSettings(RenderQueueRange.opaque); // allow all

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
        buffer.EndSample(bufferName); // mark ends
        ExcuteBuffer();
        context.Submit();
    }

    void ExcuteBuffer() {
        context.ExecuteCommandBuffer(buffer); // send the commands to the GPU
        buffer.Clear();
    }
}
