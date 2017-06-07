using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Train_Locomotion : MonoBehaviour {

    public GameObject[] Carts;
    public GameObject[] LockPoints;
    public Vector3 Direction;

    public Vector3 Offset;

    [Range(0, 100)]
    public float speed;

    public static float speedStatic;

    public float timecounter;
    public float width;
    public float height;
    public GameObject rotationPoint;
    // Use this for initialization
    void Start () {
		
	}

    // Update is called once per frame
    void Update()
    {
        timecounter = Time.deltaTime * speed;

        Vector3 newDir = Vector3.RotateTowards(transform.forward, transform.forward* 2, timecounter, 1.0F);
         //transform.rotation = Quaternion.LookRotation(newDir);
        //transform.position = new Vector3(x, 0, z);
        transform.RotateAround(rotationPoint.transform.position, Vector3.up ,timecounter);
        //transform.LookAt(-transform.forward);

        Carts[0].transform.position = LockPoints[0].transform.position;
        Carts[0].transform.rotation = Quaternion.Lerp(Carts[0].transform.rotation, transform.rotation, Time.deltaTime * speed);

        Carts[1].transform.position = LockPoints[1].transform.position;
        Carts[1].transform.rotation = Quaternion.Lerp(Carts[1].transform.rotation, Carts[0].transform.rotation, Time.deltaTime * speed);
    }
}
