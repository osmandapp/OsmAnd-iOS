//
//  OADeleteWaypointsViewController.h
//  OsmAnd
//
//  Created by Skalii on 13.10.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABaseButtonsViewController.h"

@class OAGPXTableData;

@protocol OATrackMenuViewControllerDelegate;

@interface OADeleteWaypointsViewController : OABaseButtonsViewController

- (instancetype)initWithSectionsData:(OAGPXTableData *)tableData;

@property (nonatomic, weak) id<OATrackMenuViewControllerDelegate> trackMenuDelegate;

@end
