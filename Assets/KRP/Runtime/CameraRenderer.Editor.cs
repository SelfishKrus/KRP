
using UnityEditor;
using UnityEngine;
using UnityEngine.Profiling;
using UnityEngine.Rendering;

partial class CameraRenderer{


    partial void DrawGizmos(); // signature

    partial void DrawUnsupportedShaders();  // signature

    partial void PrepareForSceneWindow();

    partial void PrepareBuffer();

    #if UNITY_EDITOR
        static ShaderTagId[] legacyShaderTagIds = {
            new ShaderTagId("Always"),
            new ShaderTagId("ForwardBase"),
            new ShaderTagId("PrepassBase"),
            new ShaderTagId("Vertex"),
            new ShaderTagId("VertexLMRGBM"),
            new ShaderTagId("VertexLM")
        };  

        static Material errorMat;

        string SampleName { get; set; }

        partial void DrawUnsupportedShaders(){
            if (errorMat == null) {
                errorMat = new Material(Shader.Find("Hidden/InternalErrorShader"));
            }
            var drawingSettings = new DrawingSettings(
                legacyShaderTagIds[0], new SortingSettings(camera)
            ){
                overrideMaterial = errorMat
            };
            for (int i = 1; i < legacyShaderTagIds.Length; i++) {
                drawingSettings.SetShaderPassName(i, legacyShaderTagIds[i]);
            } 
            var filteringSettings = FilteringSettings.defaultValue;
            context.DrawRenderers(
                cullingResults, ref drawingSettings, ref filteringSettings
            );
        }

        partial void DrawGizmos(){
            if (Handles.ShouldRenderGizmos()) {
                context.DrawGizmos(camera, GizmoSubset.PreImageEffects);
                context.DrawGizmos(camera, GizmoSubset.PostImageEffects);
            }
        }

        // render UI in the scene view
        partial void PrepareForSceneWindow(){
            if (camera.cameraType == CameraType.SceneView) {
                ScriptableRenderContext.EmitWorldGeometryForSceneView(camera);
            }
        }

        // create scopes for different cameras
        partial void PrepareBuffer(){

            // namely buffer.name = SampleName = camera.name;
            Profiler.BeginSample("Editor Only");
            SampleName = camera.name;
            buffer.name = camera.name;
            Profiler.EndSample();
            
        }

    #else

        const string SampleName = bufferName;
        
    #endif

}
