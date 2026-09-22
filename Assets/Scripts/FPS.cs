using Unity.Cinemachine;
using UnityEngine;
using UnityEngine.InputSystem;

public class FPS : MonoBehaviour
{
    [SerializeField] private CinemachinePanTilt cam;
    [SerializeField] private float speed;
    private InputAction look => InputManager.Instance.Player.Look;
    private void Start()
    {
        Cursor.lockState = CursorLockMode.Locked;
    }
    private void FixedUpdate()
    {
        Vector3 moveInput = look.ReadValue<Vector2>();
        moveInput = new(moveInput.x, 0, moveInput.y);
        Quaternion panRotation = Quaternion.Euler(0, cam.PanAxis.Value, 0);
        Vector3 moveDirection = panRotation * moveInput;
        transform.localRotation = panRotation;
    }
}
