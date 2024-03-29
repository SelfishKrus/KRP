// using System.Numerics;
using UnityEngine;
using UnityEngine.Rendering;

public class Shadows
{
    const string bufferName = "Shadows";

    CommandBuffer buffer = new CommandBuffer
    {
        name = bufferName
    };

    void ExecuteBuffer()
    {
        context.ExecuteCommandBuffer(buffer);
        buffer.Clear();
    }


    
    ScriptableRenderContext context;

    CullingResults cullingResults;

    ShadowSettings shadowSettings;

    const int maxShadowedDirectionalLightCount = 4, maxCascades = 4;
    int shadowedDirectionalLightCount;

    static int 
        dirShadowAtlasId = Shader.PropertyToID("_DL_ShadowAtlas"),
        dirShadowMatricesId = Shader.PropertyToID("_DL_ShadowMatrices"),
        cascadeCountId = Shader.PropertyToID("_CascadeCount"),
        cascadeCullingSpheresId = Shader.PropertyToID("_CascadeCullingSpheres"),
        shadowDistanceId = Shader.PropertyToID("_ShadowDistance");

    static Vector4[] cascadeCullingSpheres = new Vector4[maxCascades];

    static Matrix4x4[] dirShadowMatrices = new Matrix4x4[maxShadowedDirectionalLightCount * maxCascades];
    

    public void Setup(
        ScriptableRenderContext context, 
        CullingResults cullingResults,
        ShadowSettings shadowSettings)
    {
        this.context = context;
        this.cullingResults = cullingResults;
        this.shadowSettings = shadowSettings;
        shadowedDirectionalLightCount = 0;
    }

    struct ShadowedDirectionalLight
    {
        public int visibleLightIndex;
    }

    ShadowedDirectionalLight[] shadowedDirectionalLights = 
        new ShadowedDirectionalLight[maxShadowedDirectionalLightCount];

    public Vector2 ReserveDirectionalShadows (Light light, int visibleLightIndex) 
    {
        if (shadowedDirectionalLightCount < maxShadowedDirectionalLightCount && 
            light.shadows != LightShadows.None && 
            light.shadowStrength > 0f &&
            cullingResults.GetShadowCasterBounds(visibleLightIndex, out Bounds b))
        {
            shadowedDirectionalLights[shadowedDirectionalLightCount] = new ShadowedDirectionalLight 
                {
                    visibleLightIndex = visibleLightIndex
                };
            return new Vector2(
                light.shadowStrength, 
                shadowSettings.directional.cascadeCount * shadowedDirectionalLightCount++);   
        }
        return Vector2.zero;

    }

    Vector2 SetTileViewport (int index, int split, float tileSize) 
    {
		Vector2 offset = new Vector2(index % split, index / split);
		buffer.SetViewport(new Rect(offset.x * tileSize, offset.y * tileSize, tileSize, tileSize));
        return offset;
	}

    Matrix4x4 ConvertToAtlasMatrix(Matrix4x4 m, Vector2 offset, int split)
    {   
        if (SystemInfo.usesReversedZBuffer)
        {
            m.m20 = -m.m20;
            m.m21 = -m.m21;
            m.m22 = -m.m22;
            m.m23 = -m.m23;
        }

        // offset the projection matrix to align texels with pixels
        // and scale and bias from [-1,1] to [0,1]
        float scale = 1f / split;
		m.m00 = (0.5f * (m.m00 + m.m30) + offset.x * m.m30) * scale;
		m.m01 = (0.5f * (m.m01 + m.m31) + offset.x * m.m31) * scale;
		m.m02 = (0.5f * (m.m02 + m.m32) + offset.x * m.m32) * scale;
		m.m03 = (0.5f * (m.m03 + m.m33) + offset.x * m.m33) * scale;
		m.m10 = (0.5f * (m.m10 + m.m30) + offset.y * m.m30) * scale;
		m.m11 = (0.5f * (m.m11 + m.m31) + offset.y * m.m31) * scale;
		m.m12 = (0.5f * (m.m12 + m.m32) + offset.y * m.m32) * scale;
		m.m13 = (0.5f * (m.m13 + m.m33) + offset.y * m.m33) * scale;
		m.m20 = 0.5f * (m.m20 + m.m30);
		m.m21 = 0.5f * (m.m21 + m.m31);
		m.m22 = 0.5f * (m.m22 + m.m32);
		m.m23 = 0.5f * (m.m23 + m.m33);
        return m;
    }

    void RenderDirectionalShadows (int index, int split, int tileSize)
    {
        ShadowedDirectionalLight light = shadowedDirectionalLights[index];
		var _shadowSettings = new ShadowDrawingSettings(
            cullingResults, 
            light.visibleLightIndex);
        int cascadeCount = shadowSettings.directional.cascadeCount;
        int tileOffset = index * cascadeCount;
        Vector3 ratios = shadowSettings.directional.CascadeRatios;

        for (int i = 0; i < cascadeCount; i++)
        {
            cullingResults.ComputeDirectionalShadowMatricesAndCullingPrimitives(
                light.visibleLightIndex, i, cascadeCount, ratios, tileSize, 0f,
                out Matrix4x4 viewMatrix, out Matrix4x4 projectionMatrix,
                out ShadowSplitData splitData);
            _shadowSettings.splitData = splitData;
            // only needed for the first light as the cascades of all lights are equivalent
            if (index == 0) 
            {   
                // Squared distance
                Vector4 cullingSphere = splitData.cullingSphere;
                cullingSphere.w *= cullingSphere.w;
                cascadeCullingSpheres[i] = cullingSphere;
            }
            int tileIndex = tileOffset + i;
            dirShadowMatrices[tileIndex] = ConvertToAtlasMatrix(
                projectionMatrix * viewMatrix, 
                SetTileViewport(tileIndex, split, tileSize), 
                split);
            buffer.SetViewProjectionMatrices(viewMatrix, projectionMatrix);
            ExecuteBuffer();
            context.DrawShadows(ref _shadowSettings);
        }
    }

    void RenderDirectionalShadows()
    {
        int atlasSize = (int)shadowSettings.directional.atlasSize;
        buffer.GetTemporaryRT(
            dirShadowAtlasId, atlasSize, atlasSize, 
            32, FilterMode.Bilinear, RenderTextureFormat.Shadowmap);
        buffer.SetRenderTarget(dirShadowAtlasId, RenderBufferLoadAction.DontCare, RenderBufferStoreAction.Store);
        buffer.ClearRenderTarget(true, false, Color.clear);
        buffer.BeginSample(bufferName);
        ExecuteBuffer();

        int tiles = shadowedDirectionalLightCount * shadowSettings.directional.cascadeCount;
        int split = tiles <= 1 ? 1 : tiles <= 4 ? 2 : 4;
        int tileSize = atlasSize / split;

        for (int i = 0; i < shadowedDirectionalLightCount; i++) 
        {
			RenderDirectionalShadows(i, split, tileSize);
		}
		buffer.SetGlobalInt(cascadeCountId, shadowSettings.directional.cascadeCount);
        buffer.SetGlobalVectorArray(cascadeCullingSpheresId, cascadeCullingSpheres);
        buffer.SetGlobalMatrixArray(dirShadowMatricesId, dirShadowMatrices);
        buffer.SetGlobalFloat(shadowDistanceId, shadowSettings.maxDistance);
		buffer.EndSample(bufferName);
		ExecuteBuffer();
    }

    public void Render()
    {
        if (shadowedDirectionalLightCount > 0)
        {
            RenderDirectionalShadows();
        }
        else
        {
            buffer.GetTemporaryRT(
                dirShadowAtlasId, 1, 1, 
                32, FilterMode.Bilinear, RenderTextureFormat.Shadowmap);
        }
    }

    public void Cleanup()
    {
        buffer.ReleaseTemporaryRT(dirShadowAtlasId);
        ExecuteBuffer();
    }

}
