using UnityEngine;
using UnityEngine.Rendering;
using System.Collections;
using System.Collections.Generic;

public class ShadowCopySetup : MonoBehaviour {
	CommandBuffer m_afterShadowPass = null;

	// Use this for initialization
	void Start () 
	{
	
		m_afterShadowPass = new CommandBuffer();
		m_afterShadowPass.name = "Shadowmap Copy";

		//The name of the shadowmap for this light will be "MyShadowMap"
		m_afterShadowPass.SetGlobalTexture ("MyShadowMap", new RenderTargetIdentifier(BuiltinRenderTextureType.CurrentActive));
		
		Light light = GetComponent<Light> ();
		if (light) 
		{
			//add command buffer right after the shadowmap has been renderered
			light.AddCommandBuffer (UnityEngine.Rendering.LightEvent.AfterShadowMap, m_afterShadowPass);
		}

	}

	void OnDestroy()
	{
		if (m_afterShadowPass != null) 
		{
			Light light = GetComponent<Light> ();
			if (light) 
			{
				light.RemoveCommandBuffer(UnityEngine.Rendering.LightEvent.AfterShadowMap, m_afterShadowPass);
			}
		}
	}
	/*
	// Update is called once per frame
	void Update () 
	{
		if (m_afterShadowPass != null) 
		{
			m_afterShadowPass.Clear ();
			
			m_afterShadowPass.SetGlobalTexture ("MyShadowMap", new RenderTargetIdentifier(BuiltinRenderTextureType.CurrentActive));
			
			Light light = GetComponent<Light> ();
			if (light)
				light.AddCommandBuffer (UnityEngine.Rendering.LightEvent.AfterShadowMap, m_afterShadowPass);
			

		}
	
	}

	 
	public void OnWillRenderObject()
	{
		m_afterShadowPass.Clear ();

		m_afterShadowPass.SetGlobalTexture ("MyShadowMap", new RenderTargetIdentifier(BuiltinRenderTextureType.CurrentActive));

		Light light = GetComponent<Light> ();
		if (light)
			light.AddCommandBuffer (UnityEngine.Rendering.LightEvent.AfterShadowMap, m_afterShadowPass);

	}
	*/

}
