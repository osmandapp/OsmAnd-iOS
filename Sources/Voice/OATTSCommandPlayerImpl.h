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

@interface OATTSCommandPlayerImpl : OAAbstractCommandPlayer

- (instancetype) initWithVoiceRouter:(OAVoiceRouter *) voiceRouter voiceProvider:(NSString *)provider;
- (void)playCommands:(OACommandBuilder *)builder;

@end
