using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ObjectThickness : MonoBehaviour {

    public RenderTexture thicknessRenderTexture;

    public Material SSS_Mat;
    public Material depth_Mat;
    void Awake()
    {
        //RenderTexture thicknessRenderTexture = new RenderTexture(1024, 768, 0);
        //thicknessRenderTexture.format = RenderTextureFormat.RFloat;

        //depth_Mat = this.GetComponent<MeshRenderer>().material;
        SSS_Mat.SetTexture("_ThicknessTex", thicknessRenderTexture);
    }

    // Postprocess the image
    void Update()
    {

        //Grab Depth and blit to R float
        RenderTexture tempDepthResult = RenderTexture.GetTemporary(thicknessRenderTexture.width, thicknessRenderTexture.height, thicknessRenderTexture.depth);
        Graphics.Blit(tempDepthResult, thicknessRenderTexture, depth_Mat);
        //Graphics.Blit(thicknessRenderTexture, tempDepthResult);
        //SSS_Mat.SetTexture("_ThicknessTex", thicknessRenderTexture);
        //output.SetTexture("_Depth", tempDepthResult);
        //output.SetTexture("_Scatter", thicknessRenderTexture);
    
        tempDepthResult.Release();
    }
}
