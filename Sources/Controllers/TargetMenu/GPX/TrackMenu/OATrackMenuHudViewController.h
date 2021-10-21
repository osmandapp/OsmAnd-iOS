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

@required

- (void)openAnalysis:(EOARouteStatisticsMode)modeType;
- (void)refreshWaypoints:(BOOL)updateAllData;
- (NSInteger)getWaypointsCount:(NSString *)groupName;
- (NSInteger)getWaypointsGroupColor:(NSString *)groupName;
- (BOOL)isWaypointsGroupVisible:(NSString *)groupName;
- (void)setWaypointsGroupVisible:(NSString *)groupName show:(BOOL)show;
- (void)deleteWaypointsGroup:(NSString *)groupName;
- (void)openConfirmDeleteWaypointsScreen:(NSString *)groupName;
- (void)openWaypointsGroupOptionsScreen:(NSString *)groupName;

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
