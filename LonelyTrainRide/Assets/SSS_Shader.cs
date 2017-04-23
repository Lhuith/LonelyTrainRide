using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SSS_Shader : MonoBehaviour
{
    public Material sssDistance;
    public Material sssScatter;
    public Transform lightDir;
	// Use this for initialization
	void Start ()
    {
        sssScatter = this.GetComponent<MeshRenderer>().material;
    }
	
	// Update is called once per frame
	void Update ()
    {

        Debug.Log(sssScatter.GetMatrix("unity_WorldToLight"));

        RenderTexture temp = RenderTexture.GetTemporary(1028, 1028, 24);
        Graphics.Blit(temp, sssDistance);

        RenderTexture temp2 = RenderTexture.GetTemporary(1028, 1028, 24);
        Graphics.Blit(temp2, sssScatter);
       
        Vector3 LightDirection = new Vector3(10, 10, 5);//transform.position - lightDir.transform.position;

        //Vector3 camoffset = new Vector3(-offset.x, -offset.y, offset.z);
        //Matrix4x4 m = Matrix4x4.TRS(camoffset, Quaternion.identity, new Vector3(1, 1, -1));
        //camera.worldToCameraMatrix = m * transform.worldToLocalMatrix;
        //
        //sssScatter.SetMatrix("_LightProjection", lightMatrix);

    }
}
