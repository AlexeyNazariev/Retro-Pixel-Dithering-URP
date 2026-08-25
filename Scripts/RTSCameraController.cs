using UnityEngine;
using UnityEngine.InputSystem;

namespace SpaceExtra
{
    /// <summary>
    /// Fixed-elevation RTS camera controller powered by the Unity New Input System.
    /// Supports WASD/Arrow key panning and screen-edge panning.
    /// </summary>
    [AddComponentMenu("SpaceExtra/RTS Camera Controller")]
    public class RTSCameraController : MonoBehaviour
    {
        [Header("Movement Speed")]
        [Tooltip("Base camera panning speed")]
        [SerializeField] private float moveSpeed = 25f;

        [Tooltip("Speed multiplier when Left Shift or Right Shift is held")]
        [SerializeField] private float fastMoveMultiplier = 2f;

        [Tooltip("Movement interpolation smoothing factor")]
        [SerializeField] private float smoothing = 10f;

        [Header("Fixed Elevation")]
        [Tooltip("Fixed camera height (Y axis) above the ground plane")]
        [SerializeField] private float fixedHeight = 20f;

        [Header("Screen Edge Scrolling")]
        [Tooltip("Enable camera panning when the mouse cursor approaches screen edges")]
        [SerializeField] private bool enableEdgeScroll = true;

        [Tooltip("Border thickness in pixels from the screen edges that triggers panning")]
        [SerializeField] private float edgeScrollBorder = 15f;

        private Vector3 targetPosition;

        private void Start()
        {
            targetPosition = transform.position;
            targetPosition.y = fixedHeight;
            transform.position = targetPosition;
        }

        private void Update()
        {
            HandleMovement();

            targetPosition.y = fixedHeight;

            transform.position = Vector3.Lerp(transform.position, targetPosition, Time.deltaTime * smoothing);
        }

        private void HandleMovement()
        {
            Vector3 inputVector = Vector3.zero;
            var keyboard = Keyboard.current;

            if (keyboard != null)
            {
                if (keyboard.wKey.isPressed || keyboard.upArrowKey.isPressed) inputVector.z += 1f;
                if (keyboard.sKey.isPressed || keyboard.downArrowKey.isPressed) inputVector.z -= 1f;
                if (keyboard.aKey.isPressed || keyboard.leftArrowKey.isPressed) inputVector.x -= 1f;
                if (keyboard.dKey.isPressed || keyboard.rightArrowKey.isPressed) inputVector.x += 1f;
            }

            var mouse = Mouse.current;
            if (enableEdgeScroll && mouse != null)
            {
                Vector2 mousePos = mouse.position.ReadValue();
                if (mousePos.x >= Screen.width - edgeScrollBorder) inputVector.x += 1f;
                if (mousePos.x <= edgeScrollBorder) inputVector.x -= 1f;
                if (mousePos.y >= Screen.height - edgeScrollBorder) inputVector.z += 1f;
                if (mousePos.y <= edgeScrollBorder) inputVector.z -= 1f;
            }

            if (inputVector.sqrMagnitude > 0.01f)
            {
                inputVector.Normalize();

                Vector3 forward = transform.forward;
                forward.y = 0f;
                forward.Normalize();

                Vector3 right = transform.right;
                right.y = 0f;
                right.Normalize();

                Vector3 moveDirection = forward * inputVector.z + right * inputVector.x;

                float currentSpeed = moveSpeed;
                if (keyboard != null && (keyboard.leftShiftKey.isPressed || keyboard.rightShiftKey.isPressed))
                {
                    currentSpeed *= fastMoveMultiplier;
                }

                targetPosition += moveDirection * currentSpeed * Time.deltaTime;
            }
        }
    }
}
