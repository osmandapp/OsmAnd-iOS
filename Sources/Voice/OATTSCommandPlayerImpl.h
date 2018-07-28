//
//  OATTSCommandPlayerImpl.h
//  OsmAnd
//
//  Created by Paul on 7/10/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//
#include "OAAbstractCommandPlayer.h"
#include "OAVoiceRouter.h"

@interface OATTSCommandPlayerImpl : OAAbstractCommandPlayer

- (instancetype) initWithVoiceRouter:(OAVoiceRouter *) voiceRouter;
- (void)playCommands:(OACommandBuilder *)builder;

@end
