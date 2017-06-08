using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Alpha_Fix : MonoBehaviour {
	
	public Transform Cam;

	// Use this for initialization
	void Start () {
		
	}
	
	// Update is called once per frame
	void LateUpdate () {
		//transform.rotation = Cam.rotation;
	}

	void Update () {
		//transform.rotation = Cam.rotation;
	}

	void FixedUpdate () {
		transform.rotation = Cam.rotation;
	}
}
