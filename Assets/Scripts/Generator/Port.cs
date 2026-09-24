using UnityEngine;

public class Port : MonoBehaviour
{
    [SerializeField, Range(0, 180)]
    private int rotationRange;

    [SerializeField]
    private Chunk currentChunk;

    public int RotationRange => rotationRange;
    public Chunk CurrentChunk => currentChunk;
    public Chunk NextChunk { get; private set; }

    public void Connect(Chunk chunk)
    {
        NextChunk = chunk;
        chunk.Enter.NextChunk = currentChunk;
    }

    private void OnDrawGizmos()
    {
        Gizmos.color = Color.blue;

        Gizmos.DrawRay(
            transform.position,
            Quaternion.Euler(0f, rotationRange, 0f) *
            transform.right * 3f);

        Gizmos.DrawRay(
            transform.position,
            Quaternion.Euler(0f, -rotationRange, 0f) *
            transform.right * 3f);
    }
}