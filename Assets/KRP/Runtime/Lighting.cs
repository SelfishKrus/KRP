using Unity.Collections;
using UnityEngine;
using UnityEngine.Rendering;

public class Lighting
{   
    // ARGS // 

    const string bufferName = "Lighting";

	CommandBuffer buffer = new CommandBuffer 
    {
		name = bufferName
	};

    CullingResults cullingResults;

    const int maxDirLightCount = 4;

    static int
        dirLightCountId = Shader.PropertyToID("_DL_Count"),
        dirLightColorsId = Shader.PropertyToID("_DL_Colors"),
        dirLightDirectionsId = Shader.PropertyToID("_DL_Directions");

    static Vector4[]
        dirLightColors = new Vector4[maxDirLightCount],
        dirLightDirections = new Vector4[maxDirLightCount];
	
	void SetupDirectionalLight (int index, ref VisibleLight visibleLight) 
    {
		dirLightColors[index] = visibleLight.finalColor;
		dirLightDirections[index] = -visibleLight.localToWorldMatrix.GetColumn(2);
    }

    void SetupLights()
    {
        NativeArray<VisibleLight> visibleLights = cullingResults.visibleLights;
        int dirLightCount = 0;
        for (int i = 0; i < visibleLights.Length; i++) 
        {
			VisibleLight visibleLight = visibleLights[i];
            if (visibleLight.lightType == LightType.Directional)
            {
                SetupDirectionalLight(dirLightCount++, ref visibleLight);
                if (dirLightCount >= maxDirLightCount)  break;
            }
		}

		buffer.SetGlobalInt(dirLightCountId, visibleLights.Length);
		buffer.SetGlobalVectorArray(dirLightColorsId, dirLightColors);
		buffer.SetGlobalVectorArray(dirLightDirectionsId, dirLightDirections);
    }

    // MAIN // 

    public void Setup (ScriptableRenderContext context, CullingResults cullingResults) 
    {   
        this.cullingResults = cullingResults;
		buffer.BeginSample(bufferName);
		SetupLights();
		buffer.EndSample(bufferName);
		context.ExecuteCommandBuffer(buffer);
		buffer.Clear();
	}
}
