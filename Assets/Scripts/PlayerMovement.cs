using UnityEngine;
using UnityEngine.InputSystem;

public class PlayerMovement : MonoBehaviour
{
    [SerializeField] private float speed, sprintBoost;
    [SerializeField] private CharacterController controller;    
    private InputSystem_Actions.PlayerActions input => InputManager.Instance.Player;
    private float currentSpeed;
    private void Start()
    {
        currentSpeed = speed;
        input.Sprint.performed += ctx => sprint(ctx);
        input.Sprint.canceled += ctx => sprint(ctx);
    }
    private void FixedUpdate()
    {
        Vector3 direction = input.Movement.ReadValue<Vector2>();
        Vector3 move = direction.x * transform.right + direction.y * transform.forward;
        controller.Move(move * Time.fixedDeltaTime * currentSpeed);
    }
    private void sprint(InputAction.CallbackContext ctx)
    {
        currentSpeed = ctx.canceled ? speed : speed * sprintBoost;
    }
}
