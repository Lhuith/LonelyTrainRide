using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Head_Movement : MonoBehaviour {

    public Camera cam;

	// Use this for initialization
	void Start ()
    {
		
	}
	
	// Update is called once per frame
	void Update ()
    {
        transform.rotation = cam.transform.rotation;
	}
}
