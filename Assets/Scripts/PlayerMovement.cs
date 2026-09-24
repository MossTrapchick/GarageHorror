using UnityEngine;
using UnityEngine.InputSystem;

public class PlayerMovement : MonoBehaviour
{
    [SerializeField] private float speed, sprintBoost, jumpForce;
    [SerializeField] private CharacterController controller;  
    private InputSystem_Actions.PlayerActions input => InputManager.Instance.Player;
    private float currentSpeed;
    [SerializeField] private Vector3 horisontalVelocity = Vector3.down;
    private void Start()
    {
        currentSpeed = speed;
        input.Sprint.performed += ctx => sprint(ctx);
        input.Sprint.canceled += ctx => sprint(ctx);
        input.Jump.performed += ctx => jump(ctx);
    }
    private void FixedUpdate()
    {
        Vector3 direction = input.Movement.ReadValue<Vector2>();
        Vector3 move = direction.x * transform.right + direction.y * transform.forward;
        controller.Move((move * currentSpeed + horisontalVelocity) * Time.fixedDeltaTime);
        if (!controller.isGrounded) horisontalVelocity.y += -9.81f * 0.1f;
        else horisontalVelocity.y = -1;
    }
    private void sprint(InputAction.CallbackContext ctx)
    {
        currentSpeed = ctx.canceled ? speed : speed * sprintBoost;
    }
    private void jump(InputAction.CallbackContext ctx)
    {
        if (!controller.isGrounded) return;
        horisontalVelocity.y += jumpForce;
    }
}
