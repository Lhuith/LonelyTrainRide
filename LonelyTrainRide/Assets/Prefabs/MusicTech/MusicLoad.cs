using UnityEngine;
using System.Collections;
using System.Linq;

[ExecuteInEditMode]
public class MusicLoad : MonoBehaviour
{
	static public AudioClip[] songslist;
    public AudioClip[] songslistView;
    // Use this for initialization
    void Awake () {
        AudioClip[] songsListLoad =  Resources.LoadAll<AudioClip>("Music");
		songslist = songsListLoad;
        songslistView = songsListLoad;
    }
	
	// Update is called once per frame
	void Update () {
	
	}
}
