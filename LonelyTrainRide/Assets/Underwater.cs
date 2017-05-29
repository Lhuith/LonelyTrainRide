using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Underwater : MonoBehaviour {


    public Material UnderWater;
    public int iterations;
    private RenderTexture UnderWaterTex;

	// Update is called once per frame
	void Update ()
    {
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Graphics.Blit(source, destination, UnderWater);
    }
}
