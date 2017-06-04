using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Reflection_Probe_Update : MonoBehaviour {

    ReflectionProbe probe;
    public int probeIterations;

    void Awake()
    {
        probe = GetComponent<ReflectionProbe>();
    }

    void Update()
    {
        probe.transform.position = new Vector3(
            Camera.main.transform.position.x,
            Camera.main.transform.position.y,
            Camera.main.transform.position.z
        );

        for(int i = 0; i < probeIterations; i++)
        probe.RenderProbe();
    }
}
