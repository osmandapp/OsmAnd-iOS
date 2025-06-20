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
#import "OARootViewController.h"
#import "Localization.h"

#include <JavaScriptCore/JavaScriptCore.h>

@implementation OATTSCommandPlayerImpl {
    AVSpeechSynthesizer *synthesizer;
    OAVoiceRouter *vrt;
    NSString *voiceProvider;
    JSContext *context;
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
        if ([voiceProvider hasPrefix:@"fa"])
        {
            NSString *details = OALocalizedString([OAUtilities isiOSAppOnMac] ? @"download_persian_voice_alert_descr_macos" : @"download_persian_voice_alert_descr_ios");
            dispatch_async(dispatch_get_main_queue(), ^{
                [OAUtilities showToast:OALocalizedString(@"download_persian_voice_alert_title") details:details duration:4 inView:OARootViewController.instance.view];
            });
        }
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

- (BOOL)supportsStructuredStreetNames
{
    return YES;
}

@end
