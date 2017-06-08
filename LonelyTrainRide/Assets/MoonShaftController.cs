using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityStandardAssets.ImageEffects;

public class MoonShaftController : MonoBehaviour {

	public GameObject Sun;

	public float intensSave;
	// Use this for initialization
	void Start () 
	{
		intensSave = GetComponent<SunShafts>().sunShaftIntensity;
	}
	
	// Update is called once per frame
	void Update () 
	{
		float cosAngle = Vector3.Dot(Vector3.up, -Sun.transform.forward);

        if (cosAngle < 0)
        {
            //GetComponent<SunShafts>().enabled = true;
			GetComponent<SunShafts>().sunShaftIntensity = Mathf.Lerp(0, intensSave, Time.deltaTime * 40);
        }
		else
        {

		GetComponent<SunShafts>().sunShaftIntensity = 0;
           // GetComponent<SunShafts>().sunShaftIntensity = Mathf.Lerp(intensSave, 0, Time.deltaTime * 12);
		}
		
	}
}
