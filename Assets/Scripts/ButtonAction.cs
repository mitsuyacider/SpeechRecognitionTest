using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public class ButtonAction : MonoBehaviour {
	enum AudioState {
	  STANDBY, RECOGNIZING, SCENE
	}

	public delegate void audioDelegate();
	public AudioClip audioClip;
	public Text textView;
	private AudioSource audioSource;
	private AudioState audioState = AudioState.STANDBY;

	// Use this for initialization
	void Start () {
		audioSource = gameObject.GetComponent<AudioSource>();

		AudioClip clip = (AudioClip) Resources.Load("Sounds/magic");
		audioSource.clip = clip;
		textView.text = "再生ボタンを押してください";
	}

	// Update is called once per frame
	void Update () {

	}

	public void clickButton () {
		// NOTE: audioを再生 / 停止
		if (audioSource.isPlaying) {
			audioSource.Stop ();
		} else {
			playSound();
		}
	}

	/*
		NOTE: Nativeからのコールバック
				  音声認識によって解析した文字列を取得する。
		@param message : 音声認識によって解析された文章
	*/
	public void callbackFromNative(string message) {
		Debug.Log ("got message from native:" + message);

		if (message == "stopRecognizing") {
			playSound();
		} else {
			textView.text = message;

			// NOTE: テスト用に呪文の正解ワードを用意
			string dictionary = "悪悪";
			string dictionary2 = "サラダ";
			string dictionary3 = "木の実ナナ";
			if(message.Contains(dictionary)) {
				// NOTE: detected spell
				reciteSpell("ニクニクニー", "Sounds/scene02");
			}

			if(message.Contains(dictionary2)) {
				// NOTE: detected spell
				reciteSpell("サラダーラ", "Sounds/scene02");
			}

			if(message.Contains(dictionary3)) {
				// NOTE: detected spell
				reciteSpell("キノミナナーミ", "Sounds/scene03");
			}
		}
	}

	private void reciteSpell(string spell, string filePath) {
		// NOTE: detected spell
		textView.text = "呪文「" + spell + "」を唱えました！！";
		changeGameScene();
		// NOTE: iOSへ音声認識開始の通知
		Bridge.StopRecognizing();

		// NOTE: サウンドを変更する
		AudioClip clip = (AudioClip) Resources.Load(filePath);
		audioSource.clip = clip;
	}

	private void changeGameScene() {
		switch(audioState) {
			case AudioState.STANDBY:
				// NOTE: 音声認識を開始する
				textView.text = "効果音の後に呪文を唱えてください。";
				audioState = AudioState.RECOGNIZING;
				break;

			case AudioState.RECOGNIZING:
				// NOTE: テキスト解析の結果を出力する
				audioState = AudioState.SCENE;
				break;

			case AudioState.SCENE:
				audioState = AudioState.STANDBY;
				textView.text = "再生ボタンを押してください。";
				// NOTE: サウンドを変更する
				AudioClip clip = (AudioClip) Resources.Load("Sounds/magic");
				audioSource.clip = clip;

				break;
		}
	}

	private void playSound() {
		audioSource.Play ();
		StartCoroutine(Checking( ()=>{
					Debug.Log("Audio END");

					// NOTE: ゲームシーモードを更新する
					changeGameScene();

					if (audioState == AudioState.RECOGNIZING) {
						// NOTE: iOSへ音声認識開始の通知
						Bridge.StartRecognizing();
					}
		} ));
	}

  /*
		NOTE: 音声終了のフレームを調べるコルーチン
	*/
	private IEnumerator Checking (audioDelegate callback) {
			while(true) {
					yield return new WaitForFixedUpdate();
					if (!audioSource.isPlaying) {
							callback();
							break;
					}
			}
	}
}
