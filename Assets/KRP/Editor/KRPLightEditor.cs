using UnityEngine;
using UnityEditor;

namespace KRP
{
    [CanEditMultipleObjects]
    [CustomEditorForRenderPipeline(typeof(Light), typeof(KrusRenderPipelineAsset))]
    public class CustomLightEditor : LightEditor 
    {
        public override void OnInspectorGUI()
        {
            base.OnInspectorGUI();
            if (
                !settings.lightType.hasMultipleDifferentValues &&
                (LightType)settings.lightType.enumValueIndex == LightType.Spot
            )
            {
                settings.DrawInnerAndOuterSpotAngle();
                settings.ApplyModifiedProperties();
            }
        }
    }
}
