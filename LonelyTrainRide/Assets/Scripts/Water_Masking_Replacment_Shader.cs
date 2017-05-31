using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Water_Masking_Replacment_Shader : MonoBehaviour
{
    public Shader waterMaskreplacementShader;
   // public RenderTexture waterMaskTex;
        // Use this for initialization
	void OnEnable ()
    {
        this.GetComponent<Camera>().SetReplacementShader(waterMaskreplacementShader, "RenderType");
	}

    void OnDisable()
    {
        this.GetComponent<Camera>().ResetReplacementShader();
    }
}
