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

static const NSTimeInterval kSpeechProgressTimeout = 5.0;
static const NSTimeInterval kSpeechSecondsPerCharacter = 0.2;

@implementation OATTSCommandPlayerImpl {
    AVSpeechSynthesizer *_synthesizer;
    OAVoiceRouter *_vrt;
    NSString *_voiceProvider;
    JSContext *_context;
    AVAudioSession *_audioSession;
    dispatch_queue_t _speechQueue;
    NSMutableArray<NSString *> *_pendingPhrases;
    AVSpeechUtterance *_currentUtterance;
    NSUInteger _speechWatchToken;
    BOOL _isStopRequested;
    BOOL _isCleared;
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
        _synthesizer = [self createSynthesizer];
        _audioSession = [AVAudioSession sharedInstance];
        _vrt = voiceRouter;
        _voiceProvider = provider == nil ? @"" : provider;
        _speechQueue = [self.class speechQueue];
        _pendingPhrases = [NSMutableArray array];

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

    NSString *toSpeak = [[builder getUtterances] componentsJoinedByString:@" "];
    dispatch_async(_speechQueue, ^{
        if (self->_isCleared)
            return;

        [self->_pendingPhrases addObject:toSpeak];
        [self speakNextPhrase];
    });
}

- (void)speakNextPhrase
{
    if (_currentUtterance)
        return;

    if (_pendingPhrases.count > 0 && [self hasActiveCall])
    {
        NSLog(@"[OATTSCommandPlayerImpl] Cannot play commands during a phone call");
        [_pendingPhrases removeAllObjects];
    }
    if (_pendingPhrases.count == 0)
    {
        [self deactivateAudioSession];
        return;
    }

    [self activateAudioSession];
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:_pendingPhrases.firstObject];
    [_pendingPhrases removeObjectAtIndex:0];
    utterance.voice = [self voiceToUse];
    utterance.prefersAssistiveTechnologySettings = YES;
    _currentUtterance = utterance;
    _isStopRequested = NO;
    [_synthesizer speakUtterance:utterance];
    [self watchSpeechWithTimeout:kSpeechProgressTimeout];
}

- (void)finishUtterance:(AVSpeechUtterance *)utterance
{
    if (_currentUtterance != utterance)
        return;

    _currentUtterance = nil;
    [self speakNextPhrase];
}

- (void)watchSpeechWithTimeout:(NSTimeInterval)timeout
{
    NSUInteger watchToken = ++_speechWatchToken;
    __weak OATTSCommandPlayerImpl *weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC)), _speechQueue, ^{
        [weakSelf handleSpeechTimeout:watchToken];
    });
}

- (void)handleSpeechTimeout:(NSUInteger)watchToken
{
    if (watchToken != _speechWatchToken || !_currentUtterance)
        return;

    NSLog(@"[OATTSCommandPlayerImpl] Speech synthesizer got stuck, recreating it");
    [self replaceSynthesizer];
    _currentUtterance = nil;
    [self speakNextPhrase];
}

- (AVSpeechSynthesizer *)createSynthesizer
{
    AVSpeechSynthesizer *synthesizer = [[AVSpeechSynthesizer alloc] init];
    synthesizer.delegate = self;
    return synthesizer;
}

- (void)replaceSynthesizer
{
    [self stopSynthesizer:_synthesizer];
    _synthesizer = [self createSynthesizer];
}

- (void)stopSynthesizer:(AVSpeechSynthesizer *)synthesizer
{
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    });
}

- (void)activateAudioSession
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
        return;
    }

    NSError *activationError = nil;
    if (![_audioSession setActive:YES error:&activationError])
        NSLog(@"[OATTSCommandPlayerImpl] Error activating audio session: %@", activationError.localizedDescription);
}

- (void)deactivateAudioSession
{
    [_audioSession setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
}

- (BOOL)hasActiveCall
{
    for (CXCall *call in [[CXCallObserver alloc] init].calls)
    {
        if (!call.hasEnded)
            return YES;
    }
    return NO;
}

- (void)stop
{
    dispatch_async(_speechQueue, ^{
        [self->_pendingPhrases removeAllObjects];
        if (!self->_currentUtterance || self->_isStopRequested)
            return;

        self->_isStopRequested = YES;
        [self replaceSynthesizer];
        [self watchSpeechWithTimeout:kSpeechProgressTimeout];
    });
}

- (void)clear
{
    dispatch_async(_speechQueue, ^{
        self->_isCleared = YES;
        [self->_pendingPhrases removeAllObjects];
        if (!self->_currentUtterance)
            return;

        self->_currentUtterance = nil;
        [self stopSynthesizer:self->_synthesizer];
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
        if (self->_currentUtterance != utterance || self->_isStopRequested)
            [self stopSynthesizer:synthesizer];
        else
            [self watchSpeechWithTimeout:kSpeechProgressTimeout + utterance.speechString.length * kSpeechSecondsPerCharacter];
    });
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer willSpeakRangeOfSpeechString:(NSRange)characterRange utterance:(AVSpeechUtterance *)utterance
{
    dispatch_async(_speechQueue, ^{
        if (self->_currentUtterance == utterance && !self->_isStopRequested)
            [self watchSpeechWithTimeout:kSpeechProgressTimeout];
    });
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance
{
    dispatch_async(_speechQueue, ^{
        [self finishUtterance:utterance];
    });
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance
{
    dispatch_async(_speechQueue, ^{
        [self finishUtterance:utterance];
    });
}

- (BOOL)supportsStructuredStreetNames
{
    return YES;
}

#pragma mark - AVAudioSession Notifications

- (void)handleAudioSessionInterruption:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    AVAudioSessionInterruptionType type = (AVAudioSessionInterruptionType)[info[AVAudioSessionInterruptionTypeKey] unsignedIntegerValue];
    AVAudioSessionInterruptionReason reason = (AVAudioSessionInterruptionReason)[info[AVAudioSessionInterruptionReasonKey] unsignedIntegerValue];
    if (type != AVAudioSessionInterruptionTypeBegan || reason == AVAudioSessionInterruptionReasonAppWasSuspended)
        return;

    dispatch_async(_speechQueue, ^{
        [self->_pendingPhrases removeAllObjects];
        if (!self->_currentUtterance)
            return;

        [self replaceSynthesizer];
        self->_currentUtterance = nil;
    });
}

@end
