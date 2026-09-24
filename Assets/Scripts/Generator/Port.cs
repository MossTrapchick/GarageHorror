using UnityEngine;

public class Port : MonoBehaviour
{
    [SerializeField] private Transform placePoint;
    public Transform PlacePoint => placePoint;
    [SerializeField] private GameObject currentChunk;
    public GameObject CurrentChunk { get => currentChunk; private set { currentChunk = value; } }
    public GameObject NextChunk {  get; private set; }
    public void OnGenerate(GameObject currentChunk, GameObject nextChunk)
    {
        NextChunk = nextChunk;
        nextChunk.GetComponent<Chunk>().Enter.NextChunk = currentChunk;
    }
    
}
