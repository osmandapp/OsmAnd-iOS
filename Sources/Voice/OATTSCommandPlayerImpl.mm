//
//  OATTSCommandPlayerImpl.m
//  OsmAnd
//
//  Created by Paul on 7/10/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "OATTSCommandPlayerImpl.h"
#import "OACommandBuilder.h"
#import "OAVoiceRouter.h"
#import "OAAppSettings.h"

#include <JavaScriptCore/JavaScriptCore.h>

@implementation OATTSCommandPlayerImpl {
    AVSpeechSynthesizer *synthesizer;
    OAVoiceRouter *vrt;
    NSString *voiceProvider;
    JSContext *context;
    AVAudioSession *audioSession;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        synthesizer = [[AVSpeechSynthesizer alloc] init];
    }
    return self;
}

- (instancetype) initWithVoiceRouter:(OAVoiceRouter *) voiceRouter voiceProvider:(NSString *)provider
{
    self = [super init];
    if (self)
    {
        synthesizer = [[AVSpeechSynthesizer alloc] init];
        synthesizer.delegate = self;
        audioSession = [AVAudioSession sharedInstance];
        vrt = voiceRouter;
        voiceProvider = provider == nil ? @"" : provider;
        NSString *resourceName = [NSString stringWithFormat:@"%@%@", voiceProvider, @"_tts"];
        NSString *jsPath = [[NSBundle mainBundle] pathForResource:resourceName ofType:@"js"];
        if (jsPath == nil) {
            return nil;
        }
        context = [[JSContext alloc] init];
        NSString *scriptString = [NSString stringWithContentsOfFile:jsPath encoding:NSUTF8StringEncoding error:nil];
        [context evaluateScript:scriptString];
    }
    return self;
}

- (void)playCommands:(OACommandBuilder *)builder
{
    if ([vrt isMute]) {
        return;
    }
    
    [audioSession setCategory:AVAudioSessionCategoryPlayback
                         mode:AVAudioSessionModeVoicePrompt
                      options:(AVAudioSessionCategoryOptionDuckOthers | AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers)
                        error:nil];
    [audioSession setActive:YES error:nil];

    NSMutableString *toSpeak = [[NSMutableString alloc] init];
    NSArray<NSString *> *uterrances = [builder getUtterances];
    for (NSString *utterance in uterrances) {
        [toSpeak appendString:utterance];
    }
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:toSpeak];
    utterance.voice = [self voiceToUse];
    utterance.prefersAssistiveTechnologySettings = YES;
    [synthesizer speakUtterance:utterance];
}

- (AVSpeechSynthesisVoice *)voiceToUse {
    AVSpeechSynthesisVoice *systemPreferredVoice = [AVSpeechSynthesisVoice voiceWithLanguage:voiceProvider];
    if (systemPreferredVoice) {
        return systemPreferredVoice;
    } else {
        NSLog(@"[OATTSCommandPlayerImpl] Invalid or unsupported locale identifier: %@, using current system language", voiceProvider);
        return [AVSpeechSynthesisVoice voiceWithLanguage:[AVSpeechSynthesisVoice currentLanguageCode]];
    }
}

- (OACommandBuilder *)newCommandBuilder {
    OACommandBuilder *commandBuilder = [[OACommandBuilder alloc] initWithCommandPlayer:self jsContext:context];
    OAAppSettings *settings = [OAAppSettings sharedManager];
    [commandBuilder setParameters:[OAMetricsConstant toTTSString:[settings.metricSystem get]] mode:YES];
    return commandBuilder;
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance
{
    [audioSession setActive:NO error:nil];
}

@end
