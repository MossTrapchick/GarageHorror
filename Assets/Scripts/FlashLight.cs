using UnityEngine;

public class FlashLight : MonoBehaviour
{
    [SerializeField] Camera cam;
    void Update()
    {
        Vector3 dir = transform.position + cam.transform.forward * 50;
        transform.LookAt(dir);
    }
}
