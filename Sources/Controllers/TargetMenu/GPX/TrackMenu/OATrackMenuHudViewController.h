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
    EOATrackMenuHudSegmentsTab,
    EOATrackMenuHudPointsTab,
    EOATrackMenuHudActionsTab
};

@protocol OATrackMenuViewControllerDelegate <NSObject>

@required

- (void)openAnalysis:(EOARouteStatisticsMode)modeType;
- (void)refreshWaypoints;
- (void)refreshLocationServices;
- (NSInteger)getWaypointsCount:(NSString *)groupName;
- (NSInteger)getWaypointsGroupColor:(NSString *)groupName;
- (BOOL)isWaypointsGroupVisible:(NSString *)groupName;
- (void)setWaypointsGroupVisible:(NSString *)groupName show:(BOOL)show;
- (void)deleteWaypointsGroup:(NSString *)groupName
           selectedWaypoints:(NSArray<OAGpxWptItem *> *)selectedWaypoints;
- (void)changeWaypointsGroup:(NSString *)groupName
                newGroupName:(NSString *)newGroupName
               newGroupColor:(UIColor *)newGroupColor;
- (void)openConfirmDeleteWaypointsScreen:(NSString *)groupName;
- (void)openWaypointsGroupOptionsScreen:(NSString *)groupName;
- (NSString *)checkGroupName:(NSString *)groupName;
- (BOOL)isDefaultGroup:(NSString *)groupName;

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
