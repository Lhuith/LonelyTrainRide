using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Sparkle_Replacement_Shader : MonoBehaviour
{

    public Shader replacementShader;
    public RenderTexture sparkleTex;
        // Use this for initialization
	void OnEnable ()
    {
        this.GetComponent<Camera>().SetReplacementShader(replacementShader, "RenderType");
	}

    void OnDisable()
    {
        this.GetComponent<Camera>().ResetReplacementShader();
    }
}
