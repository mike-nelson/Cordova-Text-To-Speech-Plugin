#Cordova iOS Text to Speech Plugin

A small text to speech plugin for Cordova3 / iOS

### Installation

In your Cordova project directory : 

`cordova plugin add https://github.com/cavej03/Cordova-Text-To-Speech-Plugin.git`

### How to use

    ttsPlugin.setRate(rate); // Set voice speed : default is "0.2"
    
    ttsPlugin.setLanguage(lang); // Set voice language : default is "en-US"
    
    ttsPlugin.initTTS(); // Init Plugin
    
    ttsPlugin.speak("Hello"); // Say Hello
    
    ttsPlugin.stop(); // Stop speaking
    
    ttsPlugin.pause(); // Pause speaking
    
    ttsPlugin.resume(); // Resume speaking


### Events
    ttsPlugin.callbacks.finishedSpeaking = function(){
        //override with your own functions
        console.log("Finished Speaking");
    },
    ttsPlugin.callbacks.cancelledSpeaking = function(){
        //override with your own functions
        console.log("Cancelled Speaking");
    },
    ttsPlugin.callbacks.continuedSpeaking = function(){
        //override with your own functions
        console.log("Continued Speaking");
    },
    ttsPlugin.callbacks.pausedSpeaking = function(){
        //override with your own functions
        console.log("Paused Speaking");
    },
    ttsPlugin.callbacks.startedSpeaking = function(){
        //override with your own functions
        console.log("Started Speaking");
    }
    ttsPlugin.callbacks.currentRangeOfSpeech = function(range){
        //override with your own functions
        console.log("currentRangeOfSpeech", range);
    }

### Status
    ttsPlugin.getStatus(function(status){
        //change this callback
        console.log(status)
    })

Big thanks to steevelefort who created the original plugin - found here: 
https://github.com/steevelefort/cordova3-ios-tts-plugin

### Todo

- Android Version
