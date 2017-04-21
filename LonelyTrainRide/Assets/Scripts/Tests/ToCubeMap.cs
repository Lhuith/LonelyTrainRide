using UnityEngine;
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
    public GameObject go;

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
        if (go)
        {

            cam = go.GetComponent<Camera>();

            //Vector3 eulerA =  new Vector3(-go.transform.eulerAngles.x,
            //                               go.transform.eulerAngles.y,
            //                               go.transform.eulerAngles.z);
            //
            //go.transform.position = Camera.main.transform.position;

            //go.transform.eulerAngles = eulerA;
            //go.transform.parent = transform.root;

            //cam.depthTextureMode = DepthTextureMode.Depth;
            cam.cullingMask = layerMask;
            cam.nearClipPlane = nearClip;
            cam.farClipPlane = farClip;
            cam.transform.position = transform.position;
            cam.enabled = false;


            ReflectionCubeMap.wrapMode = TextureWrapMode.Clamp;

            reflectMat.SetTexture("_Tex", ReflectionCubeMap);
            cam.RenderToCubemap(ReflectionCubeMap, faceMask);

        }
    }

    void OnDisable()
    {
    }
}
 
