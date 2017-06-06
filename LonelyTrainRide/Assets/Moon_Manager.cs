using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Moon_Manager : MonoBehaviour {

    public Light Sun;

	// Use this for initialization
	void Start ()
    {
		
	}
	
	// Update is called once per frame
	void Update ()
    {
        this.GetComponent<Light>().intensity = (Sun.intensity / 100) * 12;

    }
}
