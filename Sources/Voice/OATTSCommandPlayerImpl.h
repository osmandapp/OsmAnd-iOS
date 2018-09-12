//
//  OATTSCommandPlayerImpl.h
//  OsmAnd
//
//  Created by Paul on 7/10/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#include "OAAbstractCommandPlayer.h"
#include "OAVoiceRouter.h"

@interface OATTSCommandPlayerImpl : OAAbstractCommandPlayer<AVSpeechSynthesizerDelegate>

- (instancetype) initWithVoiceRouter:(OAVoiceRouter *) voiceRouter voiceProvider:(NSString *)provider;
- (void)playCommands:(OACommandBuilder *)builder;

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance;

@end
