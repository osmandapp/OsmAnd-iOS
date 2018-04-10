//
//  OAWaypointUIHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 10/04/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OALocationPointWrapper;

@interface OAWaypointUIHelper : NSObject

+ (void) showOnMap:(OALocationPointWrapper *)p;

+ (void) sortAllTargets:(void (^)(void))onComplete;

@end
