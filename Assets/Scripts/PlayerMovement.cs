using UnityEngine;
using UnityEngine.InputSystem;

public class PlayerMovement : MonoBehaviour
{
    [SerializeField] private float speed;
    [SerializeField] private CharacterController controller;    
    private InputAction Movement => InputManager.Instance.Player.Movement;
    private void FixedUpdate()
    {
        Vector3 direction = Movement.ReadValue<Vector2>();
        Vector3 move = direction.x * transform.right + direction.y * transform.forward;
        controller.Move(move * Time.fixedDeltaTime * speed);
    }
}
