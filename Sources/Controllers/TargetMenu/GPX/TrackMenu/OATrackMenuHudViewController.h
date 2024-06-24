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
#import "OATrackMenuHudViewControllerConstants.h"

@class LineChartView;
@class OATrack, OATrkSegment, OARouteLineChartHelper, OARouteKey, OAAuthor, OACopyright, OALink, OATravelArticleIdentifier;

@protocol OATrackMenuViewControllerDelegate <NSObject>

@required

- (void)openAnalysis:(NSArray<NSNumber *> *)types;
- (void)openAnalysis:(OAGPXTrackAnalysis *)analysis
            withTypes:(NSArray<NSNumber *> *)types;
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
- (OAAuthor *)getAuthor;
- (OACopyright *)getCopyright;
- (OAMetadata *)getMetadata;
- (NSString *)getKeywords;
- (NSArray<OALink *> *)getLinks;
- (NSString *)getCreatedOn;
- (NSString *)generateDescription;
- (NSString *)getMetadataImageLink;
- (BOOL)changeTrackVisible;
- (BOOL)isTrackVisible;
- (BOOL)currentTrack;
- (BOOL)isJoinSegments;
- (CLLocationCoordinate2D)getCenterGpxLocation;
- (CLLocationCoordinate2D)getPinLocation;
- (OARouteKey *)getRouteKey;
- (void)openAppearance;
- (void)openExport:(UIView *)sourceView;
- (void)openNavigation;
- (void)openDescription;
- (void)openDescriptionEditor;
- (void)openDescriptionReadOnly:(NSString *)description;
- (void)openNameTagsScreenWith:(NSArray<NSDictionary *> *)tagsArray;
- (void)openDuplicateTrack;
- (void)openMoveTrack;
- (void)openWptOnMap:(OAGpxWptItem *)gpxWptItem;
- (void)openURL:(NSString *)url sourceView:(UIView *)sourceView;
- (void)openArticleById:(OATravelArticleIdentifier *)articleId lang:(NSString *)lang;
- (void)showAlertDeleteTrack;
- (void)showAlertRenameTrack;
- (void)openUploadGpxToOSM;
- (void)saveNetworkRoute;

- (void)stopLocationServices;
- (BOOL)openedFromMap;
- (void)reloadSections:(NSIndexSet *)sections;
- (void)updateData:(OAGPXBaseTableData *)tableData;
- (void)updateProperty:(id)value tableData:(OAGPXBaseTableData *)tableData;

@end

@interface OATrackMenuViewControllerState : OATargetMenuViewControllerState

+ (instancetype)withPinLocation:(CLLocationCoordinate2D)pinLocation openedFromMap:(BOOL)openedFromMap;

@property (nonatomic, assign) EOATrackMenuHudTab lastSelectedTab;
@property (nonatomic, assign) EOATrackMenuHudSegmentsStatisticsTab selectedStatisticsTab;
@property (nonatomic, assign) NSArray<NSNumber *> *routeStatistics;
@property (nonatomic) UIImage *trackIcon;
@property (nonatomic) NSString *gpxFilePath;
@property (nonatomic, assign) CLLocationCoordinate2D pinLocation;
@property (nonatomic, assign) EOADraggableMenuState showingState;
@property (nonatomic, assign) BOOL openedFromMap;
@property (nonatomic, assign) BOOL openedFromTracksList;
@property (nonatomic, assign) BOOL openedFromTrackMenu;
@property (nonatomic, assign) NSInteger scrollToSectionIndex;


// Uses for reopening previous screens (with all NavController history) after opening track on map from MyPlaces
@property (nonatomic, nullable) NSArray<UIViewController *> *navControllerHistory;

@end

@interface OATrackMenuHudViewController : OABaseTrackMenuHudViewController

- (instancetype)initWithGpx:(OAGPX *)gpx tab:(EOATrackMenuHudTab)tab;
- (instancetype)initWithGpx:(OAGPX *)gpx routeKey:(OARouteKey *)routeKey state:(OATargetMenuViewControllerState *)state;

@end
