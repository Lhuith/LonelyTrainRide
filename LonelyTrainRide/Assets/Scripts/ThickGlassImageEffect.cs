using UnityEngine;
using System.Collections;
[ExecuteInEditMode]
public class ThickGlassImageEffect : MonoBehaviour
{
    public RenderTexture thicknessRenderTexture;
    public Material material;

    void Awake ()
    {
        material.SetTexture("_ThicknessTex", thicknessRenderTexture);
    }
   
    // Postprocess the image
    void OnRenderImage (RenderTexture source, RenderTexture destination)
    {
        Graphics.Blit (source, destination, material);     
       // material.SetTexture("_ThicknessTex", thicknessRenderTexture);
    }
}
