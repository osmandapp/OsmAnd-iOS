//
//  OATrackMenuHudViewController.h
//  OsmAnd
//
//  Created by Skalii on 10.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABaseTrackMenuHudViewController.h"
#import "OAStatisticsSelectionBottomSheetViewController.h"
#import "OAMapPanelViewController.h"

typedef NS_ENUM(NSUInteger, EOATrackMenuHudTab)
{
    EOATrackMenuHudOverviewTab = 0,
    EOATrackMenuHudPointsTab,
    EOATrackMenuHudActionsTab
};

@protocol OATrackMenuViewControllerDelegate <NSObject>

@optional

- (void)openAnalysis:(EOARouteStatisticsMode)modeType;

@end

@interface OATrackMenuViewControllerState : OATargetMenuViewControllerState

@property (nonatomic, assign) EOATrackMenuHudTab lastSelectedTab;
@property (nonatomic, assign) EOARouteStatisticsMode routeStatistics;
@property (nonatomic, assign) NSString *gpxFilePath;

@end

@interface OATrackMenuHudViewController : OABaseTrackMenuHudViewController

- (instancetype)initWithGpx:(OAGPX *)gpx tab:(EOATrackMenuHudTab)tab;
- (instancetype)initWithGpx:(OAGPX *)gpx state:(OATargetMenuViewControllerState *)state;

@end
