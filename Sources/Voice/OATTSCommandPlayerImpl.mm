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

static const NSTimeInterval kSpeechStallTimeout = 5.0;
static const NSTimeInterval kSpeechSecondsPerCharacter = 0.2;

@interface OATTSCommandPlayerImpl () <CXCallObserverDelegate>

@end

@implementation OATTSCommandPlayerImpl {
    AVSpeechSynthesizer *_synthesizer;
    OAVoiceRouter *_vrt;
    NSString *_voiceProvider;
    JSContext *_context;
    AVAudioSession *_audioSession;
    BOOL _isInterrupted;
    BOOL _isCleared;
    dispatch_queue_t _speechQueue;
    NSMutableSet<AVSpeechUtterance *> *_queuedUtterances;
    NSUInteger _lastSpeechEvent;
    CXCallObserver *_callObserver;
}

+ (dispatch_queue_t)speechQueue
{
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("net.osmand.voice-prompts", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
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
        _speechQueue = [self.class speechQueue];
        _queuedUtterances = [NSMutableSet set];
        _callObserver = [[CXCallObserver alloc] init];
        [_callObserver setDelegate:self queue:_speechQueue];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleAudioSessionInterruption:)
                                                     name:AVAudioSessionInterruptionNotification
                                                   object:_audioSession];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleApplicationWillEnterForeground:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
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
    if (_isCleared)
        return;

    if (_isInterrupted)
    {
        NSLog(@"[OATTSCommandPlayerImpl] Cannot play commands: Audio session is currently interrupted.");
        return;
    }

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

- (BOOL)activateAudioSession
{
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
    {
        NSLog(@"[OATTSCommandPlayerImpl] Error activating audio session: %@", activationError.localizedDescription);
        return NO;
    }
    return YES;
}

- (void)deactivateAudioSession
{
    if (!_isInterrupted)
        [_audioSession setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
}

- (void)completeUtterance:(AVSpeechUtterance *)utterance
{
    if (_isCleared)
        return;

    [_queuedUtterances removeObject:utterance];
    if (_queuedUtterances.count > 0)
        [self watchSpeechWithTimeout:kSpeechStallTimeout];
    else
        [self deactivateAudioSession];
}

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
    if (_isCleared || speechEvent != _lastSpeechEvent || _queuedUtterances.count == 0)
        return;

    NSLog(@"[OATTSCommandPlayerImpl] Speech synthesizer is stuck, dropping %lu queued prompts", (unsigned long)_queuedUtterances.count);
    [self resetSynthesizer];
    [self deactivateAudioSession];
}

- (void)resetSynthesizer
{
    [self detachSynthesizer];
    _synthesizer = [[AVSpeechSynthesizer alloc] init];
    _synthesizer.delegate = self;
}

- (void)detachSynthesizer
{
    AVSpeechSynthesizer *synthesizer = _synthesizer;
    synthesizer.delegate = nil;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        [synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    });
    [_queuedUtterances removeAllObjects];
}

- (void)stop
{
    dispatch_async(_speechQueue, ^{
        if (self->_queuedUtterances.count == 0)
            return;

        [self resetSynthesizer];
        [self deactivateAudioSession];
    });
}

- (void)clear
{
    dispatch_async(_speechQueue, ^{
        self->_isCleared = YES;
        if (self->_queuedUtterances.count == 0)
            return;

        [self detachSynthesizer];
        [self deactivateAudioSession];
    });
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
        [self completeUtterance:utterance];
    });
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance
{
    dispatch_async(_speechQueue, ^{
        [self completeUtterance:utterance];
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
    AVAudioSessionInterruptionReason reason = (AVAudioSessionInterruptionReason)[info[AVAudioSessionInterruptionReasonKey] unsignedIntegerValue];
    if (type == AVAudioSessionInterruptionTypeBegan && reason == AVAudioSessionInterruptionReasonAppWasSuspended)
        return;

    dispatch_async(_speechQueue, ^{
        self->_isInterrupted = type == AVAudioSessionInterruptionTypeBegan;
        if (self->_isInterrupted && self->_queuedUtterances.count > 0)
            [self resetSynthesizer];
    });
}

- (void)handleApplicationWillEnterForeground:(NSNotification *)notification
{
    dispatch_async(_speechQueue, ^{
        if (![self hasActiveCall])
            self->_isInterrupted = NO;
    });
}

#pragma mark - CXCallObserverDelegate

- (BOOL)hasActiveCall
{
    for (CXCall *call in _callObserver.calls)
    {
        if (!call.hasEnded)
            return YES;
    }
    return NO;
}

- (void)callObserver:(CXCallObserver *)callObserver callChanged:(CXCall *)call
{
    if (call.hasEnded && ![self hasActiveCall])
        _isInterrupted = NO;
}

@end
