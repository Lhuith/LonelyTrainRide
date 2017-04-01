using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PaintTest : MonoBehaviour
{

    //Transform viewer;

	// Use this for initialization
	void Start ()
    {
        //viewer = GameObject.Find("Passanger").transform;
    }
	
	// Update is called once per frame
	void Update ()
    {
       // RaycastHit hit;

       // Vector3 dir = -viewer.transform.up;
       //
       // if(Physics.Raycast(Camera.main.ScreenPointToRay(dir), out hit))
       // {
       //     MeshRenderer mRend = hit.transform.GetComponent<MeshRenderer>();
       //
       //     Texture2D tex = mRend.material.mainTexture as Texture2D;
       //
       //     Vector2 pixelUV = hit.textureCoord;
       //     pixelUV.x *= tex.width;
       //     pixelUV.y *= tex.height;
       //
       //
       //     for(int i = 0; i < 10; i++)
       //     {
       //         for (int j = 0; j < 10; j++)
       //         {
       //             {
       //                 tex.SetPixel((int)pixelUV.x + i, (int)pixelUV.y + j, Color.magenta);
       //             }
       //         }
       //     }
       //
       //     //tex.SetPixel((int)pixelUV.x, (int)pixelUV.y, Color.magenta);
       //     tex.Apply();
        //}
	}
}
