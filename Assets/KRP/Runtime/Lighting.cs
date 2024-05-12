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
            otherLightPositionsId = Shader.PropertyToID("_OL_Positions"),
            otherLightDirectionsId = Shader.PropertyToID("_OL_Directions"),
            otherLightSpotAnglesId = Shader.PropertyToID("_OL_SpotAngles"),
            otherLightShadowDataId = Shader.PropertyToID("_OL_ShadowData");

        static Vector4[]
            otherLightColors = new Vector4[maxOtherLightCount],
            otherLightPositions = new Vector4[maxOtherLightCount],
            otherLightDirections = new Vector4[maxOtherLightCount],
            otherLightSpotAngles = new Vector4[maxOtherLightCount],
            otherLightShadowData = new Vector4[maxOtherLightCount];

        Shadows shadows = new Shadows();

        static string lightsPerObjectKeyword = "_LIGHTS_PER_OBJECT";

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
            otherLightSpotAngles[index] = new Vector4(0f, 1f);
            Light light = visibleLight.light;
            otherLightShadowData[index] = shadows.ReserveOtherShadows(light, index);
        }

        void SetupSpotLight(int index, ref VisibleLight visibleLight)
        {
            otherLightColors[index] = visibleLight.finalColor;
            Vector4 position = visibleLight.localToWorldMatrix.GetColumn(3);
            position.w =
                1f / Mathf.Max(visibleLight.range * visibleLight.range, 0.00001f);
            otherLightPositions[index] = position;
            otherLightDirections[index] =
                -visibleLight.localToWorldMatrix.GetColumn(2);

            Light light = visibleLight.light;
            float innerCos = Mathf.Cos(Mathf.Deg2Rad * 0.5f * light.innerSpotAngle);
            float outerCos = Mathf.Cos(Mathf.Deg2Rad * 0.5f * visibleLight.spotAngle);
            float angleRangeInv = 1f / Mathf.Max(innerCos - outerCos, 0.001f);
            otherLightSpotAngles[index] = new Vector4(angleRangeInv, -outerCos * angleRangeInv);
            otherLightShadowData[index] = shadows.ReserveOtherShadows(light, index);
        }

        void SetupLights(bool useLightsPerObject)
        {
            NativeArray<int> indexMap = useLightsPerObject ? cullingResults.GetLightIndexMap(Allocator.Temp) : default;
            NativeArray<VisibleLight> visibleLights = cullingResults.visibleLights;
            int dirLightCount = 0, otherLightCount = 0;
            int i;
            for (i = 0; i < visibleLights.Length; i++)
            {
                int newIndex = -1;
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
                            newIndex = otherLightCount;
                            SetupPointLight(otherLightCount++, ref visibleLight);
                        }
                        break;

                    case LightType.Spot:
                        if (otherLightCount < maxOtherLightCount)
                        {
                            newIndex = otherLightCount;
                            SetupSpotLight(otherLightCount++, ref visibleLight);
                        }
                        break;
                }

                if (useLightsPerObject)
                {
                    indexMap[i] = newIndex;
                }
            }

            // to eliminate the indices of the invisible lights 
            if (useLightsPerObject)
            {
                for (; i < indexMap.Length; i++)
                {
                    indexMap[i] = -1;
                }

                cullingResults.SetLightIndexMap(indexMap);
                indexMap.Dispose();
                Shader.EnableKeyword(lightsPerObjectKeyword);
            }
            else
            {
                Shader.DisableKeyword(lightsPerObjectKeyword);
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
                buffer.SetGlobalVectorArray(otherLightDirectionsId, otherLightDirections);
                buffer.SetGlobalVectorArray(otherLightSpotAnglesId, otherLightSpotAngles);
                buffer.SetGlobalVectorArray(otherLightShadowDataId, otherLightShadowData);
            }
        }

        public void Cleanup()
        {
            shadows.Cleanup();
        }

        // MAIN // 
        public void Setup(ScriptableRenderContext context, CullingResults cullingResults, ShadowSettings shadowSettings, bool useLightsPerObject)
        {
            this.cullingResults = cullingResults;
            buffer.BeginSample(bufferName);
            shadows.Setup(context, cullingResults, shadowSettings);
            SetupLights(useLightsPerObject);

            shadows.Render();
            buffer.EndSample(bufferName);
            context.ExecuteCommandBuffer(buffer);
            buffer.Clear();
        }

        #endregion
    }

}
