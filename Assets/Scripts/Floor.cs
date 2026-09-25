using UnityEngine;

public class Floor : MonoBehaviour
{
    [SerializeField] Transform player;
    [SerializeField] Material mat;
    Renderer renderer;

    Vector2 offset = Vector2.zero;
    private void Start()
    {
        renderer = GetComponent<Renderer>();
    }
    private void Update()
    {
        Vector3 move = player.position;
        move.y = transform.position.y;
        transform.position = move;
    }
}
