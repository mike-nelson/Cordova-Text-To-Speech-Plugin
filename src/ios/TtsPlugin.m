#import "TtsPlugin.h"
#import <Cordova/CDV.h>
#import <AVFoundation/AVFoundation.h>

@implementation TtsPlugin

// customised by Mike Nelson, beweb

AVSpeechSynthesizer *synth;
//NSString *lang = @"en-US";
NSString *lang = @"en-US";
AVSpeechSynthesisVoice *globalVoice;
double rate = 0.2;
NSString *currentLocale;
NSString *currentSpeechText = @"nothing yet";
NSString* currentSpeechCallbackId;
bool isDebug = YES;

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
  
 //   [self initAudioSession:command];
    
//    for (AVSpeechSynthesisVoice *voice in [AVSpeechSynthesisVoice speechVoices]) {
//        NSString *language = voice.language;
//        if ([language isEqualToString:currentLocale]){
//           /*NSLog(@"setting voice to locale: %@", currentLocale);*/
//            globalVoice = voice;
//        }
//    }
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    // track route change notification
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleRouteChange:)
                                                 name:AVAudioSessionRouteChangeNotification
                                               object:audioSession];
    
    // track interruptions
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleInterruption:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:audioSession];
    
    // track interruptions
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleSecondaryAudio:)
                                                 name:AVAudioSessionSilenceSecondaryAudioHintNotification
                                               object:audioSession];
    
    // track interruptions
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMediaServicesWereLost:)
                                                 name:AVAudioSessionMediaServicesWereLostNotification
                                               object:audioSession];
    
    // track interruptions
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMediaServicesWereReset:)
                                                 name:AVAudioSessionMediaServicesWereResetNotification
                                               object:audioSession];
    

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
        [self sendErrorWithMessage:@"getVoices crash" sourceMessage:exception.reason command:command];
        return;
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

- (void)setAudioSessionPlayAndRecord:(CDVInvokedUrlCommand*)command{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error;
	
    AVAudioSessionRouteDescription* currentRoute = [audioSession currentRoute];
    AVAudioSessionPortDescription *inputPort = currentRoute.inputs[0];
    if (inputPort.portType == AVAudioSessionPortCarAudio) {
        NSLog(@"TTS Plugin: AVAudioSessionPortCarAudio %@", inputPort.portName);
        if ([inputPort.portName isEqualToString:@"CarPlay"]) {
            NSLog(@"TTS Plugin: yay carplay!");
        }
    }
    
    
	//was AVAudioSessionModeVideoChat,AVAudioSessionModeVideoRecording
    bool success = [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                                       mode:AVAudioSessionModeSpokenAudio
                                    options:AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionAllowBluetoothA2DP
                                      error:&error];
    if (!success) {
        NSLog(@"setAudioSessionPlayAndRecord Error setting setCategory! %@\n", [error localizedDescription]);
        [self sendErrorWithMessage:@"TTS setAudioSessionPlayAndRecord: Error setting setCategory" sourceMessage:error.localizedDescription command:command];
        return;
    }else{
        [self jlog:@"setAudioSessionPlayAndRecord init audio session success"];
    }
    
    
    
    [self jlog:@"setAudioSessionPlayAndRecord looking for bluetooth handsfree or carplay"];
    NSArray* routes = [audioSession availableInputs];
    AVAudioSessionPortDescription* bestRoute = nil;
    for (AVAudioSessionPortDescription* route in routes) {
        if (route.portType == AVAudioSessionPortBluetoothHFP) {
            [self jlog:@"setAudioSessionPlayAndRecord found bluetooth handsfree"];
            bestRoute = route;
        }
    }
    for (AVAudioSessionPortDescription* route in routes) {
        if (route.portType == AVAudioSessionPortCarAudio) {
            [self jlog:@"setAudioSessionPlayAndRecord found car audio, better than bluetooth HFP"];
            bestRoute = route;
        }
    }
    if (bestRoute){
        [audioSession setPreferredInput:bestRoute error:nil];
    }
    
    //[audioSession overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    
    success = [audioSession setActive:YES error:&error];
    if (!success) {
        NSLog(@"setAudioSessionPlayAndRecord Error setting session active! %@\n", [error localizedDescription]);
        [self sendErrorWithMessage:@"TTS setAudioSessionPlayAndRecord: Error setting audio session active" sourceMessage:error.localizedDescription command:command];
        return;
    }else{
        NSLog(@"setAudioSessionPlayAndRecord session active");
    }
    
    
}

- (void)setAudioSessionPlayback:(CDVInvokedUrlCommand*)command{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error;
    bool success = [audioSession setCategory:AVAudioSessionCategoryPlayback
                                       mode:AVAudioSessionModeSpokenAudio
                                    options:AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionAllowBluetooth | AVAudioSessionCategoryOptionAllowBluetoothA2DP
                                      error:&error];
    if (!success) {
        NSLog(@"setAudioSessionPlayback Error setting setCategory! %@\n", [error localizedDescription]);
        [self sendErrorWithMessage:@"TTS setAudioSessionPlayback: Error setting setCategory" sourceMessage:error.localizedDescription command:command];
        return;
    }else{
        [self jlog:@"init audio session success"];
    }
    
    success = [audioSession setActive:YES error:&error];
    if (!success) {
        NSLog(@"setAudioSessionPlayback Error setting session active! %@\n", [error localizedDescription]);
        [self sendErrorWithMessage:@"TTS setAudioSessionPlayback: Error setting audio session active" sourceMessage:error.localizedDescription command:command];
        return;
    }
}

- (void)handleRouteChange:(NSNotification *)notification
{
    
 // 20200127 removed return, need for end car journey   return;
    
    NSUInteger reasonValue = [[notification.userInfo valueForKey:AVAudioSessionRouteChangeReasonKey] intValue];
    AVAudioSessionRouteDescription *routeDescription = [notification.userInfo valueForKey:AVAudioSessionRouteChangePreviousRouteKey];
    
    if (isDebug) NSLog(@"Route change:");
    switch (reasonValue) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            NSLog(@"     NewDeviceAvailable");
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
            NSLog(@"     OldDeviceUnavailable");
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            NSLog(@"     CategoryChange");
            //NSLog(@" New Category: %@", [[AVAudioSession sharedInstance] category]);
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
        case AVAudioSessionRouteChangeReasonRouteConfigurationChange:
            NSLog(@"     RouteConfigurationChange");
            break;
        default:
            NSLog(@"     ReasonUnknown");
    }
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error;
    
    AVAudioSessionRouteDescription *newRoute = session.currentRoute;
    if (isDebug||true) NSLog(@"Previous route:\n");
    if (isDebug||true) NSLog(@"%@\n", routeDescription);
    if (isDebug||true) NSLog(@"Current route:\n");
    if (isDebug||true) NSLog(@"%@\n", newRoute);
    
    if (newRoute!=nil && newRoute.inputs!=nil && [newRoute.inputs count]>0 && newRoute.outputs!=nil && [newRoute.outputs count]>0){
        AVAudioSessionPortDescription *inputPort = newRoute.inputs[0];
        NSString *inputName = inputPort.portName;
        NSString *inputType = inputPort.portType;
        AVAudioSessionPortDescription *outputPort = newRoute.outputs[0];
        NSString *outputName = outputPort.portName;
        NSString *outputType = outputPort.portType;
        
        bool notify = true;
        if ([outputType isEqual:@"Receiver"]){
            // try to push user away from reciever and on to speaker as this is usually what is wanted
            // it seems to go on to the receiver by itself incorrectly
            bool success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
            if (success){
            // about to change again, correctly this time
                notify = false;
            }
        }
        
        if (notify){
            NSString* jsString = [[NSString alloc] initWithFormat:@"ttsPlugin.callbacks.audioRouteChanged(\"%@\",\"%@\",\"%@\",\"%@\",\"%lu\")",inputName,inputType,outputName,outputType,reasonValue];
            [self.commandDelegate evalJs:jsString];
        }
    }
    
    // example
//    2020-01-27 13:40:37.513932+1300 SpeakingEmail[2380:899637]      OldDeviceUnavailable
//    2020-01-27 13:40:37.516228+1300 SpeakingEmail[2380:899637] Previous route:
//    2020-01-27 13:40:37.516743+1300 SpeakingEmail[2380:899637] <AVAudioSessionRouteDescription: 0x2810f6960,
//    inputs = (
//              "<AVAudioSessionPortDescription: 0x2810f7c30, type = MicrophoneBuiltIn; name = iPhone Microphone; UID = Built-In Microphone; selectedDataSource = Front>"
//              );
//    outputs = (
//               "<AVAudioSessionPortDescription: 0x2810f7e70, type = CarAudio; name = CarPlay; UID = 10:98:C3:B1:8C:F8-Audio-AudioMain-245135381192083; selectedDataSource = (null)>"
//               )>
//    2020-01-27 13:40:37.517853+1300 SpeakingEmail[2380:899637] Current route:
//    2020-01-27 13:40:37.518012+1300 SpeakingEmail[2380:899637] <AVAudioSessionRouteDescription: 0x2810d6040,
//    inputs = (
//              "<AVAudioSessionPortDescription: 0x2810d5d30, type = MicrophoneBuiltIn; name = iPhone Microphone; UID = Built-In Microphone; selectedDataSource = Front>"
//              );
//    outputs = (
//               "<AVAudioSessionPortDescription: 0x2810d71d0, type = Speaker; name = Speaker; UID = Speaker; selectedDataSource = (null)>"
//               )>
}

 - (void)handleInterruption:(NSNotification *)notification
{
    [self jlog:@"handleInterruption notification"];
    NSDictionary *userInfo = notification.userInfo;
    NSInteger interuptionType = [[userInfo valueForKey:AVAudioSessionInterruptionTypeKey] integerValue];
    switch (interuptionType) {
        case AVAudioSessionInterruptionTypeBegan:
            NSLog(@"Audio Session Interruption case started.");
    [synth stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
            [self jlog:@"handleInterruption BEGIN"];
            [self.commandDelegate evalJs:@"ttsPlugin.callbacks.handleInterruptionStart()"];
            break;
            
        case AVAudioSessionInterruptionTypeEnded:
            NSLog(@"Audio Session Interruption case ended.");
            NSInteger interuptionOption = [[userInfo valueForKey:AVAudioSessionInterruptionOptionKey] integerValue];
            if (interuptionOption==AVAudioSessionInterruptionOptionShouldResume){
                NSLog(@"Audio Session Interruption case ended SHOULD RESUME.");
            [synth continueSpeaking];
                [self jlog:@"handleInterruption SHOULD RESUME"];
                [self.commandDelegate evalJs:@"ttsPlugin.callbacks.handleInterruptionEnd(true)"];
            }else{
                NSLog(@"Audio Session Interruption case ended SHOULD NOT RESUME.");
                [self jlog:@"handleInterruption SHOULD NOT RESUME"];
                [self.commandDelegate evalJs:@"ttsPlugin.callbacks.handleInterruptionEnd(false)"];
            }
            break;
            
        default:
            NSLog(@"Audio Session Interruption Notification case default.");
            break;
    }
}
 
 - (void)handleSecondaryAudio:(NSNotification *)notification
{
    [self jlog:@"handleSecondaryAudio notification"];
    NSDictionary *userInfo = notification.userInfo;
    NSInteger hintType = [[userInfo valueForKey:AVAudioSessionSilenceSecondaryAudioHintTypeKey] integerValue];
    if (hintType==AVAudioSessionSilenceSecondaryAudioHintTypeBegin){
        [self jlog:@"handleSecondaryAudio BEGIN"];
        NSLog(@"Audio Session AVAudioSessionSilenceSecondaryAudioHintTypeBegin case BEGIN.");
        // just treat same as interruption - have never seen it happen yet but seems like it should be same handling
        [self.commandDelegate evalJs:@"ttsPlugin.callbacks.handleInterruptionStart()"];
    }else{
        [self jlog:@"handleSecondaryAudio END"];
        NSLog(@"Audio Session AVAudioSessionSilenceSecondaryAudioHintTypeBegin case END.");
        [self.commandDelegate evalJs:@"ttsPlugin.callbacks.handleInterruptionEnd(true)"];
    }
}
 
 - (void)handleMediaServicesWereLost:(NSNotification *)notification
{
    [self jlog:@"handleSMediaServicesWereLost notification"];
}
 
 - (void)handleMediaServicesWereReset:(NSNotification *)notification
{
    [self jlog:@"handleSMediaServicesWereReset notification"];
}
 
 - (void)handleMediaServerReset:(NSNotification *)notification
{
    [self jlog:@"Media server has reset"];
    [self.commandDelegate evalJs:@"ttsPlugin.callbacks.handleMediaServerReset()"];
}

////////////////////////// commands ///////////////////////////////////////////

- (void)speak:(CDVInvokedUrlCommand*)command{
    NSString* text = [command.arguments objectAtIndex:0];
    if (isDebug) NSLog(@"TTSPlugin - speak called: %@", text);
    
    currentSpeechCallbackId = command.callbackId;
    currentSpeechText = text;
    
    //if (true){
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error;
    bool success = [audioSession setActive:YES error:&error];
    if (!success) {
        NSLog(@"Error setting session active! %@\n", [error localizedDescription]);
        [self sendErrorWithMessage:@"TTS speak: Error setting audio session active" sourceMessage:error.localizedDescription command:command];
        return;
    }
    
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
    //NSLog(@"TTSPlugin - speak call done: %@", utterance.speechString);
    
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"OK"];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)stop:(CDVInvokedUrlCommand*)command{
   if (isDebug)  NSLog(@"TTSPlugin - stop called");
    currentSpeechText = @"cancelled speaking, dont callback on finished";
    if (synth.isSpeaking){            // mn 2019 reintroduced this conditional
        [synth stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    }
    
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

///////////////////////////////// events //////////////////////////////////////////////////

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance{
    //NSLog(@"Started Speaking %@", utterance.speechString);
    [self.commandDelegate evalJs:@"ttsPlugin.callbacks.startedSpeaking()"];
}
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance{
    if (utterance.speechString==currentSpeechText){
        // mn 2018 - now only fires this callback if the most recently played speech is finished successfully - not after stop()
        // otherwise previous speech callback fires milliseconds after stop() which can be after the next play()
        if (isDebug) NSLog(@"Finished Speaking %@", utterance.speechString);
        //NSString* jsString = [[NSString alloc] initWithFormat:@"ttsPlugin.callbacks.finishedSpeaking(\"%@\")",utterance.speechString];
        [self.commandDelegate evalJs:@"ttsPlugin.callbacks.finishedSpeaking()"];

        NSMutableDictionary * event = [[NSMutableDictionary alloc]init];
        [event setValue:@"finishedSpeaking" forKey:@"type"];
        [event setValue:utterance.speechString forKey:@"speechString"];
        CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:event];
        [pluginResult setKeepCallbackAsBool:NO];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:currentSpeechCallbackId];
    }else{
        if (isDebug) NSLog(@"Cancelled Speaking %@", utterance.speechString);
    }
    //[self.commandDelegate evalJs:@"ttsPlugin.callbacks.finishedSpeaking()"];
}
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didPauseSpeechUtterance:(AVSpeechUtterance *)utterance{
    if (isDebug) NSLog(@"Paused Speaking %@", utterance);
    [self.commandDelegate evalJs:@"ttsPlugin.callbacks.pausedSpeaking()"];
}
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didContinueSpeechUtterance:(AVSpeechUtterance *)utterance{
    if (isDebug) NSLog(@"Continued Speaking %@ ", utterance);
    [self.commandDelegate evalJs:@"ttsPlugin.callbacks.continuedSpeaking()"];
}
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance{
    if (isDebug) NSLog(@"Cancelled Speaking %@", utterance);
    [self.commandDelegate evalJs:@"ttsPlugin.callbacks.cancelledSpeaking()"];
}
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer willSpeakRangeOfSpeechString:(NSRange)characterRange utterance:(AVSpeechUtterance *)utterance{
    //NSLog(@"willSpeakRangeOfSpeechString: %@", NSStringFromRange(characterRange));
//    NSString* jsString = [[NSString alloc] initWithFormat:@"ttsPlugin.callbacks.currentRangeOfSpeech(\"%@\")",NSStringFromRange(characterRange)];
//    [self.commandDelegate evalJs:jsString];
  
    NSMutableDictionary * event = [[NSMutableDictionary alloc]init];
    [event setValue:@"currentRangeOfSpeech" forKey:@"type"];
    [event setValue:NSStringFromRange(characterRange) forKey:@"currentText"];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:event];
    [pluginResult setKeepCallbackAsBool:YES];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:currentSpeechCallbackId];

    
}

-(void) sendErrorWithMessage:(NSString *)errorMessage sourceMessage:(NSString *)sourceMessage command:(CDVInvokedUrlCommand*)command
{
    NSLog(@"recog report error: %@", errorMessage);
    NSMutableDictionary * event = [[NSMutableDictionary alloc]init];
    [event setValue:@"error" forKey:@"type"];
    [event setValue:errorMessage forKey:@"message"];
    [event setValue:sourceMessage forKey:@"sourceMessage"];
    CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:event];
    [pluginResult setKeepCallbackAsBool:NO];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

-(void) jlog:(NSString *)message
{
    NSLog(@"TTS Plugin: %@", message);
    NSString* jsString = [[NSString alloc] initWithFormat:@"window.jlog(\"TTS Plugin Log: %@\")",message];
    [self.commandDelegate evalJs:jsString];
}

@end
