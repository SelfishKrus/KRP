using Unity.Collections;
using UnityEngine;
using UnityEngine.Rendering;

namespace KRP
{
    public class Lighting
    {
        #region ARGS

        const string bufferName = "Lighting";

        CommandBuffer buffer = new CommandBuffer
        {
            name = bufferName
        };

        CullingResults cullingResults;

        const int maxDirLightCount = 4, maxOtherLightCount = 64;

        static int
            dirLightCountId = Shader.PropertyToID("_DL_Count"),
            dirLightColorsId = Shader.PropertyToID("_DL_Colors"),
            dirLightDirectionsId = Shader.PropertyToID("_DL_Directions"),
            dirLightShadowDataId = Shader.PropertyToID("_DL_ShadowData");

        static Vector4[]
            dirLightColors = new Vector4[maxDirLightCount],
            dirLightDirections = new Vector4[maxDirLightCount],
            dirLightShadowData = new Vector4[maxDirLightCount];

        static int
            otherLightCountId = Shader.PropertyToID("_OL_Count"),
            otherLightColorsId = Shader.PropertyToID("_OL_Colors"),
            otherLightPositionsId = Shader.PropertyToID("_OL_Positions");

        static Vector4[]
            otherLightColors = new Vector4[maxOtherLightCount],
            otherLightPositions = new Vector4[maxOtherLightCount];

        Shadows shadows = new Shadows();

        #endregion

        #region METHODS

        void SetupDirectionalLight(int index, ref VisibleLight visibleLight)
        {
            dirLightColors[index] = visibleLight.finalColor;
            dirLightDirections[index] = -visibleLight.localToWorldMatrix.GetColumn(2);
            dirLightShadowData[index] = shadows.ReserveDirectionalShadows(visibleLight.light, index);
        }

        void SetupPointLight(int index, ref VisibleLight visibleLight)
        {
            otherLightColors[index] = visibleLight.finalColor;
            Vector4 position = visibleLight.localToWorldMatrix.GetColumn(3);
            position.w = 1f / Mathf.Max(visibleLight.range * visibleLight.range, 0.00001f);
            otherLightPositions[index] = position;
        }

        void SetupLights()
        {
            NativeArray<VisibleLight> visibleLights = cullingResults.visibleLights;
            int dirLightCount = 0, otherLightCount = 0;
            for (int i = 0; i < visibleLights.Length; i++)
            {
                VisibleLight visibleLight = visibleLights[i];
                switch (visibleLight.lightType)
                {
                    case LightType.Directional:
                        if (dirLightCount < maxDirLightCount)
                        {
                            SetupDirectionalLight(dirLightCount++, ref visibleLight);
                        }
                        break;

                    case LightType.Point:
                        if (otherLightCount < maxOtherLightCount)
                        {
                            SetupPointLight(otherLightCount++, ref visibleLight);
                        }
                        break;
                }
            }

            buffer.SetGlobalInt(dirLightCountId, visibleLights.Length);
            if (dirLightCount > 0)
            {
                buffer.SetGlobalVectorArray(dirLightColorsId, dirLightColors);
                buffer.SetGlobalVectorArray(dirLightDirectionsId, dirLightDirections);
                buffer.SetGlobalVectorArray(dirLightShadowDataId, dirLightShadowData);
            }

            buffer.SetGlobalInt(otherLightCountId, otherLightCount);
            if (otherLightCount > 0)
            {
                buffer.SetGlobalVectorArray(otherLightColorsId, otherLightColors);
                buffer.SetGlobalVectorArray(otherLightPositionsId, otherLightPositions);
            }
        }

        public void Cleanup()
        {
            shadows.Cleanup();
        }

        // MAIN // 
        public void Setup(ScriptableRenderContext context, CullingResults cullingResults, ShadowSettings shadowSettings)
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

        #endregion
    }

}
