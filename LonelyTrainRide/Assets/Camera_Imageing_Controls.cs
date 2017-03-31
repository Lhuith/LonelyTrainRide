using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Camera_Imageing_Controls : MonoBehaviour {

	// Use this for initialization
	void Enable ()
    {
        Camera.main.depthTextureMode = DepthTextureMode.Depth;
	}
	
	// Update is called once per frame
	void Update () {
		
	}
}
