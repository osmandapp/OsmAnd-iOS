//
//  OAEditWaypointsGroupBottomSheetViewController.h
//  OsmAnd
//
//  Created by Skalii on 20.10.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABaseBottomSheetViewController.h"

@class OASTrkSegment, OASGpxTrackAnalysis;

@protocol OATrackMenuViewControllerDelegate;

@interface OAEditWaypointsGroupBottomSheetViewController : OABaseBottomSheetViewController

- (instancetype)initWithWaypointsGroupName:(NSString *)groupName;
- (instancetype)initWithSegment:(OASTrkSegment *)segment analysis:(OASGpxTrackAnalysis *)analysis;

@property (weak, nonatomic) id<OATrackMenuViewControllerDelegate> trackMenuDelegate;

@end
