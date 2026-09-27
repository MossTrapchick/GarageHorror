using UnityEngine;

public class Door : MonoBehaviour
{
    [SerializeField] Material[] materials;
    [SerializeField] Renderer renderer;
    void Start()
    {
        renderer.material = materials[Random.Range(0,materials.Length)];
    }
}
