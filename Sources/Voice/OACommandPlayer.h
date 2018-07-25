//
//  OACommandPlayer.h
//  OsmAnd
//
//  Created by Alexey Kulish on 23/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OACommandBuilder;

@protocol OACommandPlayer <NSObject>

@required

- (NSString *) getCurrentVoice;

- (OACommandBuilder *) newCommandBuilder;

- (void) playCommands:(OACommandBuilder *)builder;

- (void) clear;

- (void) updateAudioStream:(int)streamType;

- (NSString *) getLanguage;

- (BOOL) supportsStructuredStreetNames;

- (void) stop;

@end
