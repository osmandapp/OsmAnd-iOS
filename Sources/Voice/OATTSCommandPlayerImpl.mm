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
    AVSpeechSynthesizer *_synthesizer;
    OAVoiceRouter *_vrt;
    NSString *_voiceProvider;
    JSContext *_context;
    AVAudioSession *_audioSession;
    BOOL _isInterrupted;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _synthesizer = [[AVSpeechSynthesizer alloc] init];
    }
    return self;
}

- (instancetype) initWithVoiceRouter:(OAVoiceRouter *)voiceRouter voiceProvider:(NSString *)provider
{
    self = [super init];
    if (self)
    {
        _synthesizer = [[AVSpeechSynthesizer alloc] init];
        _synthesizer.delegate = self;
        _audioSession = [AVAudioSession sharedInstance];
        _vrt = voiceRouter;
        _voiceProvider = provider == nil ? @"" : provider;
        _isInterrupted = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleAudioSessionInterruption:)
                                                     name:AVAudioSessionInterruptionNotification
                                                   object:_audioSession];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)playCommands:(OACommandBuilder *)builder
{
    if ([_vrt isMute])
        return;
    
    if (_isInterrupted)
    {
        NSLog(@"[OATTSCommandPlayerImpl] Cannot play commands: Audio session is currently interrupted.");
        return;
    }
    
    NSError *categoryError = nil;
    BOOL categorySet = [_audioSession setCategory:AVAudioSessionCategoryPlayback
                                             mode:AVAudioSessionModeVoicePrompt
                                          options:AVAudioSessionCategoryOptionDuckOthers
                                            error:&categoryError];
    if (!categorySet)
    {
        NSLog(@"[OATTSCommandPlayerImpl] Error setting audio session category: %@", categoryError.localizedDescription);
        return;
    }
    
    NSError *activationError = nil;
    BOOL activated = [_audioSession setActive:YES error:&activationError];
    if (!activated)
    {
        NSLog(@"[OATTSCommandPlayerImpl] Error activating audio session: %@", activationError.localizedDescription);
        return;
    }
    
    NSMutableString *toSpeak = [[NSMutableString alloc] init];
    NSArray<NSString *> *uterrances = [builder getUtterances];
    
    for (NSString *utterance in uterrances)
        [toSpeak appendString:utterance];
    
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:toSpeak];
    utterance.voice = [self voiceToUse];
    utterance.prefersAssistiveTechnologySettings = YES;
    [_synthesizer speakUtterance:utterance];
}

- (AVSpeechSynthesisVoice *)voiceToUse
{
    AVSpeechSynthesisVoice *systemPreferredVoice = [AVSpeechSynthesisVoice voiceWithLanguage:_voiceProvider];
    if (systemPreferredVoice)
    {
        return systemPreferredVoice;
    }
    else
    {
        if ([_voiceProvider hasPrefix:@"fa"])
        {
            NSString *details = OALocalizedString([OAUtilities isiOSAppOnMac] ? @"download_persian_voice_alert_descr_macos" : @"download_persian_voice_alert_descr_ios");
            dispatch_async(dispatch_get_main_queue(), ^{
                [OAUtilities showToast:OALocalizedString(@"download_persian_voice_alert_title") details:details duration:4 inView:OARootViewController.instance.view];
            });
        }
        NSLog(@"[OATTSCommandPlayerImpl] Invalid or unsupported locale identifier: %@, using current system language", _voiceProvider);
        return [AVSpeechSynthesisVoice voiceWithLanguage:[AVSpeechSynthesisVoice currentLanguageCode]];
    }
}

- (OACommandBuilder *)newCommandBuilder
{
    OACommandBuilder *commandBuilder = [[OACommandBuilder alloc] initWithCommandPlayer:self voiceProvider:_voiceProvider];
    OAAppSettings *settings = [OAAppSettings sharedManager];
    [commandBuilder setParameters:[OAMetricsConstant toTTSString:[settings.metricSystem get]] mode:YES];
    return commandBuilder;
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance
{
    if (!_isInterrupted)
    {
        NSError *error = nil;
        [_audioSession setActive:NO error:&error];
        if (error)
            NSLog(@"[OATTSCommandPlayerImpl] Error deactivating audio session: %@", error.localizedDescription);
    }
}

- (BOOL)supportsStructuredStreetNames
{
    return YES;
}

#pragma mark - AVAudioSession Notifications

- (void)handleAudioSessionInterruption:(NSNotification *)notification
{
    if (!notification)
        return;

    NSDictionary *info = notification.userInfo;
    AVAudioSessionInterruptionType type = (AVAudioSessionInterruptionType)[info[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];

    if (type == AVAudioSessionInterruptionTypeBegan)
    {
        _isInterrupted = YES;
        if ([_synthesizer isSpeaking])
            [_synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryWord];
    }
    else
    {
        AVAudioSessionInterruptionOptions options = [info[AVAudioSessionInterruptionOptionKey] unsignedIntegerValue];
        _isInterrupted = NO;
        if (options == AVAudioSessionInterruptionOptionShouldResume)
        {
            NSError *error = nil;
            BOOL activated = [_audioSession setActive:YES error:&error];
            if (!activated)
                NSLog(@"[OATTSCommandPlayerImpl] Error reactivating audio session: %@", error.localizedDescription);
            else
                NSLog(@"[OATTSCommandPlayerImpl] Audio session reactivated successfully.");
        }
    }
}

@end
