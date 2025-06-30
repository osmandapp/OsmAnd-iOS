//
//  OATTSCommandPlayerImpl.h
//  OsmAnd
//
//  Created by Paul on 7/10/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import "OAAbstractCommandPlayer.h"
#import "OAVoiceRouter.h"

@interface OATTSCommandPlayerImpl : OAAbstractCommandPlayer<AVSpeechSynthesizerDelegate>

- (instancetype) initWithVoiceRouter:(OAVoiceRouter *) voiceRouter voiceProvider:(NSString *)provider;
- (void)playCommands:(OACommandBuilder *)builder;

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance;

@end
