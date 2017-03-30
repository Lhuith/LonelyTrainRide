using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
public class Sky_Shader_Manager : MonoBehaviour {

    public Material skyMat;
    public RenderTexture skyRenderTexture;
    public Texture2D testTexture;
    public Color TestColor;

    public float KM_Range = 0.0015f;
    public float KR_Range = 0.0025f;

    public int nSamples_Range = 2;
    public float fSamples_Range = 2;

    public float g = -0.85f;

    public float fScaleDepth = .25f;
    public float ESun = 15f;
    public float fOuterRadius = 1.25f;
    public float fInnerRadius = 1f;

    void Start()
    {
        
    }

    void Update()
    {
        skyMat.SetFloat("_Km", KM_Range);
        skyMat.SetFloat("_Kr", KR_Range);
        skyMat.SetFloat("_fSamples", fSamples_Range);
        skyMat.SetFloat("_nSamples", nSamples_Range);

        skyMat.SetFloat("_fScaleDepth", fScaleDepth);
        skyMat.SetFloat("_ESun", ESun);
        skyMat.SetFloat("_fOuterRadius", fOuterRadius);
        skyMat.SetFloat("_fInnerRadius", fInnerRadius);
        skyMat.SetFloat("_G", g);
        skyMat.SetColor("_Color", TestColor);

        float fkr4PI = KR_Range * 4 * Mathf.PI;
        skyMat.SetFloat("_fKr4PI", fkr4PI);
        float fkm4PI = KM_Range * 4 * Mathf.PI;
        skyMat.SetFloat("_fKm4PI", fkm4PI);
        float KrSun = KR_Range * ESun;
        skyMat.SetFloat("_fKrESun", KrSun);
        float KmSun = KM_Range * ESun;
        skyMat.SetFloat("_fKmESun", KmSun);
        float fOut2 = (fOuterRadius * fOuterRadius);
        skyMat.SetFloat("_fOuterRadius2", fOut2);
        float fInn2 = (fInnerRadius * fInnerRadius);
        skyMat.SetFloat("_fInnerRadius2", fInn2);
        float fScale = 1 / (fOuterRadius - fInnerRadius);
        skyMat.SetFloat("_fScale", fScale);
        float invScale = 1.0f / fScaleDepth;
        skyMat.SetFloat("_fInvScaleDepth", invScale);
        float scaleOverScaleDepth = fScale / fScaleDepth;
        skyMat.SetFloat("_fScaleOverScaleDepth", scaleOverScaleDepth);
        float g2 = g * g;
        skyMat.SetFloat("_G2", g2);
    }

}
