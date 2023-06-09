using UnityEngine;


[ExecuteInEditMode]
[DisallowMultipleComponent]
public class PerObjectMaterialProperties : MonoBehaviour
{
    void Start() {
        OnValidate();
    }

    static int 
        baseColorId = Shader.PropertyToID("_BaseColor"),
        cutoffId = Shader.PropertyToID("_Cutoff"),
        metallicId = Shader.PropertyToID("_Metallic"),
        smoothnessId = Shader.PropertyToID("_Smoothness");
    
    static MaterialPropertyBlock block;

    [SerializeField]
    Color baseColor = Color.white;


    [SerializeField, Range(0, 1f)]
    float cutoff = 0.5f, metallic = 0f, smoothness = 0.5f;

    void OnValidate() {

        if (block == null) {
            block = new MaterialPropertyBlock();
        }

        // baseColor = new Color(Random.value, Random.value, Random.value);

        block.SetColor(baseColorId, baseColor);
        block.SetFloat(cutoffId, cutoff);
        block.SetFloat(metallicId, metallic);
        block.SetFloat(smoothnessId, smoothness);

        var renderer = GetComponent<Renderer>();
        renderer.SetPropertyBlock(block);
    }
}


