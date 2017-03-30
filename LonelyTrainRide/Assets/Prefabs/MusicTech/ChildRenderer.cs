using UnityEngine;
using System.Collections;

public class ChildRenderer : MonoBehaviour {
	public GOF_Cube parType;
	public MeshRenderer meshRend;
	public int parTypeInt;
	// Use this for initialization
	void Start () {
		parType = transform.parent.GetComponent<GOF_Cube>();
		meshRend = GetComponent<MeshRenderer> ();
	}
	
	// Update is called once per frame
	void Update () {
}
}
