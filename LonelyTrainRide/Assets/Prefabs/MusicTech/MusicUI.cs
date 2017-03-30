using UnityEngine;
using System.Collections;
using UnityEngine.UI;

public class MusicUI : MonoBehaviour {
	public MusicLoad musicLoader;
	public SpectrumAnalyzer specAny;
	public Text songName, playButton;
	public bool isPause, isPlay;
	// Use this for initialization
	void Start () {
		//musicLoader = Camera.main.GetComponent<MusicLoad> ();
		songName = GameObject.FindGameObjectWithTag ("NAME").GetComponent<Text> ();
		playButton = GameObject.FindGameObjectWithTag ("PLAY").GetComponent<Text> ();
		specAny = Camera.main.GetComponent<SpectrumAnalyzer> ();
	}
	
	// Update is called once per frame
	void Update () {
		isPlay = specAny.isPlay;

		if (isPlay) {
			playButton.text = "Pause";
		} else {
			playButton.text = "Play";
		}
			songName.text = Camera.main.GetComponent<AudioSource> ().clip.name;
	}

	public void NextSong(){
		specAny.NextSong ();
	}

	public void PrevSong(){
		specAny.PrevSong ();
	}

	public void PlayPuaseSong(){
		if (!isPlay) {
			specAny.PlaySong ();
		} else {
			specAny.PauseSong ();
		}
	}
}
