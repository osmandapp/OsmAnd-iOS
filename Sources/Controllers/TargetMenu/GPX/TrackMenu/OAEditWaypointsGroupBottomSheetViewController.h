//
//  OAEditWaypointsGroupBottomSheetViewController.h
//  OsmAnd
//
//  Created by Skalii on 20.10.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABaseBottomSheetViewController.h"

@class OAGpxTrkSeg, OAGPXTrackAnalysis;

@protocol OATrackMenuViewControllerDelegate;

@interface OAEditWaypointsGroupBottomSheetViewController : OABaseBottomSheetViewController

- (instancetype)initWithWaypointsGroupName:(NSString *)groupName;
- (instancetype)initWithSegment:(OAGpxTrkSeg *)segment analysis:(OAGPXTrackAnalysis *)analysis;

@property (weak, nonatomic) id<OATrackMenuViewControllerDelegate> trackMenuDelegate;

@end
