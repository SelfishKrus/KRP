using UnityEngine;


[ExecuteInEditMode]
[DisallowMultipleComponent]
public class PerObjectMaterialProperties : MonoBehaviour
{
    void Start() {
        OnValidate();
    }

    static int baseColorId = Shader.PropertyToID("_BaseColor");  
    static MaterialPropertyBlock block;

    [SerializeField]
    Color baseColor = Color.white;

    void OnValidate() {

        if (block == null) {
            block = new MaterialPropertyBlock();
        }

        baseColor = new Color(Random.value, Random.value, Random.value);

        block.SetColor(baseColorId, baseColor);
        var renderer = GetComponent<Renderer>();
        renderer.SetPropertyBlock(block);
        
    }
}


