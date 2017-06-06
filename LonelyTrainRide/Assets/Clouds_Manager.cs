using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Clouds_Manager : MonoBehaviour
{


    public Material skyBoxMaterial;
    public Material skyBoxShadowMaterial;

    public float NoiseFreq1 = 3.1f;
    public float NoiseFreq2 = 35.1f;
    public float NoiseAmp1 = 5f;
    public float NoiseAmp2 = 1f;
    public float NoiseBias = -0.2f;

    public Vector3 Scroll1 = new Vector3(0.01f, 0.08f, 0.06f);
    public Vector3 Scroll2 = new Vector3(0.01f, 0.05f, 0.03f);

    public float Altitude0 = 1500;
    public float Altitude1 = 3500;
    public float FarDist = 30000;

    public float SampleCount0 = 30;
    public float SampleCount1 = 90;
    public float SampleCountL = 16;

    [Range(0, .001f)]
    public float Alpha;
    // Use this for initialization
    void Start ()
    {
		
	}
	
	// Update is called once per frame
	void Update ()
    {
        skyBoxMaterial.SetFloat("_NoiseFreq1", NoiseFreq1);
        skyBoxMaterial.SetFloat("_NoiseFreq2", NoiseFreq2);
        skyBoxMaterial.SetFloat("_NoiseAmp1", NoiseAmp1);
        skyBoxMaterial.SetFloat("_NoiseAmp2", NoiseAmp2);
        skyBoxMaterial.SetFloat("_NoiseBias", NoiseBias);
        skyBoxMaterial.SetVector("_Scroll1", Scroll1);
        skyBoxMaterial.SetVector("_Scroll2", Scroll2);
        skyBoxMaterial.SetFloat("_Altitude0", Altitude0);
        skyBoxMaterial.SetFloat("_Altitude1", Altitude1);
        skyBoxMaterial.SetFloat("_FarDist", FarDist);


        skyBoxMaterial.SetFloat("_SampleCount0", SampleCount0);
        skyBoxMaterial.SetFloat("_SampleCount1", SampleCount1);
        skyBoxMaterial.SetFloat("_SampleCountL", SampleCountL);

        skyBoxShadowMaterial.SetFloat("_NoiseFreq1", NoiseFreq1);
        skyBoxShadowMaterial.SetFloat("_NoiseFreq2", NoiseFreq2);
        skyBoxShadowMaterial.SetFloat("_NoiseAmp1", NoiseAmp1);
        skyBoxShadowMaterial.SetFloat("_NoiseAmp2", NoiseAmp2);
        skyBoxShadowMaterial.SetFloat("_NoiseBias", NoiseBias);
        skyBoxShadowMaterial.SetVector("_Scroll1", Scroll1);
        skyBoxShadowMaterial.SetVector("_Scroll2", Scroll2);
        skyBoxShadowMaterial.SetFloat("_Altitude0", Altitude0);
        skyBoxShadowMaterial.SetFloat("_Altitude1", Altitude1);
        skyBoxShadowMaterial.SetFloat("_FarDist", FarDist);

        skyBoxShadowMaterial.SetFloat("_Alpha", Alpha);

       skyBoxShadowMaterial.SetFloat("_SampleCount0", SampleCount0);
       skyBoxShadowMaterial.SetFloat("_SampleCount1", SampleCount1);
       skyBoxShadowMaterial.SetFloat("_SampleCountL", SampleCountL);

    }
}
