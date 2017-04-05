using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Train_Manager : MonoBehaviour {


    public GameObject[] children;

    [Range(0, 100)]
    public float speed = 0;

    [Range(0.00f, 1.00f)]
    public float speedDamp = 0;

    // Use this for initialization
    void Start ()
    {
		
	}
	
	// Update is called once per frame
	void Update ()
    {

        Vector3 finalSpeed = new Vector3(0, 0, 5.25f) * Time.deltaTime * speed;
        Vector3 childSpeed = finalSpeed * speedDamp;

        for (int i = 0; i < children.Length; i++)
            children[i].transform.GetComponent<Rigidbody>().AddForce(-childSpeed, ForceMode.Acceleration);

        transform.position += new Vector3(0, 0, 5.25f) * Time.deltaTime * speed;
	}
}
