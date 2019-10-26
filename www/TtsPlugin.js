var exec = require('cordova/exec');
/**
 * Constructor
 */
function tts() {}

tts.prototype.init = function() {
    exec(function(result){
        // document.dispatchEvent(new CustomEvent('ttsInitSuccess', result));
    },
    function(error){
        // document.dispatchEvent(new CustomEvent('ttsInitFailed', result));
    },
    "TtsPlugin",
    "initTTS",
    []
    );
};

tts.prototype.setAudioSessionPlayback = function(successCallback, errorCallback) {
    exec(successCallback, errorCallback,
    "TtsPlugin",
    "setAudioSessionPlayback",
    []
    );
};

tts.prototype.setAudioSessionPlayAndRecord = function(successCallback, errorCallback) {
    exec(successCallback, errorCallback,
    "TtsPlugin",
    "setAudioSessionPlayAndRecord",
    []
    );
};

tts.prototype.setLanguage = function(lang) {
    exec(function(result){
        // document.dispatchEvent(new CustomEvent('ttsSetLanguageSuccess', result));
    },
    function(error){
        // document.dispatchEvent(new CustomEvent('ttsSetLanguageFailed', result));
    },
    "TtsPlugin",
    "setLanguage",
    [lang]
    );
};

tts.prototype.setRate = function(rate) {
    exec(function(result){
        // document.dispatchEvent(new CustomEvent('ttsSetRateSuccess', result));
    },
    function(error){
        // document.dispatchEvent(new CustomEvent('ttsSetRateFailed', result));
    },
    "TtsPlugin",
    "setRate",
    [rate]
    );
};

tts.prototype.getVoices = function(callback) { //because this is asynchronous we need to pass a callback 
    exec(function(result){
        if(callback){
            callback(result);
        }
    },
    function(error){
        console.error(error);
    },
    "TtsPlugin",
    "getVoices",
    []
    );
};


tts.prototype.setVoice = function(text) {
    exec(function(result){
        //console.log(result);
        // document.dispatchEvent(new CustomEvent('ttsSpeakSuccess', result));
    },
    function(error){
        // document.dispatchEvent(new CustomEvent('ttsSpeakFailed', result));
    },
    "TtsPlugin",
    "setVoice",
    [text]
    );
};


/**
 * @param {string} text - text to speak
 * @param {function} callback - a function with param event, can be type 'finishedSpeaking'
 * @example ttsPlugin.speak('hello', function(ev){if (ev.type=='finishedSpeaking'){ console.log('done') }})
 */
tts.prototype.speak = function(text, callback) {
    exec(callback,
    function(error){
        // document.dispatchEvent(new CustomEvent('ttsSpeakFailed', result));
    },
    "TtsPlugin",
    "speak",
    [text]
    );
};

tts.prototype.getSpeechStatus = function(callback) { //because this is asynchronous we need to pass a callback 
    exec(function(result){
        if(callback){
            callback(result);
        }
    },
    function(error){
        console.error(error);
    },
    "TtsPlugin",
    "getSpeechStatus",
    []
    );
};

tts.prototype.stop = function() {
    exec(function(result){
        // document.dispatchEvent(new CustomEvent('ttsStopSuccess', result));
    },
    function(error){
        // document.dispatchEvent(new CustomEvent('ttsStopFailed', result));
    },
    "TtsPlugin",
    "stop",
    []
    );
};

tts.prototype.pause = function() {
    exec(function(result){
        // document.dispatchEvent(new CustomEvent('ttsPauseSuccess', result));
    },
    function(error){
        // document.dispatchEvent(new CustomEvent('ttsPauseFailed', result));
    },
    "TtsPlugin",
    "pause",
    []
    );
};

tts.prototype.resume = function() {
    exec(function(result){
        // document.dispatchEvent(new CustomEvent('ttsResumeSuccess', result));
    },
    function(error){
        // document.dispatchEvent(new CustomEvent('ttsResumeFailed', result));
    },
    "TtsPlugin",
    "resume",
    []
    );
};

tts.prototype.restart = function() {
    exec(function(result){
        // document.dispatchEvent(new CustomEvent('ttsRestartSuccess', result));
    },
    function(error){
        // document.dispatchEvent(new CustomEvent('ttsRestartFailed', result));
    },
    "TtsPlugin",
    "restart",
    []
    );
};

tts.prototype.callbacks = {
    finishedSpeaking: function(){
        console.log("Finished Speaking");
    },
    cancelledSpeaking: function(){
        console.log("Cancelled Speaking");
    },
    continuedSpeaking: function(){
        console.log("Continued Speaking");
    },
    pausedSpeaking: function(){
        console.log("Paused Speaking");
    },
    startedSpeaking: function(){
        console.log("Started Speaking");
    },
    currentRangeOfSpeech: function(textrangefromnsrange){
        console.log("currentRangeOfSpeech", textrangefromnsrange);
    },
    audioRouteChanged: function(routeDescription){
    	console.log("audioRouteChanged", routeDescription);
    },
    handleMediaServerReset: function(){
    	console.log("handleMediaServerReset");
    },
};

var tts = new tts();
module.exports = tts;
