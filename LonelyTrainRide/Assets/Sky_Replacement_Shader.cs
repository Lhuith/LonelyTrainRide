using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Sky_Replacement_Shader : MonoBehaviour
{

    public Shader skyreplacementShader;
    public RenderTexture skyCloudDepthTex;
        // Use this for initialization
	void OnEnable ()
    {
        this.GetComponent<Camera>().SetReplacementShader(skyreplacementShader, "RenderType");
	}

    void OnDisable()
    {
        this.GetComponent<Camera>().ResetReplacementShader();
    }
}
