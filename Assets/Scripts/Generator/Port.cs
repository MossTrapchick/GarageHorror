using System.Collections.Generic;
using UnityEngine;

public class Port : MonoBehaviour
{
    [SerializeField] private Transform placePoint;
    public GameObject[] connectedChunks;
    public Transform PlacePoint => placePoint;
    public void OnGenerate(GameObject chunk)
    {
        //connectedChunks[0] присвоен текущему из инспектора
        connectedChunks[1] = chunk;
    }
}
