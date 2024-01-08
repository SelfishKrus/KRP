using UnityEditor;
using UnityEngine;
using UnityEngine.Profiling;
using UnityEngine.Rendering;

partial class CameraRenderer
{
    partial void DrawGizmos();

    partial void DrawUnsupportedShaders();

    partial void PrepareForSceneWindow();

    partial void PrepareBuffer();

#if UNITY_EDITOR
    
    string SampleName { get; set; }

    static ShaderTagId[] legacyShaderTagIds = 
    {
		new ShaderTagId("Always"),
		new ShaderTagId("ForwardBase"),
		new ShaderTagId("PrepassBase"),
		new ShaderTagId("Vertex"),
		new ShaderTagId("VertexLMRGBM"),
		new ShaderTagId("VertexLM")
	};

    static Material errorMaterial;

    partial void DrawUnsupportedShaders() 
    {   
        if (errorMaterial == null) 
        {
            errorMaterial = new Material(Shader.Find("Hidden/InternalErrorShader"));
        }

        var sortingSettings = new SortingSettings(camera);
		var drawingSettings = new DrawingSettings(legacyShaderTagIds[0], sortingSettings)
        {
            overrideMaterial = errorMaterial
        };
		for (int i = 1; i < legacyShaderTagIds.Length; i++) 
        {
			drawingSettings.SetShaderPassName(i, legacyShaderTagIds[i]);
		}
		var filteringSettings = FilteringSettings.defaultValue;
		context.DrawRenderers(cullingResults, ref drawingSettings, ref filteringSettings);
	}

	partial void DrawGizmos() 
    {
		if (Handles.ShouldRenderGizmos()) {
			context.DrawGizmos(camera, GizmoSubset.PreImageEffects);
			context.DrawGizmos(camera, GizmoSubset.PostImageEffects);
		}
	}

    partial void PrepareForSceneWindow () 
    {
		if (camera.cameraType == CameraType.SceneView) 
        {
			ScriptableRenderContext.EmitWorldGeometryForSceneView(camera);
		}
	}

    partial void PrepareBuffer()
    {
        Profiler.BeginSample("Editor Only");
        SampleName = camera.name;
        buffer.name = SampleName;
        Profiler.EndSample();
    }

#else

    SampleName = bufferName;

#endif    

}
