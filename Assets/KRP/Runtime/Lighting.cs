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
        dirLightDirectionsId = Shader.PropertyToID("_DL_Directions"),
        dirLightShadowDataId = Shader.PropertyToID("_DL_ShadowData");

    static Vector4[]
        dirLightColors = new Vector4[maxDirLightCount],
        dirLightDirections = new Vector4[maxDirLightCount],
        dirLightShadowData = new Vector4[maxDirLightCount];
	
    // FUNC //

	void SetupDirectionalLight (int index, ref VisibleLight visibleLight) 
    {
		dirLightColors[index] = visibleLight.finalColor;
		dirLightDirections[index] = -visibleLight.localToWorldMatrix.GetColumn(2);
        dirLightShadowData[index] = shadows.ReserveDirectionalShadows(visibleLight.light, index);
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
        buffer.SetGlobalVectorArray(dirLightShadowDataId, dirLightShadowData);
    }

    public void Cleanup()
    {
        shadows.Cleanup();
    }

    // MAIN // 

    Shadows shadows = new Shadows();

    public void Setup (
        ScriptableRenderContext context, 
        CullingResults cullingResults,
        ShadowSettings shadowSettings) 
    {   
        this.cullingResults = cullingResults;
		buffer.BeginSample(bufferName);
        shadows.Setup(context, cullingResults, shadowSettings);
		SetupLights();
        shadows.Render();
		buffer.EndSample(bufferName);
		context.ExecuteCommandBuffer(buffer);
		buffer.Clear();
	}
}
