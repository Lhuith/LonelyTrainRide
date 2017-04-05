﻿using UnityEngine;
using System.Collections;
using UnityEngine.Rendering;

[ExecuteInEditMode]
public class ToCubeMap : MonoBehaviour
{
    public Material reflectMat;
    private Camera cam;
    public Cubemap ReflectionCubeMap;
    public int cubemapSize = 128;
    public float nearClip = 0.01f;
    public float farClip = 500;
    public bool oneFacePerFrame = false;
    public LayerMask layerMask;

    void Start()
    {
        UpdateCubeMap(63);
    }

    void LateUpdate()
    {
        if (oneFacePerFrame)
        {
            int faceToRender = Time.frameCount % 6;
            int faceMask = 1 << faceToRender;
            UpdateCubeMap(faceMask);
        }
        else
        {
            UpdateCubeMap(63); // all sex faces
        }
    }

    void UpdateCubeMap(int faceMask)
    {
        if (!cam)
        {
            GameObject go = new GameObject("CubemapCamera", typeof(Camera));
         
            go.transform.position = transform.position;
            go.transform.rotation = Quaternion.identity;

            cam = go.GetComponent<Camera>();
            cam.depthTextureMode = DepthTextureMode.Depth;
            cam.cullingMask = layerMask;
            cam.nearClipPlane = nearClip;
            cam.farClipPlane = farClip;
            cam.enabled = false;
        }

        cam.transform.position = transform.position;

        ReflectionCubeMap.wrapMode = TextureWrapMode.Clamp;

        reflectMat.SetTexture("_Tex", ReflectionCubeMap);
        cam.RenderToCubemap(ReflectionCubeMap, faceMask);
    }

    void OnDisable()
    {   
        Destroy(cam);
    }
}

