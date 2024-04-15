using UnityEngine;
using UnityEngine.Rendering;

public class Shadows
{

    const string bufferName = "Shadows";
    CommandBuffer buffer = new CommandBuffer
    {
        name = bufferName
    };
    ScriptableRenderContext context;
    CullingResults cullingResults;
    ShadowSettings settings;
    const int maxShadowedDirectionalLightCount = 1;
    int ShadowedDirectionalLightCount;

    struct ShadowedDirectionalLight
    {
        public int visibleLightIndex;
    }
    ShadowedDirectionalLight[] ShadowedDirectionalLights = new ShadowedDirectionalLight[maxShadowedDirectionalLightCount];
    public void ReserveDirectionalShadows(Light light, int visibleLightIndex) 
    {
        if (ShadowedDirectionalLightCount < maxShadowedDirectionalLightCount &&
            light.shadows != LightShadows.None && 
            light.shadowStrength > 0.0f &&
            cullingResults.GetShadowCasterBounds(visibleLightIndex, out Bounds b)) 
        {
            ShadowedDirectionalLights[ShadowedDirectionalLightCount++] =
                new ShadowedDirectionalLight {
                    visibleLightIndex = visibleLightIndex
                };
        }
    }

    public void Setup
    (
        ScriptableRenderContext context, CullingResults cullingResults,
        ShadowSettings settings
    )
    {
        this.context = context;
        this.cullingResults = cullingResults;
        this.settings = settings;
        ShadowedDirectionalLightCount = 0;
    }

    void ExecuteBuffer()
    {
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();
    }

    static int dirShadowAtlasId = Shader.PropertyToID("_DirectionalShadowAtlas");

    public void Render()
    {
        if (ShadowedDirectionalLightCount > 0)
        {
            RenderDirectionalShadows();
        }
        else
        {   
            //  dummy texture to avoid null reference exception
            buffer.GetTemporaryRT(
                dirShadowAtlasId, 1, 1,
                32, FilterMode.Bilinear, RenderTextureFormat.Shadowmap
            );
        }
    } 

    void RenderDirectionalShadows() 
    {
        int atlasSize = (int)settings.directional.atlasSize;
        buffer.GetTemporaryRT(
            dirShadowAtlasId, atlasSize, atlasSize,
            32, FilterMode.Bilinear, RenderTextureFormat.Shadowmap
        );
        buffer.SetRenderTarget(
			dirShadowAtlasId,
			RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store
		);
        buffer.ClearRenderTarget(true, false, Color.clear);

        buffer.BeginSample(bufferName);
        ExecuteBuffer();

        for (int i = 0; i < ShadowedDirectionalLightCount; i++)
        {
            RenderDirectionalShadows(i, atlasSize);
        }

        buffer.EndSample(bufferName);
        ExecuteBuffer();
    }

    // Overload for the single directional light
    void RenderDirectionalShadows (int index, int tileSize)
    {
        ShadowedDirectionalLight light = ShadowedDirectionalLights[index];
        var shadowSettings = new ShadowDrawingSettings(cullingResults, light.visibleLightIndex, BatchCullingProjectionType.Orthographic);
        cullingResults.ComputeDirectionalShadowMatricesAndCullingPrimitives(
            light.visibleLightIndex, 0, 1, Vector3.zero, tileSize, 0.0f, out Matrix4x4 viewMatrix, out Matrix4x4 projectionMatrix, out ShadowSplitData splitData
        );
        shadowSettings.splitData = splitData;
        buffer.SetViewProjectionMatrices(viewMatrix, projectionMatrix);
        ExecuteBuffer();
        context.DrawShadows(ref shadowSettings);
    }

    public void Cleanup()
    {
        buffer.ReleaseTemporaryRT(dirShadowAtlasId);
        ExecuteBuffer();
    }

}