using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityStandardAssets.ImageEffects;

public class BloomFix : MonoBehaviour {

    public GameObject Sun;
    private float intensSave;
	// Use this for initialization
	void Start ()
    {
        intensSave = GetComponent<Bloom>().bloomThreshold;

    }

    // Update is called once per frame
    void Update()
    {
        float cosAngle = Vector3.Dot(Vector3.up, -Sun.transform.forward);

        if (cosAngle < 0)
        {
            GetComponent<Bloom>().bloomThreshold = 0;
        }
        else
        {
            GetComponent<Bloom>().bloomThreshold = intensSave;
        }
    }
}
