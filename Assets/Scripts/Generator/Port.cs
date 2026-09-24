using UnityEngine;

public class Port : MonoBehaviour
{
    [SerializeField, Range(0, 180)] private int rotationRange;
    [SerializeField] Material connectorMat;

    [SerializeField] private Chunk currentChunk;

    public int RotationRange => rotationRange;
    public Chunk CurrentChunk => currentChunk;
    public Chunk NextChunk { get; private set; }
    #region vertexes
    public Vector3 Left => transform.position + transform.forward * (transform.localScale.z / 2f);

    public Vector3 Right => transform.position - transform.forward * (transform.localScale.z / 2f);

    public Vector3 BottomLeft => Left - transform.up * (transform.localScale.y / 2f);

    public Vector3 BottomRight => Right - transform.up * (transform.localScale.y / 2f);

    public Vector3 TopLeft => Left + transform.up * (transform.localScale.y / 2f);

    public Vector3 TopRight => Right + transform.up * (transform.localScale.y / 2f);
    #endregion

    public void Connect(Chunk chunk)
    {
        NextChunk = chunk;
        chunk.Enter.NextChunk = currentChunk;
        Connector.Connect(this, chunk.Enter, connectorMat).transform.SetParent(currentChunk.transform, true);
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

        Gizmos.DrawCube(TopRight, new(0.1f, 0.1f, 0.1f));
        Gizmos.color = Color.red;
        Gizmos.DrawCube(TopLeft, new(0.1f, 0.1f, 0.1f));

    }
}