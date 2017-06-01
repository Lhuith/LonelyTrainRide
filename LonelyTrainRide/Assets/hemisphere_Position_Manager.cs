using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class hemisphere_Position_Manager : MonoBehaviour {

    public Transform followTarget;

	// Use this for initialization
	void Start ()
    {
		
	}
	
	// Update is called once per frame
	void Update ()
    {
        transform.position = new Vector3(followTarget.position.x, followTarget.position.y, followTarget.position.z);

    }
}
