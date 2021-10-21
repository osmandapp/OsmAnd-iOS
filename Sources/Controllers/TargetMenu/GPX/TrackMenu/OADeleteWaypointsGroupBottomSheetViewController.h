//
//  OADeleteWaypointsGroupBottomSheetViewController.h
//  OsmAnd
//
//  Created by Skalii on 20.10.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABaseBottomSheetViewController.h"

@protocol OATrackMenuViewControllerDelegate;

@interface OADeleteWaypointsGroupBottomSheetViewController : OABaseBottomSheetViewController

- (instancetype)initWithGroupName:(NSString *)groupName;

@property (weak, nonatomic) id<OATrackMenuViewControllerDelegate> trackMenuDelegate;

@end
