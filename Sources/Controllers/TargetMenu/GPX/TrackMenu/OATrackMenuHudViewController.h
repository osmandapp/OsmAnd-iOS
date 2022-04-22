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

@class LineChartView;
@class OATrack, OATrkSegment, OARouteLineChartHelper;

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

- (OAGPXTrackAnalysis *)getGeneralAnalysis;
- (OATrkSegment *)getGeneralSegment;
- (NSArray<OATrkSegment *> *)getSegments;
- (void)editSegment;
- (void)deleteAndSaveSegment:(OATrkSegment *)segment;
- (void)openEditSegmentScreen:(OATrkSegment *)segment
                     analysis:(OAGPXTrackAnalysis *)analysis;

- (void)refreshLocationServices;
- (NSMutableDictionary<NSString *, NSMutableArray<OAGpxWptItem *> *> *)getWaypointsData;
- (NSArray<NSString *> *)getWaypointSortedGroups;
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
- (void)openDeleteWaypointsScreen:(OAGPXTableData *)tableData;
- (void)openWaypointsGroupOptionsScreen:(NSString *)groupName;
- (void)openNewWaypointScreen;
- (NSString *)checkGroupName:(NSString *)groupName;
- (BOOL)isDefaultGroup:(NSString *)groupName;
- (BOOL)isRteGroup:(NSString *)groupName;

- (void)updateChartHighlightValue:(LineChartView *)chart
                          segment:(OATrkSegment *)segment;
- (OARouteLineChartHelper *)getLineChartHelper;
- (OATrack *)getTrack:(OATrkSegment *)segment;
- (NSString *)getTrackSegmentTitle:(OATrkSegment *)segment;
- (NSString *)getDirName;
- (NSString *)getGpxFileSize;
- (NSString *)getCreatedOn;
- (NSString *)generateDescription;
- (NSString *)getMetadataImageLink;
- (BOOL)changeTrackVisible;
- (BOOL)isTrackVisible;
- (BOOL)currentTrack;
- (BOOL)isJoinSegments;
- (CLLocationCoordinate2D)getCenterGpxLocation;
- (CLLocationCoordinate2D)getPinLocation;
- (void)openAppearance;
- (void)openExport;
- (void)openNavigation;
- (void)openDescription;
- (void)openDescriptionEditor;
- (void)openDuplicateTrack;
- (void)openMoveTrack;
- (void)openWptOnMap:(OAGpxWptItem *)gpxWptItem;
- (void)showAlertDeleteTrack;
- (void)showAlertRenameTrack;

- (void)stopLocationServices;
- (BOOL)openedFromMap;
- (void)reloadSections:(NSIndexSet *)sections;

@end

@interface OATrackMenuViewControllerState : OATargetMenuViewControllerState

+ (instancetype)withPinLocation:(CLLocationCoordinate2D)pinLocation openedFromMap:(BOOL)openedFromMap;

@property (nonatomic, assign) EOATrackMenuHudTab lastSelectedTab;
@property (nonatomic, assign) EOARouteStatisticsMode routeStatistics;
@property (nonatomic, assign) NSString *gpxFilePath;
@property (nonatomic, assign) CLLocationCoordinate2D pinLocation;
@property (nonatomic, assign) EOADraggableMenuState showingState;
@property (nonatomic, assign) BOOL openedFromMap;

@end

@interface OATrackMenuHudViewController : OABaseTrackMenuHudViewController

- (instancetype)initWithGpx:(OAGPX *)gpx tab:(EOATrackMenuHudTab)tab;
- (instancetype)initWithGpx:(OAGPX *)gpx state:(OATargetMenuViewControllerState *)state;

@end
