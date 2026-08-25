using UnityEngine;

namespace SpaceExtra
{
    /// <summary>
    /// Utility component for continuous object/prop rotation (e.g., fan blades, industrial turbines).
    /// Supports local and world coordinate spaces, speed control, and smooth acceleration damping.
    /// </summary>
    [AddComponentMenu("SpaceExtra/Fan Rotator")]
    public class FanRotator : MonoBehaviour
    {
        public enum RotationAxis
        {
            X,
            Y,
            Z,
            Custom
        }

        [Header("Axis & Space")]
        [Tooltip("Axis of rotation")]
        [SerializeField] private RotationAxis axis = RotationAxis.Z;

        [Tooltip("Custom rotation axis vector (used when axis is set to Custom)")]
        [SerializeField] private Vector3 customAxis = Vector3.forward;

        [Tooltip("Rotate in local space (true) or world space (false)")]
        [SerializeField] private bool useLocalSpace = true;

        [Header("Speed & State")]
        [Tooltip("Rotation speed in degrees per second. Negative values rotate in reverse.")]
        [SerializeField] private float speed = 360f;

        [Tooltip("Whether the rotation is currently active")]
        [SerializeField] private bool isSpinning = true;

        [Header("Damping / Smoothness")]
        [Tooltip("Enable smooth acceleration and deceleration ramp")]
        [SerializeField] private bool smoothStartStop = true;

        [Tooltip("Time in seconds to reach full speed or come to a complete stop")]
        [SerializeField] private float accelerationTime = 1.0f;

        private float currentSpeed = 0f;

        public bool IsSpinning
        {
            get => isSpinning;
            set => isSpinning = value;
        }

        public float Speed
        {
            get => speed;
            set => speed = value;
        }

        private void Start()
        {
            if (!smoothStartStop)
            {
                currentSpeed = isSpinning ? speed : 0f;
            }
        }

        private void Update()
        {
            float targetSpeed = isSpinning ? speed : 0f;

            if (smoothStartStop && accelerationTime > 0f)
            {
                float step = (Mathf.Abs(speed) / accelerationTime) * Time.deltaTime;
                currentSpeed = Mathf.MoveTowards(currentSpeed, targetSpeed, step);
            }
            else
            {
                currentSpeed = targetSpeed;
            }

            if (Mathf.Approximately(currentSpeed, 0f)) return;

            Vector3 rotVector = GetRotationVector();
            float rotationAmount = currentSpeed * Time.deltaTime;

            if (useLocalSpace)
            {
                transform.Rotate(rotVector * rotationAmount, Space.Self);
            }
            else
            {
                transform.Rotate(rotVector * rotationAmount, Space.World);
            }
        }

        private Vector3 GetRotationVector()
        {
            return axis switch
            {
                RotationAxis.X => Vector3.right,
                RotationAxis.Y => Vector3.up,
                RotationAxis.Z => Vector3.forward,
                RotationAxis.Custom => customAxis.sqrMagnitude > 0.0001f ? customAxis.normalized : Vector3.forward,
                _ => Vector3.forward
            };
        }
    }
}
