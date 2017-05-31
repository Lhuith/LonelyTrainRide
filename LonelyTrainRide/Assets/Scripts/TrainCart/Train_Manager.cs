using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Train_Manager : MonoBehaviour {


    public GameObject[] children;

    [Range(0, 100)]
    public float speed = 0;

    [Range(0.00f, 2.00f)]
    public float speedDamp = 0;

    [Range(0, 3)]
    public float rumbleX = 0;

    [Range(0, 3)]
    public float rumbleY = 0;

    [Range(0, 3)]
    public float rumbleZ = 0;

    // Use this for initialization
    void Start ()
    {
		
	}
	
	// Update is called once per frame
	void Update ()
    {

        if(Input.GetKey(KeyCode.S))
        {
            transform.position -= new Vector3(0, 1, 0);
        }

        if (Input.GetKey(KeyCode.W))
        {
            transform.position += new Vector3(0, 1, 0);
        }

       //
       // Vector3 rotationRumble = new Vector3(Random.Range(0, rumbleX), Random.Range(0, rumbleY), Random.Range(0, rumbleZ));
       // Quaternion rotationRumpleQua = new Quaternion(0, 0, 0, 0);
       // rotationRumpleQua.eulerAngles += rotationRumble;
       //
       // Vector3 finalSpeed = new Vector3(0, 0, 5.25f) * Time.deltaTime * speed;
       // Vector3 childSpeed = (finalSpeed + rotationRumble * speedDamp) * speedDamp;
       //
       // for (int i = 0; i < children.Length; i++)
       //     children[Random.Range(0, children.Length)].transform.GetComponent<Rigidbody>().AddForce(-childSpeed, ForceMode.Acceleration);
       //
       // transform.position += new Vector3(0, 0, 5.25f) * Time.deltaTime * speed;
       //
       // transform.rotation = rotationRumpleQua;
    }
}
