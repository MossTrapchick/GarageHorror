using UnityEngine;

public class Rake : MonoBehaviour
{
    [SerializeField] float speed;
    [SerializeField] CharacterController controller;
    static Transform player;
    private void Start()
    {
        player = GameObject.FindGameObjectWithTag("Player").transform;
    }
    private void FixedUpdate()
    {
        Vector3 direction = player.position - transform.position;
        direction.y = transform.position.y;
        controller.Move(direction.normalized * speed * Time.fixedDeltaTime);
        transform.LookAt(player.position);
    }
}
