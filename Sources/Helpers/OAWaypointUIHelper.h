//
//  OAWaypointUIHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 10/04/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OALocationPointWrapper, OAWaypointSelectionDialog;

@protocol OAWaypointSelectionDelegate

@required
- (void) waypointSelectionDialogComplete:(BOOL)selectionDone showMap:(BOOL)showMap calculatingRoute:(BOOL)calculatingRoute;

@end

@interface OAWaypointUIHelper : NSObject

+ (void) showOnMap:(OALocationPointWrapper *)p;

+ (void) sortAllTargets:(void (^)(void))onComplete;
+ (void) switchStartAndFinish:(void (^)(void))onComplete;

@end
