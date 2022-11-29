using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SunCycle : MonoBehaviour
{
    Transform sunTransform;
    [SerializeField] float sunRotationSpeed = 10;

    private void Start()
    {
        sunTransform = GetComponent<Transform>();
    }

    private void Update()
    {
        sunTransform.Rotate(Vector3.down * (sunRotationSpeed * Time.deltaTime));
    }
}
