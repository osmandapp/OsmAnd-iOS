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

@class OAGpxTrk, OAGpxTrkSeg, OARouteLineChartHelper;

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
- (void)openAnalysis:(OAGPXTrackAnalysis *)analysis
            withMode:(EOARouteStatisticsMode)mode;

- (NSArray<OAGpxTrkSeg *> *)updateSegmentsData;
- (void)editSegment;
- (void)deleteAndSaveSegment:(OAGpxTrkSeg *)segment;
- (void)openEditSegmentScreen:(OAGpxTrkSeg *)segment
                     analysis:(OAGPXTrackAnalysis *)analysis;

- (NSDictionary<NSString *, NSArray<OAGpxWptItem *> *> *)updateWaypointsData;
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
- (NSDictionary *)updateGroupName:(NSString *)currentGroupName
                     oldGroupName:(NSString *)oldGroupName;
- (void)openConfirmDeleteWaypointsScreen:(NSString *)groupName;
- (void)openDeleteWaypointsScreen:(NSArray *)sectionsData
                   waypointGroups:(NSDictionary *)waypointGroups;
- (void)openWaypointsGroupOptionsScreen:(NSString *)groupName;
- (void)openNewWaypointScreen;
- (NSString *)checkGroupName:(NSString *)groupName;
- (BOOL)isDefaultGroup:(NSString *)groupName;

- (OARouteLineChartHelper *)getLineChartHelper;
- (OAGpxTrk *)getTrack:(OAGpxTrkSeg *)segment;
- (NSString *)getDirName;
- (NSString *)getGpxFileSize;
- (NSString *)getCreatedOn;
- (NSString *)generateDescription;
- (BOOL)changeTrackVisible;
- (BOOL)isTrackVisible;
- (BOOL)currentTrack;
- (BOOL)isJoinSegments;
- (CLLocationCoordinate2D)getCenterGpxLocation;
- (void)openAppearance;
- (void)openExport;
- (void)openNavigation;
- (void)openDescription;
- (void)openDuplicateTrack;
- (void)openMoveTrack;
- (void)openWptOnMap:(OAGpxWptItem *)gpxWptItem;
- (void)showAlertDeleteTrack;
- (void)showAlertRenameTrack;

- (void)stopLocationServices;

@end

@interface OATrackMenuViewControllerState : OATargetMenuViewControllerState

+ (instancetype)withPinLocation:(CLLocationCoordinate2D)pinLocation;

@property (nonatomic, assign) EOATrackMenuHudTab lastSelectedTab;
@property (nonatomic, assign) EOARouteStatisticsMode routeStatistics;
@property (nonatomic, assign) NSString *gpxFilePath;
@property (nonatomic, assign) CLLocationCoordinate2D pinLocation;

@end

@interface OATrackMenuHudViewController : OABaseTrackMenuHudViewController

- (instancetype)initWithGpx:(OAGPX *)gpx tab:(EOATrackMenuHudTab)tab;
- (instancetype)initWithGpx:(OAGPX *)gpx state:(OATargetMenuViewControllerState *)state;

@end
