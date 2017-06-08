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
            if(GetComponent<SunShafts>().sunShaftIntensity != intensSave)
            GetComponent<SunShafts>().sunShaftIntensity = Mathf.Lerp(GetComponent<SunShafts>().sunShaftIntensity, intensSave, Time.deltaTime);
        }
        else if (cosAngle > 0)
        {
            if (GetComponent<SunShafts>().sunShaftIntensity > 1)
                GetComponent<SunShafts>().sunShaftIntensity = Mathf.Lerp(GetComponent<SunShafts>().sunShaftIntensity, 1, Time.deltaTime);
		}
		
	}
}
