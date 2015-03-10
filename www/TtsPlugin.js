var exec = require('cordova/exec');
/**
 * Constructor
 */
function tts() {}

tts.prototype.init = function(successCallBack, failCallBack) {
    exec(function(result){
        if(successCallBack){
            successCallBack();
        }
    },
    function(error){
        if(failCallBack){
            failCallBack();
        }
    },
    "TtsPlugin",
    "initTTS",
    []
    );
}

tts.prototype.setLanguage = function(lang) {
    exec(function(result){
    },
    function(error){
    },
    "TtsPlugin",
    "setLanguage",
    [lang]
    );
}

tts.prototype.setRate = function(rate) {
    exec(function(result){
    },
    function(error){
    },
    "TtsPlugin",
    "setRate",
    [rate]
    );
}


tts.prototype.speak = function(text) {
    exec(function(result){
        console.log("tts -  speak:",result);
    },
    function(error){
    },
    "TtsPlugin",
    "speak",
    [text]
    );
}

tts.prototype.stop = function() {
    exec(function(result){
        console.log("tts -  stop:",result);
    },
    function(error){
    },
    "TtsPlugin",
    "stop",
    []
    );
}

tts.prototype.pause = function() {
    exec(function(result){
        console.log("tts -  pause:",result);
    },
    function(error){
    },
    "TtsPlugin",
    "pause",
    []
    );
}

tts.prototype.resume = function() {
    exec(function(result){
        console.log("tts -  resume:",result);
    },
    function(error){
    },
    "TtsPlugin",
    "resume",
    []
    );
}

tts.prototype.restart = function() {
    exec(function(result){
        console.log("tts -  restart:",result);
    },
    function(error){
    },
    "TtsPlugin",
    "restart",
    []
    );
}

var tts = new tts();
module.exports = tts;