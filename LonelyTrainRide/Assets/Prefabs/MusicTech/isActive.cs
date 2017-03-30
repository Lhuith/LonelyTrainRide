using UnityEngine;
using System.Collections;

public class isActive : MonoBehaviour {
	public bool active;
	// Use this for initialization
	void Start () {
		transform.position = new Vector3 (transform.position.x + 1.25f,transform.position.y, transform.position.z);
		active = false;
	}
	
	// Update is called once per frame
	void Update () {
	
	}
}
