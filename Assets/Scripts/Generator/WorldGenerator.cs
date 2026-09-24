using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine; 

public class WorldGenerator : MonoBehaviour
{
    [SerializeField] private GameObject[] chunkPrefabs;
    [SerializeField] private Transform player;
    [SerializeField] private int rayCount = 360, loadDistance = 20;
    LayerMask mask;
    List<GameObject> chunks = new();
    private void Start()
    {
        mask = LayerMask.GetMask("Wall");
        StartCoroutine(cycle());
    }
    IEnumerator cycle()
    {
        while (true)
        {
            checkVisible();
            yield return new WaitForSeconds(1f);
        }
    }
    void checkVisible()
    {
        List<GameObject> visiblePorts = new();
        float angle = 360f / rayCount;
        Vector3 direction;
        for (int i = 0; i < rayCount; i++)
        {
            direction = Quaternion.Euler(0, angle * i, 0) * Vector3.forward;
            visiblePorts = ray(visiblePorts, player.position, direction, loadDistance);
        }


        List<GameObject> visibleChunks = new();
        foreach (var port in visiblePorts.Select(p => p.GetComponent<Port>()))
            visibleChunks.AddRange(new GameObject[]{port.CurrentChunk, port.NextChunk});

        var toDelete = chunks.Except(visibleChunks).ToList();
        foreach(var chunk in toDelete) 
            Destroy(chunk);

        chunks = visibleChunks;
    }

    List<GameObject> ray(List<GameObject> visiblePorts, Vector3 origin,Vector3 direction, float distance)
    {
        if (Physics.Raycast(origin, direction, out var hit, distance, mask))
        {
            Debug.DrawRay(origin, direction * hit.distance, Color.red, 0.5f);
            if (!hit.collider.gameObject.CompareTag("Way")) return visiblePorts;
            
            if (!visiblePorts.Contains(hit.collider.gameObject))
            {
                visiblePorts.Add(hit.collider.gameObject);
                var port = hit.collider.gameObject.GetComponent<Port>();
                //generate
                if (port.NextChunk == null)
                    port.OnGenerate(port.CurrentChunk,Instantiate(
                        chunkPrefabs[UnityEngine.Random.Range(0, chunkPrefabs.Length)],
                        port.PlacePoint.position, port.PlacePoint.rotation));
            }
            visiblePorts = ray(visiblePorts, hit.point + direction * 0.05f, direction, Math.Clamp(distance - hit.distance, 0, loadDistance));
            
        }
        return visiblePorts;
    }
}
