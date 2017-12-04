#import "TtsPlugin.h"
#import <Cordova/CDV.h>
#import <AVFoundation/AVFoundation.h>

@implementation TtsPlugin

AVSpeechSynthesizer *synth;
//NSString *lang = @"en-US";
NSString *lang = @"en-US";
AVSpeechSynthesisVoice *globalVoice;
double rate = 0.2;
NSString *currentLocale;

- (void)initTTS:(CDVInvokedUrlCommand*)command{
    synth = [[AVSpeechSynthesizer alloc] init];
    synth.delegate = self;

    NSString *locale = [[NSLocale currentLocale] localeIdentifier];
    //NSRange startRange = [locale rangeOfString:@"_"]; // this isn't the underscore you see in the first string
    //currentLocale = [locale stringByReplacingCharactersInRange:NSMakeRange(0, startRange.length+1) withString:[[NSLocale preferredLanguages] objectAtIndex:0]];
    currentLocale = [locale stringByReplacingOccurrencesOfString:@"_" withString:@"-"];
    //NSLog(@"current locale: %@", currentLocale);

//    AVAudioSession *session = [AVAudioSession sharedInstance];
//    NSError *error;
//    bool success = [session setCategory:AVAudioSessionCategoryPlayAndRecord
//                            withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker
//                                  error:&error];
//    if (!success) NSLog(@"Error setting setCategory! %@\n", [error localizedDescription]);
    
    //if (&AVAudioSessionModeSpokenAudio!=nil){
    //    [session setMode:AVAudioSessionModeSpokenAudio error:nil];
    //}
//     [session setMode:AVAudioSessionModeVoiceChat error:nil];
  
    [self initAudioSession];
    
//    for (AVSpeechSynthesisVoice *voice in [AVSpeechSynthesisVoice speechVoices]) {
//        NSString *language = voice.language;
//        if ([language isEqualToString:currentLocale]){
//           /*NSLog(@"setting voice to locale: %@", currentLocale);*/
//            globalVoice = voice;
//        }
//    }
    
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"OK"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setLanguage:(CDVInvokedUrlCommand*)command{
    lang = [command.arguments objectAtIndex:0];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"OK"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)setRate:(CDVInvokedUrlCommand*)command{
    @try {
        rate = [[command.arguments objectAtIndex:0] doubleValue];
        //NSLog(@"setting rate: %f", rate);
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"OK"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    @catch (NSException * e) {
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"ERROR"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
    //@finally { }
}

- (void)getVoices:(CDVInvokedUrlCommand*)command{
    /*NSLog(@"setting voice to locale: coolbeans");*/
    
    NSMutableArray *stringArray = [[NSMutableArray alloc] init];
    @try{
		if ([AVSpeechSynthesisVoice speechVoices]!=nil){		
	        for (AVSpeechSynthesisVoice *voice in [AVSpeechSynthesisVoice speechVoices]) {
	            NSString *nameAndLocale = [voice.name stringByAppendingString:@"["];
	            nameAndLocale = [nameAndLocale stringByAppendingString:voice.language];
	            nameAndLocale = [nameAndLocale stringByAppendingString:@"]"];
	            [stringArray addObject:nameAndLocale];
	        }
        }
    }
    @catch (NSException *exception) {
        // i think there is an error in iOS 10.2.1
        NSLog(@"%@", exception.reason);
    }
    
    [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:stringArray] callbackId:command.callbackId];
}

- (void)setVoice:(CDVInvokedUrlCommand*)command{
    NSString* text = [command.arguments objectAtIndex:0];
    
    @try{
		if ([AVSpeechSynthesisVoice speechVoices]!=nil){		
	        for (AVSpeechSynthesisVoice *voice in [AVSpeechSynthesisVoice speechVoices]) {
	            NSString *name = voice.name;
	            if ([name isEqualToString:text]){
	                globalVoice = voice;
	            }
       
	        }
		}
    }
    @catch (NSException *exception) {
        // i think there is an error in iOS 10.2.1
        NSLog(@"%@", exception.reason);
    }
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:globalVoice.language];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


- (void)initAudioSession{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error;
    bool success = true;
    	    success = [session setCategory:AVAudioSessionCategoryPlayAndRecord
    	                  withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionAllowBluetoothA2DP
    	                        error:&error];
    	    if (!success) NSLog(@"Error setting setCategory! %@\n", [error localizedDescription]);
    if (&AVAudioSessionModeSpokenAudio!=nil){
              [session setMode:AVAudioSessionModeSpokenAudio error:nil];
    }
    success = [session setActive:YES error:&error];
    if (!success) NSLog(@"Error setting session active! %@\n", [error localizedDescription]);

    // track route change notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRouteChange:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:session];
}

- (void)handleRouteChange:(NSNotification *)notification
{
    UInt8 reasonValue = [[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] intValue];
    AVAudioSessionRouteDescription *routeDescription = [notification.userInfo valueForKey:AVAudioSessionRouteChangePreviousRouteKey];
    
    NSLog(@"Route change:");
    switch (reasonValue) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            NSLog(@"     NewDeviceAvailable");
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            NSLog(@"     OldDeviceUnavailable");
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            NSLog(@"     CategoryChange");
            NSLog(@" New Category: %@", [[AVAudioSession sharedInstance] category]);
            break;
        case AVAudioSessionRouteChangeReasonOverride:
            NSLog(@"     Override");
            break;
        case AVAudioSessionRouteChangeReasonWakeFromSleep:
            NSLog(@"     WakeFromSleep");
            break;
        case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
            NSLog(@"     NoSuitableRouteForCategory");
            break;
        default:
            NSLog(@"     ReasonUnknown");
    }
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error;
    
    AVAudioSessionRouteDescription *newRoute = session.currentRoute;
    NSLog(@"Previous route:\n");
    NSLog(@"%@\n", routeDescription);
    NSLog(@"Current route:\n");
    NSLog(@"%@\n", newRoute);
    AVAudioSessionPortDescription *inputPort = newRoute.inputs[0];
    NSString *inputName = inputPort.portName;
    NSString *inputType = inputPort.portType;
    AVAudioSessionPortDescription *outputPort = newRoute.outputs[0];
    NSString *outputName = outputPort.portName;
    NSString *outputType = outputPort.portType;
    
    bool notify = true;
    if ([outputType isEqual:@"Receiver"]){
        bool success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker
                                             error:&error];
        if (success){
        // about to change again, correctly this time
            notify = false;
        }
    }
    
    if (notify){
        NSString* jsString = [[NSString alloc] initWithFormat:@"ttsPlugin.callbacks.audioRouteChanged(\"%@\",\"%@\",\"%@\",\"%@\")",inputName,inputType,outputName,outputType];
        [self.commandDelegate evalJs:jsString];
    }
}

- (void)handleMediaServerReset:(NSNotification *)notification
{
    NSLog(@"Media server has reset");
}

- (void)speak:(CDVInvokedUrlCommand*)command{
    NSString* text = [command.arguments objectAtIndex:0];
    
    //if (true){
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error;
    bool success = true;
    //	    success = [session setCategory:AVAudioSessionCategoryPlayAndRecord
    //	                  withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionAllowBluetoothA2DP
    //	                        error:&error];
    //	    if (!success) NSLog(@"Error setting setCategory! %@\n", [error localizedDescription]);
    if (&AVAudioSessionModeSpokenAudio!=nil){
        //      [session setMode:AVAudioSessionModeSpokenAudio error:nil];
    }
    //success = [session setActive:YES error:&error];
    if (!success) NSLog(@"Error setting session active! %@\n", [error localizedDescription]);
    //}
    
    //[synth volume];

    //AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:@"by not setting it it should use the default cool cool"];
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:text];
    
    // set voice, note nil = default voice
    utterance.voice = globalVoice;
    
    //NSLog(@"max: %f", AVSpeechUtteranceMaximumSpeechRate);
    //NSLog(@"min: %f", AVSpeechUtteranceMinimumSpeechRate);
    //NSLog(@"default: %f", AVSpeechUtteranceDefaultSpeechRate);
    utterance.rate = rate*AVSpeechUtteranceDefaultSpeechRate/0.2;
    //NSLog(@"current: %f", utterance.rate);
    
    [synth speakUtterance:utterance];

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"OK"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)stop:(CDVInvokedUrlCommand*)command{
    //if (synth.isSpeaking){
        [synth stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    //}
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"OK"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)destroy:(CDVInvokedUrlCommand*)command{
    //if (synth.isSpeaking){
    [synth stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    synth = nil;
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error;
    bool success = [session setActive:NO error:&error];
    if (!success) NSLog(@"Error setting session inactive! %@\n", [error localizedDescription]);

    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"OK"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)getSpeechStatus:(CDVInvokedUrlCommand*)command{
    bool isSpeaking = [synth isSpeaking];
    bool isPaused = [synth isPaused];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"stopped"];
    
    if (isSpeaking && isPaused){
        // *speechStatus = @"paused";
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"paused"];
    }else if(isSpeaking){
        // *speechStatus = @"speaking";
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"speaking"];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)pause:(CDVInvokedUrlCommand*)command{
    //if (synth.isSpeaking){
        [synth pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    //}
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"OK"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)resume:(CDVInvokedUrlCommand*)command{
    if (synth.isPaused){
        [synth continueSpeaking];
    }
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"OK"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)restart:(CDVInvokedUrlCommand*)command{
    [synth continueSpeaking];
    [synth stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"OK"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance{
    //NSLog(@"Started Speaking %@", utterance);
    [self.commandDelegate evalJs:@"ttsPlugin.callbacks.startedSpeaking()"];
}
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance{
    NSLog(@"Finished Speaking %@", utterance.speechString);
    [self.commandDelegate evalJs:@"ttsPlugin.callbacks.finishedSpeaking()"];
}
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didPauseSpeechUtterance:(AVSpeechUtterance *)utterance{
    //NSLog(@"Paused Speaking %@", utterance);
    [self.commandDelegate evalJs:@"ttsPlugin.callbacks.pausedSpeaking()"];
}
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didContinueSpeechUtterance:(AVSpeechUtterance *)utterance{
    //NSLog(@"Continued Speaking %@ ", utterance);
    [self.commandDelegate evalJs:@"ttsPlugin.callbacks.continuedSpeaking()"];
}
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance{
    //NSLog(@"Cancelled Speaking %@", utterance);
    [self.commandDelegate evalJs:@"ttsPlugin.callbacks.cancelledSpeaking()"];
}
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer willSpeakRangeOfSpeechString:(NSRange)characterRange utterance:(AVSpeechUtterance *)utterance{
    //NSLog(@"willSpeakRangeOfSpeechString: %@", NSStringFromRange(characterRange));
    NSString* jsString = [[NSString alloc] initWithFormat:@"ttsPlugin.callbacks.currentRangeOfSpeech(\"%@\")",NSStringFromRange(characterRange)];
    [self.commandDelegate evalJs:jsString];
}

@end
