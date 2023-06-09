using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MeshBall : MonoBehaviour {

    static int baseColorId = Shader.PropertyToID("_BaseColor");

    [SerializeField]
    Mesh mesh = default;

    [SerializeField]
    Material material = default;

    Matrix4x4[] matrices = new Matrix4x4[1023];
    Vector4[] baseColors = new Vector4[1023];

    MaterialPropertyBlock block;

    Vector3[] speherePos = new Vector3[1023];
    Quaternion[] sphereRot = new Quaternion[1023];
    Vector3[] sphereScale = new Vector3[1023];

    Vector3 goPos;


    void Awake() {
        for (int i=0; i<matrices.Length; i++) {
            speherePos[i] = Random.insideUnitSphere * 10f;
            sphereRot[i] = Quaternion.Euler(Random.value * 360f, Random.value * 360f, Random.value * 360f);
            sphereScale[i] = Vector3.one * Random.Range(0.5f, 1.5f);
        }
    }

    void Update () {

        goPos = transform.position;
        
        for (int i=0; i<matrices.Length; i++) {
            matrices[i] = Matrix4x4.TRS(
                speherePos[i] + goPos,
                sphereRot[i],
                sphereScale[i]
                );

            baseColors[i] = new Vector4(Random.value, Random.value, Random.value, Random.Range(0.5f, 1f));
        }

        if (block == null) {
            block = new MaterialPropertyBlock();
            block.SetVectorArray(baseColorId, baseColors);
        }


        Graphics.DrawMeshInstanced(mesh, 0, material, matrices, 1023, block);
    }

}
