using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Light_Controls : MonoBehaviour {
    public GameObject Sun;
    public float intensitySave;
    // Use this for initialization
    void Start ()
    {
        intensitySave = GetComponent<Light>().intensity;

    }
	
	// Update is called once per frame
	void Update ()
    {
        float cosAngle = Vector3.Dot(Vector3.up, -Sun.transform.forward);

        if (cosAngle < 0)
        {
            startLightOn();
        }
        else
        {
            Debug.Log("Turinging Off");
            startLightOff();
        }
    }

    void startLightOn()
    {
        if (GetComponent<Light>().intensity != intensitySave)
            GetComponent<Light>().intensity=  Mathf.Lerp(GetComponent<Light>().intensity, intensitySave, Time.deltaTime);
    }

    void startLightOff()
    {
        if (GetComponent<Light>().intensity > 1)
            GetComponent<Light>().intensity =   Mathf.Lerp(GetComponent<Light>().intensity, 1, Time.deltaTime);
    }
}
