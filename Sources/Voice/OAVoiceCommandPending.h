//
//  OAVoiceCommandPending.h
//  OsmAnd
//
//  Created by Alexey Kulish on 25/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#define ROUTE_CALCULATED 1
#define ROUTE_RECALCULATED 2

@class OACommandBuilder;

@interface OAVoiceCommandPending : NSObject

- (void) play:(OACommandBuilder *)command;

@end
