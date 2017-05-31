using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FrameSampler : MonoBehaviour {


    private RenderTexture FrameSamplerTexture;
    private Material mat;
	// Use this for initialization
	void Start ()
    {
        if (FrameSamplerTexture == null) FrameSamplerTexture = new RenderTexture(1026, 1028, 26);
        mat = GetComponent<MeshRenderer>().material;
        mat.SetTexture("_FrameSampler", FrameSamplerTexture);

    }
	
    void UpdateWater()
    {
        RenderTexture tmp = RenderTexture.GetTemporary(1028, 1028, 26);
        Graphics.Blit(FrameSamplerTexture, tmp, mat);
        Graphics.Blit(tmp, FrameSamplerTexture);

        tmp.Release();
    }

	// Update is called once per frame
	void Update ()
    {
        UpdateWater();
    }
}
