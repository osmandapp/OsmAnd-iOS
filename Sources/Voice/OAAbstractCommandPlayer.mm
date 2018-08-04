//
//  OAAbstractPrologCommandPlayer.mm
//  OsmAnd
//
//  Created by PaulStets on 7/8/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//
#import "OAAbstractCommandPlayer.h"
#import "OACommandBuilder.h"
#import <Foundation/Foundation.h>

@implementation OAAbstractCommandPlayer
{
    
}

- (void)clear {
    
}

- (NSString *)getCurrentVoice {
    return nil;
}

- (NSString *)getLanguage {
    return nil;
}

- (OACommandBuilder *)newCommandBuilder {
    return nil;
}

- (void)playCommands:(OACommandBuilder *)builder {
    
}

- (void)stop {
    
}

- (BOOL)supportsStructuredStreetNames {
    return NO;
}

- (void)updateAudioStream:(int)streamType {
    
}

@end
