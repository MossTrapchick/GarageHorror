using UnityEngine;

public class Chunk : MonoBehaviour
{
    [SerializeField] private Port enter;

    public Port Enter => enter;
}