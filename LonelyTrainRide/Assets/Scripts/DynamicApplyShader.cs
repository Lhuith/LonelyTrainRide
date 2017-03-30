using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DynamicApplyShader : MonoBehaviour {

    public Material mat; //Wraps the Shader

    private RenderTexture buffer;
    private RenderTexture texture;

    public Texture IntialTexture; 

    public float updateInterval;
    private float lastUpdateTime = 0;
    Transform viewer;

    // Use this for initialization
    void Start ()
    {
        texture = new RenderTexture(512, 512, 16);
        viewer = GameObject.Find("Passanger").transform;
        mat = new Material(Shader.Find("Test/Smoke"));
        mat.name = transform.name;
        Graphics.Blit(IntialTexture, texture);
        buffer = new RenderTexture(texture.width, texture.height, texture.depth, texture.format);
        this.GetComponent<MeshRenderer>().material.SetTexture("_DynamicTex", texture);
    }
	
    public void UpdateTexture()
    {
        Graphics.Blit(texture, buffer, mat);
        Graphics.Blit(buffer, texture);

        //this.GetComponent<MeshRenderer>().material.SetTexture("_DynamicTex", texture);
    }

	// Update is called once per frame
	void Update ()
    {
        RaycastHit hit;
        Vector3 mouse = Input.mousePosition;
        Vector3 mWpos = Camera.main.ViewportToScreenPoint(mouse);
        Vector3 dir = transform.forward;
        Ray ray = new Ray(viewer.position, -viewer.up);

        Debug.DrawRay(ray.origin, ray.direction * 100);

        if (Physics.Raycast(ray, out hit))
        {
            MeshRenderer mRend = hit.transform.GetComponent<MeshRenderer>();

            Vector3 pixelUV = hit.textureCoord ;

            //pixelUV.x *= 241;
            //pixelUV.y *= 241;

            mat.SetVector("_SmokeCentre",
                pixelUV
            );
        }

        else
        {
            mat.SetVector("_SmokeCentre",
              new Vector3(0, 0, 0));
        }

        if (Time.time > lastUpdateTime + updateInterval)
        {
            UpdateTexture();
            lastUpdateTime = Time.time;
        }
	}
}
