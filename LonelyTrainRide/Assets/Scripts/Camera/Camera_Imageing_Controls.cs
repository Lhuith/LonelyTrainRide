using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class Camera_Imageing_Controls : MonoBehaviour
{
    [SerializeField]
    private Texture2D noiseOffsetTexture;

  // Use this for initialization
  void Awake ()
  {
      Camera.main.depthTextureMode = DepthTextureMode.Depth;
  }

	// Update is called once per frame
	void Update ()
    {
        Camera.main.depthTextureMode = DepthTextureMode.Depth;
    }
}
