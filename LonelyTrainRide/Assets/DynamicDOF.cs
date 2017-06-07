using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityStandardAssets.ImageEffects;

public class DynamicDOF : MonoBehaviour {

    public Vector3 target;
    public float targetDist;
    public DepthOfField dof;
    public float rayLen;

  
    // Use this for initialization
    void Start () {
        dof = GetComponent<DepthOfField>();
    }
	
	// Update is called once per frame
	void Update () {
		
	}

    void Aiming()
    {
        // Stores Camera's transform
        Transform camera = Camera.main.transform;

        // Stores hit data from Raycast
        RaycastHit hit;

        // Raycast parameters to pass to if statement
        Ray aim = new Ray(transform.position, camera.forward);

        // Returns Raycast's hit data and assigns its coordinates to target
        if (Physics.Raycast(aim, out hit, rayLen))
        {
            target = hit.point;
            targetDist = hit.distance;
            dof.focalLength = targetDist;
        }
        else
        {
            target = transform.position + camera.forward.normalized * rayLen;
        }
    }
}
