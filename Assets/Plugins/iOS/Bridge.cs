using System.Runtime.InteropServices;
using UnityEngine;


public class Bridge {
    #if UNITY_IOS && !UNITY_EDITOR
    [DllImport("__Internal")]
    private static extern void _ex_startRecognizing();
    #endif

    public static void StartRecognizing() {
        #if UNITY_IOS && !UNITY_EDITOR
        _ex_startRecognizing();
        #endif
    }

    #if UNITY_IOS && !UNITY_EDITOR
    [DllImport("__Internal")]
    private static extern void _ex_stopRecognizing();
    #endif

    public static void StopRecognizing() {
        #if UNITY_IOS && !UNITY_EDITOR
        _ex_stopRecognizing();
        #endif
    }
}
