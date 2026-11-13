//
//  OATTSCommandPlayerImpl.m
//  OsmAnd
//
//  Created by Paul on 7/10/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <CallKit/CallKit.h>
#import "OATTSCommandPlayerImpl.h"
#import "OACommandBuilder.h"
#import "OAVoiceRouter.h"
#import "OAAppSettings.h"
#import "OARootViewController.h"
#import "Localization.h"

#include <JavaScriptCore/JavaScriptCore.h>

// With prompts queued, this long without a synthesizer event means it is stuck
static const NSTimeInterval kSpeechStallTimeout = 5.0;
// Not all voices report words, so before the first word allow time for the whole prompt
static const NSTimeInterval kSpeechSecondsPerCharacter = 0.2;

@implementation OATTSCommandPlayerImpl {
    AVSpeechSynthesizer *_synthesizer;
    OAVoiceRouter *_vrt;
    NSString *_voiceProvider;
    JSContext *_context;
    AVAudioSession *_audioSession;
    BOOL _isInterrupted;
    // Guards the fields below and serializes the audio session calls, which can block for a while
    dispatch_queue_t _speechQueue;
    NSMutableSet<AVSpeechUtterance *> *_queuedUtterances;
    NSUInteger _lastSpeechEvent;
    CXCallObserver *_callObserver;
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
        _speechQueue = dispatch_queue_create("net.osmand.voice-prompts", DISPATCH_QUEUE_SERIAL);
        _queuedUtterances = [NSMutableSet set];
        _callObserver = [[CXCallObserver alloc] init];
        
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
    
    NSMutableString *toSpeak = [[NSMutableString alloc] init];
    NSArray<NSString *> *uterrances = [builder getUtterances];
    
    for (NSString *utterance in uterrances)
        [toSpeak appendString:utterance];
    
    dispatch_async(_speechQueue, ^{
        [self speak:toSpeak];
    });
}

- (void)speak:(NSString *)text
{
    if (_isInterrupted)
    {
        if ([self hasActiveCall])
        {
            NSLog(@"[OATTSCommandPlayerImpl] Cannot play commands: Audio session is currently interrupted.");
            return;
        }
        // iOS does not guarantee that an interruption ends with a notification
        _isInterrupted = NO;
    }
    
    // The session stays active until the queue is empty, so queued prompts never start on a session being deactivated
    if (_queuedUtterances.count == 0 && ![self activateAudioSession])
        return;
    
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:text];
    utterance.voice = [self voiceToUse];
    utterance.prefersAssistiveTechnologySettings = YES;
    [_queuedUtterances addObject:utterance];
    [_synthesizer speakUtterance:utterance];
    
    if (_queuedUtterances.count == 1)
        [self watchSpeechWithTimeout:kSpeechStallTimeout];
}

- (BOOL)hasActiveCall
{
    for (CXCall *call in _callObserver.calls)
    {
        if (!call.hasEnded)
            return YES;
    }
    return NO;
}

- (BOOL)activateAudioSession
{
    // CarPlay plays voice prompts over the car's own audio only if both options are set
    AVAudioSessionCategoryOptions options = AVAudioSessionCategoryOptionDuckOthers;
    if ([[OAAppSettings sharedManager].pauseSpokenAudio get])
        options |= AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers;
    
    NSError *categoryError = nil;
    BOOL categorySet = [_audioSession setCategory:AVAudioSessionCategoryPlayback
                                             mode:AVAudioSessionModeVoicePrompt
                                          options:options
                                            error:&categoryError];
    if (!categorySet)
    {
        NSLog(@"[OATTSCommandPlayerImpl] Error setting audio session category: %@", categoryError.localizedDescription);
        return NO;
    }
    
    NSError *activationError = nil;
    BOOL activated = [_audioSession setActive:YES error:&activationError];
    if (!activated)
        NSLog(@"[OATTSCommandPlayerImpl] Error activating audio session: %@", activationError.localizedDescription);
    return activated;
}

- (void)deactivateAudioSession
{
    if (_isInterrupted)
        return;
    
    NSError *error = nil;
    if (![_audioSession setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error])
        NSLog(@"[OATTSCommandPlayerImpl] Error deactivating audio session: %@", error.localizedDescription);
}

// AVSpeechSynthesizer reports nothing when it fails to start the audio, for example while Siri is recording.
// It then stays in "speaking" state and every later prompt waits behind the stuck one, so it has to be replaced.
- (void)watchSpeechWithTimeout:(NSTimeInterval)timeout
{
    NSUInteger speechEvent = ++_lastSpeechEvent;
    __weak OATTSCommandPlayerImpl *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)), _speechQueue, ^{
        [weakSelf handleSpeechTimeout:speechEvent];
    });
}

- (void)handleSpeechTimeout:(NSUInteger)speechEvent
{
    if (speechEvent != _lastSpeechEvent || _queuedUtterances.count == 0)
        return;
    
    NSLog(@"[OATTSCommandPlayerImpl] Speech synthesizer is stuck, dropping %lu queued prompts", (unsigned long)_queuedUtterances.count);
    [self resetSynthesizer];
    [self deactivateAudioSession];
}

- (void)resetSynthesizer
{
    AVSpeechSynthesizer *synthesizer = _synthesizer;
    synthesizer.delegate = nil;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        [synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    });
    
    _synthesizer = [[AVSpeechSynthesizer alloc] init];
    _synthesizer.delegate = self;
    [_queuedUtterances removeAllObjects];
}

- (void)onUtteranceDone:(AVSpeechUtterance *)utterance
{
    if (![_queuedUtterances containsObject:utterance])
        return;
    
    [_queuedUtterances removeObject:utterance];
    if (_queuedUtterances.count > 0)
        [self watchSpeechWithTimeout:kSpeechStallTimeout];
    else
        [self deactivateAudioSession];
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

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance
{
    dispatch_async(_speechQueue, ^{
        [self watchSpeechWithTimeout:kSpeechStallTimeout + utterance.speechString.length * kSpeechSecondsPerCharacter];
    });
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer willSpeakRangeOfSpeechString:(NSRange)characterRange utterance:(AVSpeechUtterance *)utterance
{
    dispatch_async(_speechQueue, ^{
        [self watchSpeechWithTimeout:kSpeechStallTimeout];
    });
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance
{
    dispatch_async(_speechQueue, ^{
        [self onUtteranceDone:utterance];
    });
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance
{
    dispatch_async(_speechQueue, ^{
        [self onUtteranceDone:utterance];
    });
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

    dispatch_async(_speechQueue, ^{
        self->_isInterrupted = type == AVAudioSessionInterruptionTypeBegan;
        // The interruption cuts the audio of the current prompt, nothing is left to resume when it ends
        if (self->_isInterrupted && self->_queuedUtterances.count > 0)
            [self resetSynthesizer];
    });
}

@end
