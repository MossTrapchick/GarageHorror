using UnityEngine;

public class InputManager : MonoBehaviour
{
    private static InputSystem_Actions instance;
    public static InputSystem_Actions Instance {  get { return instance; } }
    private void Awake()
    {
        DontDestroyOnLoad(gameObject);
        instance = new();
        instance.Enable();
    }
}
