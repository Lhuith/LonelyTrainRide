using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class Sky_Shader_Manager : MonoBehaviour {

    public Material skyMatGen;
    public RenderTexture skyTexture;
    public Texture2D NoiseTexture;
    public Color TestColor;
    public Vector2 resulotion;

    void Enable()
    {
        skyMatGen.SetTexture("_NoiseTex", NoiseTexture);
    }
    void Update()
    {
        skyMatGen.SetColor("_BackColor", TestColor);
        skyMatGen.SetVector("_MousePos", Input.mousePosition);
        skyMatGen.SetVector("_iResolution", resulotion);
    }

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        //Graphics.Blit(source, destination, skyMatGen);
    }


}
