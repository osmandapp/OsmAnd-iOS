//
//  OAWaypointUIHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 10/04/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OALocationPointWrapper, OAWaypointSelectionDialog;

@protocol OAWaypointSelectionDialogDelegate

@required
- (void) waypointSelectionDialogComplete:(OAWaypointSelectionDialog *)dialog selectionDone:(BOOL)selectionDone showMap:(BOOL)showMap calculatingRoute:(BOOL)calculatingRoute;

@end

@interface OAWaypointSelectionDialog : NSObject

@property (nonatomic, weak) id<OAWaypointSelectionDialogDelegate> delegate;
@property (nonatomic) id param;

- (void) selectWaypoint:(NSString *)title target:(BOOL)target intermediate:(BOOL)intermediate;

@end

@interface OAWaypointUIHelper : NSObject

+ (void) showOnMap:(OALocationPointWrapper *)p;

+ (void) sortAllTargets:(void (^)(void))onComplete;
+ (void) switchStartAndFinish:(void (^)(void))onComplete;

@end
