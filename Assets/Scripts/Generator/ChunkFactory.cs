using UnityEngine;

public class ChunkFactory
{
    private readonly GameObject[] prefabs;

    public ChunkFactory(GameObject[] prefabs)
    {
        this.prefabs = prefabs;
    }

    public Chunk Create(Port port)
    {
        GameObject instance = Object.Instantiate(
            prefabs[Random.Range(0, prefabs.Length)],
            port.transform.position,
            port.transform.rotation *
            Quaternion.Euler(
                0f,
                Random.Range(-port.RotationRange, port.RotationRange),
                0f));

        Chunk chunk = instance.GetComponent<Chunk>();

        port.Connect(chunk);

        return chunk;
    }
}