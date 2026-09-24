using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WorldGenerator : MonoBehaviour
{
    [SerializeField] private GameObject[] chunkPrefabs;
    [SerializeField] private Transform player;
    [SerializeField] private int rayCount = 360;
    [SerializeField] private float loadDistance = 20f, updateRate = 1f;

    private LayerMask wallMask;
    private HashSet<Chunk> activeChunks = new();

    private void Start()
    {
        wallMask = LayerMask.GetMask("Wall");
        StartCoroutine(UpdateWorld());
    }

    private IEnumerator UpdateWorld()
    {
        while (true)
        {
            UpdateVisibility();
            yield return new WaitForSeconds(updateRate);
        }
    }

    private void UpdateVisibility()
    {
        HashSet<Port> ports = new();

        for (int i = 0; i < rayCount; i++)
        {
            Vector3 direction =
                Quaternion.Euler(0f, 360f / rayCount * i, 0f) * Vector3.forward;

            TraceRay(ports, player.position, direction, loadDistance);
        }

        HashSet<Chunk> visibleChunks = new();

        foreach (Port port in ports)
        {
            visibleChunks.Add(port.CurrentChunk);

            if (port.NextChunk != null)
                visibleChunks.Add(port.NextChunk);
        }

        foreach (Chunk chunk in activeChunks)
            if (!visibleChunks.Contains(chunk))
                Destroy(chunk.gameObject);

        activeChunks = visibleChunks;
    }

    private void TraceRay(
        HashSet<Port> ports,
        Vector3 origin,
        Vector3 direction,
        float distance)
    {
        if (!Physics.Raycast(origin, direction, out RaycastHit hit, distance, wallMask))
            return;

        Debug.DrawRay(origin, direction * hit.distance, Color.red, updateRate/2f);

        if (!hit.collider.CompareTag("Port"))
            return;

        Port port = hit.collider.GetComponent<Port>();

        if (ports.Add(port))
        {
            if (port.NextChunk == null)
            {
                GameObject chunk = Instantiate(
                    chunkPrefabs[Random.Range(0, chunkPrefabs.Length)],
                    port.transform.position,
                    port.transform.rotation * Quaternion.Euler(0, Random.Range(-port.RotationRange, port.RotationRange), 0));

                port.Connect(chunk.GetComponent<Chunk>());
            }
        }

        TraceRay(
            ports,
            hit.point + direction * 0.05f,
            direction,
            distance - hit.distance);
    }
}
