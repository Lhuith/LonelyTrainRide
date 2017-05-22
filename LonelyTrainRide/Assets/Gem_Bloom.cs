using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Gem_Bloom : MonoBehaviour {


    public Material gemBloom;
    public int iterations;
    public RenderTexture sparkleTex;
    private RenderTexture gemBloomTex;

	// Update is called once per frame
	void Update ()
    {
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Graphics.Blit(source, destination, gemBloom);
    }
}
