//
//  OATrackMenuHudViewController.mm
//  OsmAnd
//
//  Created by Skalii on 10.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OATrackMenuHudViewController.h"
#import "OATrackMenuHeaderView.h"
#import "OASaveTrackViewController.h"
#import "OATrackSegmentsViewController.h"
#import "OATrackMenuDescriptionViewController.h"
#import "OASelectTrackFolderViewController.h"
#import "OARoutePlanningHudViewController.h"
#import "OADeleteWaypointsViewController.h"
#import "OAEditWaypointsGroupBottomSheetViewController.h"
#import "OADeleteWaypointsGroupBottomSheetViewController.h"
#import "OARouteBaseViewController.h"
#import "OATabBar.h"
#import "OAIconTitleValueCell.h"
#import "OATextViewSimpleCell.h"
#import "OATextLineViewCell.h"
#import "OATitleIconRoundCell.h"
#import "OATitleDescriptionIconRoundCell.h"
#import "OATitleSwitchRoundCell.h"
#import "OAPointWithRegionTableViewCell.h"
#import "OASelectionCollapsableCell.h"
#import "OALineChartCell.h"
#import "OASegmentTableViewCell.h"
#import "OAQuadItemsWithTitleDescIconCell.h"
#import "OARadiusCellEx.h"
#import "Localization.h"
#import "OAColors.h"
#import "OARoutingHelper.h"
#import "OARouteStatisticsHelper.h"
#import "OATargetPointsHelper.h"
#import "OASavingTrackHelper.h"
#import "OASelectedGPXHelper.h"
#import "OAGPXUIHelper.h"
#import "OAGPXTrackAnalysis.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGPXDocument.h"
#import "OAGPXMutableDocument.h"
#import "OAMapActions.h"
#import "OARouteProvider.h"
#import "OAOsmAndFormatter.h"
#import "OAAutoObserverProxy.h"
#import "OAGpxWptItem.h"
#import "OADefaultFavorite.h"
#import "OAMapLayers.h"
#import "OATrackMenuUIBuilder.h"

#import <Charts/Charts-Swift.h>
#import "OsmAnd_Maps-Swift.h"

#define kActionsSection 4

#define kInfoCreatedOnCell 0
#define kActionMoveCell 1

@implementation OATrackMenuViewControllerState

+ (instancetype)withPinLocation:(CLLocationCoordinate2D)pinLocation
{
    OATrackMenuViewControllerState *state = [[OATrackMenuViewControllerState alloc] init];
    if (state)
    {
        state.pinLocation = pinLocation;
    }
    return state;
}

@end

@interface OATrackMenuHudViewController() <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, UITabBarDelegate, UIDocumentInteractionControllerDelegate, ChartViewDelegate, OASaveTrackViewControllerDelegate, OASegmentSelectionDelegate, OATrackMenuViewControllerDelegate, OASelectTrackFolderDelegate>

@property (weak, nonatomic) IBOutlet OATabBar *tabBarView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomSeparatorHeight;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomSeparatorTopConstraint;

@property (nonatomic) BOOL isShown;

@end

@implementation OATrackMenuHudViewController
{
    OsmAndAppInstance _app;
    OAGPXMutableDocument *_mutableDoc;
    OARouteLineChartHelper *_routeLineChartHelper;
    OATrackMenuUIBuilder *_uiBuilder;

    OAAutoObserverProxy *_locationServicesUpdateObserver;
    NSTimeInterval _lastUpdate;

    UIDocumentInteractionController *_exportController;
    OATrackMenuHeaderView *_headerView;
    OAGPXTableData *_tableData;

    NSString *_description;
    NSString *_exportFileName;
    NSString *_exportFilePath;

    EOATrackMenuHudTab _selectedTab;
    OATrackMenuViewControllerState *_reopeningState;

    NSDictionary<NSString *, NSArray<OAGpxWptItem *> *> *_waypointGroups;
    NSMutableDictionary<NSString *, NSString *> *_waypointGroupsOldNewNames;
    NSArray<OAGpxTrkSeg *> *_segments;
}

@dynamic isShown;

- (instancetype)initWithGpx:(OAGPX *)gpx
{
    self = [super initWithGpx:gpx];
    if (self)
    {
        _selectedTab = EOATrackMenuHudOverviewTab;
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithGpx:(OAGPX *)gpx tab:(EOATrackMenuHudTab)tab
{
    self = [super initWithGpx:gpx];
    if (self)
    {
        _selectedTab = tab >= EOATrackMenuHudOverviewTab ? tab : EOATrackMenuHudOverviewTab;
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithGpx:(OAGPX *)gpx state:(OATargetMenuViewControllerState *)state
{
    self = [super initWithGpx:gpx];
    if (self)
    {
        if ([state isKindOfClass:OATrackMenuViewControllerState.class])
        {
            _reopeningState = state;
            _selectedTab = _reopeningState.lastSelectedTab;
            [self commonInit];
        }
    }
    return self;
}

- (NSString *)getNibName
{
    return @"OATrackMenuHudViewController";
}

- (void)commonInit
{
    _app = [OsmAndApp instance];
    _routeLineChartHelper = [self getLineChartHelper];
    _uiBuilder = [[OATrackMenuUIBuilder alloc] initWithSelectedTab:_selectedTab];
    _uiBuilder.trackMenuDelegate = self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    if (!self.isShown)
        [self changeTrackVisible];

    [self startLocationServices];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {

    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        _routeLineChartHelper.isLandscape = [self isLandscape];
        _routeLineChartHelper.screenBBox = CGRectMake(
                [self isLandscape] ? [self getLandscapeViewWidth] : 0.,
                0.,
                [self isLandscape] ? DeviceScreenWidth - [self getLandscapeViewWidth] : DeviceScreenWidth,
                [self isLandscape] ? DeviceScreenHeight : DeviceScreenHeight - [self getViewHeight]);
    }];
}

- (void)hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete
{
    [super hide:YES duration:duration onComplete:^{
        [self stopLocationServices];
        [self.mapViewController.mapLayers.routeMapLayer hideCurrentStatisticsLocation];
        if (onComplete)
            onComplete();
    }];
}

- (CGFloat)initialMenuHeight
{
    CGFloat baseHeight = self.topHeaderContainerView.frame.origin.y + self.toolBarView.frame.size.height + 10.;
    CGFloat totalHeightWithoutDescription = baseHeight + _headerView.titleContainerView.frame.size.height;
    CGFloat totalHeightWithDescription = baseHeight + _headerView.descriptionContainerView.frame.origin.y
            + _headerView.descriptionContainerView.frame.size.height;

    return _headerView.descriptionContainerView.hidden ? totalHeightWithoutDescription : totalHeightWithDescription;
}

- (void)setupView
{
    [_uiBuilder setupTabBar:self.tabBarView
                parentWidth:self.scrollableView.frame.size.width];
    self.tabBarView.delegate = self;

    [self setupTableView];
}

- (void)setupTableView
{
    if (_selectedTab == EOATrackMenuHudActionsTab)
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    else
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
}

- (void)setupHeaderView
{
    if (_headerView)
        [_headerView removeFromSuperview];

    _headerView = [[OATrackMenuHeaderView alloc] init];
    _headerView.trackMenuDelegate = self;
    [_headerView setDescription];

    BOOL isOverview = _selectedTab == EOATrackMenuHudOverviewTab;
    if (isOverview)
        [_headerView generateGpxBlockStatistics:self.analysis
                                    withoutGaps:!self.gpx.joinSegments && (self.isCurrentTrack
                                            ? (self.doc.tracks.count == 0 || self.doc.tracks.firstObject.generalTrack)
                                            : (self.doc.tracks.count > 0 && self.doc.tracks.firstObject.generalTrack))];

    [_headerView updateHeader:_selectedTab
                 currentTrack:self.isCurrentTrack
                   shownTrack:self.isShown
                        title:[self.gpx getNiceTitle]];

    CGRect topHeaderContainerFrame = self.topHeaderContainerView.frame;
    topHeaderContainerFrame.size.height = _headerView.frame.size.height;
    self.topHeaderContainerView.frame = topHeaderContainerFrame;

    [self.topHeaderContainerView insertSubview:_headerView atIndex:0];
    [self.topHeaderContainerView sendSubviewToBack:_headerView];
    self.topHeaderContainerView.superview.backgroundColor =
            isOverview ? UIColor.whiteColor : UIColorFromRGB(color_bottom_sheet_background);

    [self.topHeaderContainerView addConstraints:@[
            [self createBaseEqualConstraint:_headerView
                             firstAttribute:NSLayoutAttributeLeading
                                 secondItem:self.topHeaderContainerView
                            secondAttribute:NSLayoutAttributeLeadingMargin],
            [self createBaseEqualConstraint:_headerView
                             firstAttribute:NSLayoutAttributeTop
                                 secondItem:self.topHeaderContainerView
                            secondAttribute:NSLayoutAttributeTop],
            [self createBaseEqualConstraint:_headerView
                             firstAttribute:NSLayoutAttributeTrailing
                                 secondItem:self.topHeaderContainerView
                            secondAttribute:NSLayoutAttributeTrailingMargin],
            [self createBaseEqualConstraint:_headerView
                             firstAttribute:NSLayoutAttributeBottom
                                 secondItem:self.topHeaderContainerView
                            secondAttribute:NSLayoutAttributeBottom]
            ]
    ];
}

- (void)generateData
{
    _tableData = [_uiBuilder generateSectionsData];
}

- (OAGPXTableCellData *)getCellData:(NSIndexPath *)indexPath
{
    return _tableData.sections[indexPath.section].cells[indexPath.row];
}

- (void)copyGPXToNewFolder:(NSString *)newFolderName
           renameToNewName:(NSString *)newFileName
        deleteOriginalFile:(BOOL)deleteOriginalFile
{
    NSString *oldPath = self.gpx.gpxFilePath;
    NSString *sourcePath = [_app.gpxPath stringByAppendingPathComponent:oldPath];

    NSString *newFolder = [newFolderName isEqualToString:OALocalizedString(@"tracks")] ? @"" : newFolderName;
    NSString *newFolderPath = [_app.gpxPath stringByAppendingPathComponent:newFolder];
    NSString *newName = newFileName ? [OAUtilities createNewFileName:newFileName] : self.gpx.gpxFileName;
    NSString *newStoringPath = [newFolder stringByAppendingPathComponent:newName];
    NSString *destinationPath = [newFolderPath stringByAppendingPathComponent:newName];

    [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:nil];

    OAGPXDatabase *gpxDatabase = [OAGPXDatabase sharedDb];
    if (deleteOriginalFile)
    {
        [gpxDatabase updateGPXFolderName:newStoringPath oldFilePath:oldPath];
        [gpxDatabase save];
        [[NSFileManager defaultManager] removeItemAtPath:sourcePath error:nil];

        [OASelectedGPXHelper renameVisibleTrack:oldPath newPath:newStoringPath];
    }
    else
    {
        OAGPXDocument *gpxDoc = [[OAGPXDocument alloc] initWithGpxFile:sourcePath];
        [gpxDatabase addGpxItem:[newFolder stringByAppendingPathComponent:newName]
                          title:newName
                           desc:gpxDoc.metadata.desc
                         bounds:gpxDoc.bounds
                       document:gpxDoc];

        if ([self.settings.mapSettingVisibleGpx.get containsObject:oldPath])
            [self.settings showGpx:@[newStoringPath]];
    }
}

- (void)showAlertWithText:(NSString *)text
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:text
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok")
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)renameTrack:(NSString *)newName
{
    if (newName.length > 0)
    {
        NSString *oldFilePath = self.gpx.gpxFilePath;
        NSString *oldPath = [_app.gpxPath stringByAppendingPathComponent:oldFilePath];
        NSString *newFileName = [newName stringByAppendingPathExtension:@"gpx"];
        NSString *newFilePath = [[self.gpx.gpxFilePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:newFileName];
        NSString *newPath = [_app.gpxPath stringByAppendingPathComponent:newFilePath];
        if (![NSFileManager.defaultManager fileExistsAtPath:newPath])
        {
            self.gpx.gpxTitle = newName;
            self.gpx.gpxFileName = newFileName;
            self.gpx.gpxFilePath = newFilePath;
            [[OAGPXDatabase sharedDb] save];

            OAGpxMetadata *metadata;
            if (self.doc.metadata)
            {
                metadata = (OAGpxMetadata *) self.doc.metadata;
            }
            else
            {
                metadata = [[OAGpxMetadata alloc] init];
                long time = 0;
                if (self.doc.locationMarks.count > 0)
                    time = self.doc.locationMarks[0].time;
                if (self.doc.tracks.count > 0)
                {
                    OAGpxTrk *track = self.doc.tracks[0];
                    track.name = newName;
                    if (track.segments.count > 0)
                    {
                        OAGpxTrkSeg *seg = track.segments[0];
                        if (seg.points.count > 0)
                         {
                            OAGpxTrkPt *p = seg.points[0];
                            if (time > p.time)
                                time = p.time;
                        }
                    }
                }
                metadata.time = time == 0 ? (long) [[NSDate date] timeIntervalSince1970] : time;
            }
            metadata.name = newFileName;

            if ([NSFileManager.defaultManager fileExistsAtPath:oldPath])
                [NSFileManager.defaultManager removeItemAtPath:oldPath error:nil];

            BOOL saveFailed = ![self.mapViewController updateMetadata:metadata oldPath:oldPath docPath:newPath];
            self.doc.path = newPath;
            self.doc.metadata = metadata;

            if (saveFailed)
                [self.doc saveTo:newPath];

            [OASelectedGPXHelper renameVisibleTrack:oldFilePath newPath:newFilePath];
        }
        else
        {
            [self showAlertWithText:OALocalizedString(@"gpx_already_exsists")];
        }
    }
    else
    {
        [self showAlertWithText:OALocalizedString(@"empty_filename")];
    }
}

- (OATrackMenuViewControllerState *)getCurrentState
{
    OATrackMenuViewControllerState *state = _reopeningState ? _reopeningState : [[OATrackMenuViewControllerState alloc] init];
    state.lastSelectedTab = _selectedTab;
    state.gpxFilePath = self.gpx.gpxFilePath;

    return state;
}

- (OATrackMenuViewControllerState *)getCurrentStateForAnalyze:(EOARouteStatisticsMode)routeStatistics
{
    OATrackMenuViewControllerState *state = [self getCurrentState];
    state.routeStatistics = routeStatistics;
    return state;
}

- (void)startLocationServices
{
    [self updateDistanceAndDirection:YES];
    _locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                withHandler:@selector(updateDistanceAndDirection)
                                                                 andObserve:_app.locationServices.updateObserver];
}

- (void)updateGpxData
{
    [super updateGpxData];
    [self updateSegmentsData];
    [self updateWaypointsData];
}

- (void)updateDistanceAndDirection
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateDistanceAndDirection:NO];
    });
}

- (void)updateDistanceAndDirection:(BOOL)forceUpdate
{
    if ([[NSDate date] timeIntervalSince1970] - _lastUpdate < 0.3 && !forceUpdate)
        return;

    _lastUpdate = [[NSDate date] timeIntervalSince1970];

    // Obtain fresh location and heading
    CLLocation *newLocation = _app.locationServices.lastKnownLocation;
    if (!newLocation)
        return;

    CLLocationDirection newHeading = _app.locationServices.lastKnownHeading;
    CLLocationDirection newDirection = (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0.0f)
            ? newLocation.course : newHeading;

    if (_selectedTab == EOATrackMenuHudOverviewTab)
    {
        OsmAnd::LatLon latLon(self.gpx.bounds.center.latitude, self.gpx.bounds.center.longitude);
        const auto &trackPosition31 = OsmAnd::Utilities::convertLatLonTo31(latLon);
        const auto trackLon = OsmAnd::Utilities::get31LongitudeX(trackPosition31.x);
        const auto trackLat = OsmAnd::Utilities::get31LatitudeY(trackPosition31.y);

        const auto distance = OsmAnd::Utilities::distance(
                newLocation.coordinate.longitude,
                newLocation.coordinate.latitude,
                trackLon,
                trackLat
        );
        [_headerView setDirection:[OAOsmAndFormatter getFormattedDistance:distance]];
        CGFloat itemDirection = [_app.locationServices radiusFromBearingToLocation:[
                [CLLocation alloc] initWithLatitude:trackLat longitude:trackLon]];
        _headerView.directionIconView.transform = CGAffineTransformMakeRotation(
                OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - newDirection) * (M_PI / 180));
    }
    else if (_selectedTab == EOATrackMenuHudPointsTab)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            for (OAGPXTableSectionData *sectionData in _tableData.sections)
            {
                if (sectionData.updateData)
                    sectionData.updateData();
            }
            [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows]
                                  withRowAnimation:UITableViewRowAnimationNone];
        });
    }
}

#pragma mark - OATrackMenuViewControllerDelegate

- (void)openAnalysis:(EOARouteStatisticsMode)modeType
{
    [self openAnalysis:self.analysis
              withMode:modeType];
}

- (void)openAnalysis:(OAGPXTrackAnalysis *)analysis
            withMode:(EOARouteStatisticsMode)mode
{
    [self hide:YES duration:.2 onComplete:^{
        [self.mapPanelViewController openTargetViewWithRouteDetailsGraph:self.doc
                                                                analysis:analysis
                                                        menuControlState:[self getCurrentStateForAnalyze:mode]];
    }];
}

- (NSArray<OAGpxTrkSeg *> *)updateSegmentsData
{
    _mutableDoc = [[OAGPXMutableDocument alloc] initWithGpxFile:
            [(_app ? _app : [OsmAndApp instance]).gpxPath stringByAppendingPathComponent:self.gpx.gpxFilePath]];
    _segments = [_mutableDoc && [_mutableDoc getGeneralSegment] ? @[_mutableDoc.generalSegment] : @[]
            arrayByAddingObjectsFromArray:[_mutableDoc getNonEmptyTrkSegments:NO]];
    return _segments;
}

- (void)editSegment
{
    [self hide:YES duration:.2 onComplete:^{
        [self.mapViewController hideContextPinMarker];
        [self.mapPanelViewController showPlanRouteViewController:[
                [OARoutePlanningHudViewController alloc] initWithFileName:self.gpx.gpxFilePath
                                                          targetMenuState:[self getCurrentState]]];
    }];
}

- (void)deleteAndSaveSegment:(OAGpxTrkSeg *)segment
{
    if (segment && _mutableDoc)
    {
        if (!_segments)
            [self updateGpxData];

        if (_segments)
        {
            NSInteger segmentIndex = [_segments indexOfObject:segment];
            if ([_mutableDoc removeTrackSegment:segment])
            {
                [_mutableDoc saveTo:_mutableDoc.path];
                [self updateGpxData];

                if (self.isCurrentTrack)
                    [[_app trackRecordingObservable] notifyEvent];
                else
                    [[_app updateGpxTracksOnMapObservable] notifyEvent];

                if (segmentIndex != NSNotFound)
                {
                    OAGPXTableSectionData *sectionData = _tableData.sections[segmentIndex];
                    [sectionData setData:@{ kTableValues: @{ @"delete_section_bool_value": @YES } }];
                    if (sectionData.updateData)
                        sectionData.updateData();

                    [self.tableView beginUpdates];
                    [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:segmentIndex]
                                  withRowAnimation:UITableViewRowAnimationNone];
                    [self.tableView endUpdates];
                }

                if (_headerView)
                    [_headerView setDescription];
            }
        }
    }
}

- (void)openEditSegmentScreen:(OAGpxTrkSeg *)segment
                     analysis:(OAGPXTrackAnalysis *)analysis
{
    OAEditWaypointsGroupBottomSheetViewController *editWaypointsBottomSheet =
            [[OAEditWaypointsGroupBottomSheetViewController alloc] initWithSegment:segment
                                                                          analysis:analysis];
    editWaypointsBottomSheet.trackMenuDelegate = self;
    [editWaypointsBottomSheet presentInViewController:self];
}

- (NSDictionary<NSString *, NSArray<OAGpxWptItem *> *> *)updateWaypointsData
{
    NSMutableArray<OAGpxWptItem *> *withoutGroup = [NSMutableArray array];
    NSMutableDictionary<NSString *, NSMutableArray<OAGpxWptItem *> *> *waypointGroups = [NSMutableDictionary dictionary];
    for (OAGpxWpt *gpxWpt in self.doc.locationMarks)
    {
        OAGpxWptItem *gpxWptItem = [OAGpxWptItem withGpxWpt:gpxWpt];
        if (gpxWpt.type.length == 0)
        {
            [withoutGroup addObject:gpxWptItem];
        }
        else
        {
            NSMutableArray<OAGpxWptItem *> *group = waypointGroups[gpxWpt.type];
            if (!group)
                group = [@[gpxWptItem] mutableCopy];
            else
                [group addObject:gpxWptItem];

            waypointGroups[gpxWpt.type] = group;
        }
    }

    if (withoutGroup.count > 0)
        waypointGroups[OALocalizedString(@"shared_string_gpx_points")] = withoutGroup;

    return _waypointGroups = waypointGroups;
}

- (void)refreshWaypoints
{
    [self updateGpxData];
    if (_tableData.updateData)
        _tableData.updateData();

    [self.tableView reloadData];

    if (_headerView)
        [_headerView setDescription];
}

- (void)refreshLocationServices
{
    if (_selectedTab == EOATrackMenuHudPointsTab)
    {
        if (_waypointGroups.allKeys.count > 0)
            [self startLocationServices];
        else
            [self stopLocationServices];
    }
}

- (NSInteger)getWaypointsCount:(NSString *)groupName
{
    NSArray<OAGpxWptItem *> *waypoints = _waypointGroups[groupName];
    return waypoints ? (long) waypoints.count : 0;
}

- (NSInteger)getWaypointsGroupColor:(NSString *)groupName
{
    UIColor *groupColor;
    if (groupName && groupName.length > 0 && [self getWaypointsCount:groupName] > 0)
    {
        OAGpxWptItem *waypoint = _waypointGroups[groupName].firstObject;
        groupColor = waypoint.color ? waypoint.color
                : waypoint.point.color ? [UIColor colorFromString:waypoint.point.color] : nil;
    }
    if (!groupColor)
        groupColor = [OADefaultFavorite getDefaultColor];

    return [OAUtilities colorToNumber:groupColor];
}

- (BOOL)isWaypointsGroupVisible:(NSString *)groupName
{
    return ![self.gpx.hiddenGroups containsObject:groupName];
}

- (void)setWaypointsGroupVisible:(NSString *)groupName show:(BOOL)show
{
    if (show)
        [self.gpx removeHiddenGroups:groupName];
    else
        [self.gpx addHiddenGroups:groupName];
    [[OAGPXDatabase sharedDb] save];

    groupName = [self checkGroupName:groupName];
    NSInteger groupIndex = [_waypointGroups.allKeys indexOfObject:groupName];
    OAGPXTableSectionData *groupSection = _tableData.sections[groupIndex];
    if (groupSection.updateData)
        groupSection.updateData();
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:groupIndex]]
                          withRowAnimation:UITableViewRowAnimationNone];

    if (self.isCurrentTrack)
        [[_app trackRecordingObservable] notifyEvent];
    else
        [[_app updateGpxTracksOnMapObservable] notifyEvent];
}

- (void)deleteWaypointsGroup:(NSString *)groupName
           selectedWaypoints:(NSArray<OAGpxWptItem *> *)selectedWaypoints
{
    OASavingTrackHelper *savingHelper = [OASavingTrackHelper sharedInstance];
    if (self.isCurrentTrack)
    {
        NSArray<OAGpxWptItem *> *waypoints = selectedWaypoints ? selectedWaypoints : _waypointGroups[groupName];
        for (OAGpxWptItem *waypoint in waypoints)
        {
            [savingHelper deleteWpt:waypoint.point];
        }
        [[_app trackRecordingObservable] notifyEvent];
    }
    else
    {
        NSString *path = [_app.gpxPath stringByAppendingPathComponent:self.gpx.gpxFilePath];
        NSArray<OAGpxWptItem *> *waypoints = selectedWaypoints ? selectedWaypoints : _waypointGroups[groupName];
        [self.mapViewController deleteWpts:waypoints docPath:path];
    }
}

- (void)changeWaypointsGroup:(NSString *)groupName
                newGroupName:(NSString *)newGroupName
               newGroupColor:(UIColor *)newGroupColor
{
    NSArray<OAGpxWptItem *> *waypoints = _waypointGroups[groupName];
    NSInteger groupIndex = [_waypointGroups.allKeys indexOfObject:groupName];
    NSInteger existGroupIndex = newGroupName ? [_waypointGroups.allKeys indexOfObject:newGroupName] : -1;
    if (newGroupName)
    {
        if (!_waypointGroupsOldNewNames)
            _waypointGroupsOldNewNames = [NSMutableDictionary dictionary];

        _waypointGroupsOldNewNames[groupName] = newGroupName;
    }
    for (OAGpxWptItem *gpxWptItem in waypoints)
    {
        if (newGroupName)
            gpxWptItem.point.type = newGroupName;

        if (newGroupColor)
            gpxWptItem.color = newGroupColor;

        if (self.isCurrentTrack)
        {
            [OAGPXDocument fillWpt:gpxWptItem.point.wpt usingWpt:gpxWptItem.point];
            [self.savingHelper saveWpt:gpxWptItem.point];
        }
    }

    if (!self.isCurrentTrack)
    {
        NSString *path = [_app.gpxPath stringByAppendingPathComponent:self.gpx.gpxFilePath];
        [self.mapViewController updateWpts:waypoints docPath:path updateMap:NO];
        [[_app updateGpxTracksOnMapObservable] notifyEvent];
    }
    else if (newGroupColor)
    {
        [[_app trackRecordingObservable] notifyEvent];
    }

    if (existGroupIndex != NSNotFound && existGroupIndex > 0 && existGroupIndex != groupIndex)
    {
        OAGPXTableSectionData *sectionToDelete = _tableData.sections[existGroupIndex];
        [sectionToDelete setData:@{ kTableValues: @{@"is_duplicate_bool_value": @YES } }];
    }
    [self refreshWaypoints];
}

- (NSDictionary *)updateGroupName:(NSString *)currentGroupName
                     oldGroupName:(NSString *)oldGroupName
{
    NSMutableDictionary *newGroupData = [NSMutableDictionary dictionary];
    if (_waypointGroupsOldNewNames && [_waypointGroupsOldNewNames.allKeys containsObject:currentGroupName])
    {
        newGroupData[@"current_group_name"] = _waypointGroupsOldNewNames[currentGroupName];
        [_waypointGroupsOldNewNames removeObjectForKey:oldGroupName];
        newGroupData[@"updated"] = @(YES);
    }
    else
    {
        newGroupData[@"updated"] = @(NO);
    }

    return newGroupData;
}

- (void)openConfirmDeleteWaypointsScreen:(NSString *)groupName
{
    OADeleteWaypointsGroupBottomSheetViewController *deleteWaypointsGroupBottomSheet =
            [[OADeleteWaypointsGroupBottomSheetViewController alloc] initWithGroupName:groupName];
    deleteWaypointsGroupBottomSheet.trackMenuDelegate = self;
    [deleteWaypointsGroupBottomSheet presentInViewController:self];
}

- (void)openDeleteWaypointsScreen:(NSArray *)sectionsData
                   waypointGroups:(NSDictionary *)waypointGroups
{
    OADeleteWaypointsViewController *deleteWaypointsViewController =
            [[OADeleteWaypointsViewController alloc] initWithSectionsData:sectionsData
                                                           waypointGroups:waypointGroups
                                                           isCurrentTrack:self.isCurrentTrack
                                                              gpxFilePath:self.gpx.gpxFilePath];
    deleteWaypointsViewController.trackMenuDelegate = self;
    [self presentViewController:deleteWaypointsViewController animated:YES completion:nil];
}

- (void)openWaypointsGroupOptionsScreen:(NSString *)groupName
{
    [self stopLocationServices];

    OAEditWaypointsGroupBottomSheetViewController *editWaypointsBottomSheet =
            [[OAEditWaypointsGroupBottomSheetViewController alloc] initWithWaypointsGroupName:groupName];
    editWaypointsBottomSheet.trackMenuDelegate = self;
    [editWaypointsBottomSheet presentInViewController:self];
}

- (void)openNewWaypointScreen
{
    [self hide:YES duration:.2 onComplete:^{
        [self.mapPanelViewController openTargetViewWithNewGpxWptMovableTarget:self.gpx
                                                             menuControlState:[self getCurrentState]];
    }];
}

- (NSString *)checkGroupName:(NSString *)groupName
{
    return !groupName || groupName.length == 0 ? OALocalizedString(@"shared_string_gpx_points") : groupName;
}

- (BOOL)isDefaultGroup:(NSString *)groupName
{
    return [groupName isEqualToString:OALocalizedString(@"shared_string_gpx_points")];
}

- (OARouteLineChartHelper *)getLineChartHelper
{
    if (!_routeLineChartHelper)
    {
        _routeLineChartHelper = [[OARouteLineChartHelper alloc] initWithGpxDoc:self.doc
                                                               centerMapOnBBox:^(OABBox rect) {
            [self.mapPanelViewController displayAreaOnMap:CLLocationCoordinate2DMake(rect.top, rect.left)
                                              bottomRight:CLLocationCoordinate2DMake(rect.bottom, rect.right)
                                                     zoom:0
                                              bottomInset:([self isLandscape] ? 0. : [self getViewHeight])
                                                leftInset:([self isLandscape] ? [self getLandscapeViewWidth] : 0.)
                                                 animated:YES];
                                                               }
                                                                adjustViewPort:^() {
                                                                    [self adjustMapViewPort];
                                                                }];
        _routeLineChartHelper.isLandscape = [self isLandscape];
        _routeLineChartHelper.screenBBox = CGRectMake(
                [self isLandscape] ? [self getLandscapeViewWidth] : 0.,
                0.,
                [self isLandscape] ? DeviceScreenWidth - [self getLandscapeViewWidth] : DeviceScreenWidth,
                [self isLandscape] ? DeviceScreenHeight : DeviceScreenHeight - [self getViewHeight]);
    }
    return _routeLineChartHelper;
}

- (OAGpxTrk *)getTrack:(OAGpxTrkSeg *)segment
{
    for (OAGpxTrk *trk in _mutableDoc.tracks)
    {
        if ([trk.segments containsObject:segment])
            return trk;
    }
    return nil;
}

- (NSString *)getDirName
{
    return [[OAGPXDatabase sharedDb] getFileDir:self.gpx.gpxFilePath].capitalizedString;
}

- (NSString *)getGpxFileSize
{
    NSDictionary *fileAttributes = [NSFileManager.defaultManager attributesOfItemAtPath:self.isCurrentTrack
            ? self.gpx.gpxFilePath : self.doc.path error:nil];
    return [NSByteCountFormatter stringFromByteCount:fileAttributes.fileSize
                                          countStyle:NSByteCountFormatterCountStyleFile];
}

- (NSString *)getCreatedOn
{
    return self.doc.metadata.time > 0 ? [NSDateFormatter localizedStringFromDate:
                    [NSDate dateWithTimeIntervalSince1970:self.doc.metadata.time]
                                                                       dateStyle:NSDateFormatterMediumStyle
                                                                       timeStyle:NSDateFormatterNoStyle]
            : @"";
}

- (NSString *)generateDescription
{
    switch (_selectedTab)
    {
        case EOATrackMenuHudOverviewTab:
        {
            _description = self.doc.metadata.desc;
            break;
        }
        case EOATrackMenuHudSegmentsTab:
        {
            _description = [NSString stringWithFormat:@"%@: %li",
                            OALocalizedString(@"gpx_selection_segment_title"),
                                                      _mutableDoc && [_segments containsObject:_mutableDoc.generalSegment] ? _segments.count - 1 : _segments.count];
            break;
        }
        case EOATrackMenuHudPointsTab:
        {
            NSInteger groupsCount = _waypointGroups.allKeys.count;
            if ([_waypointGroups.allKeys containsObject:OALocalizedString(@"shared_string_gpx_points")])
                groupsCount--;

            _description = [NSString stringWithFormat:@"%@: %li", OALocalizedString(@"groups"), groupsCount];
            break;
        }
        default:
        {
            _description = @"";
            break;
        }
    }
    return _description;
}

- (BOOL)changeTrackVisible
{
    if (self.isShown)
        [self.settings hideGpx:@[self.gpx.gpxFilePath] update:YES];
    else
        [self.settings showGpx:@[self.gpx.gpxFilePath] update:YES];

    return self.isShown = !self.isShown;
}

- (BOOL)isTrackVisible
{
    return self.isShown;
}

- (BOOL)currentTrack
{
    return self.isCurrentTrack;
}

- (BOOL)isJoinSegments
{
    return self.gpx.joinSegments;
}

- (CLLocationCoordinate2D)getCenterGpxLocation
{
    return self.doc.bounds.center;
}

- (void)openAppearance
{
    [self hide:YES duration:.2 onComplete:^{
        [self.mapViewController hideContextPinMarker];
        [self.mapPanelViewController openTargetViewWithGPX:self.gpx
                                              trackHudMode:EOATrackAppearanceHudMode
                                                     state:[self getCurrentState]];
    }];
}

- (void)openExport
{
    if (self.isCurrentTrack)
    {
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        [fmt setDateFormat:@"yyyy-MM-dd"];

        NSDateFormatter *simpleFormat = [[NSDateFormatter alloc] init];
        [simpleFormat setDateFormat:@"HH-mm_EEE"];

        _exportFileName = [NSString stringWithFormat:@"%@_%@",
                                                     [fmt stringFromDate:[NSDate date]],
                                                     [simpleFormat stringFromDate:[NSDate date]]];
        _exportFilePath = [NSString stringWithFormat:@"%@/%@.gpx",
                                                     NSTemporaryDirectory(),
                                                     _exportFileName];

        [self.savingHelper saveCurrentTrack:_exportFilePath];
    }
    else
    {
        _exportFileName = self.gpx.gpxFileName;
        _exportFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:self.gpx.gpxFilePath];
        [OAGPXUIHelper addAppearanceToGpx:self.doc gpxItem:self.gpx];
        [self.doc saveTo:_exportFilePath];
    }

    _exportController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:_exportFilePath]];
    _exportController.UTI = @"com.topografix.gpx";
    _exportController.delegate = self;
    _exportController.name = _exportFileName;
    [_exportController presentOptionsMenuFromRect:CGRectZero inView:self.view animated:YES];
}

- (void)openNavigation
{
    if ([self.doc getNonEmptySegmentsCount] > 1)
    {
        OATrackSegmentsViewController *trackSegmentViewController = [[OATrackSegmentsViewController alloc] initWithFile:self.doc];
        trackSegmentViewController.delegate = self;
        [self presentViewController:trackSegmentViewController animated:YES completion:nil];
    }
    else
    {
        if (![[OARoutingHelper sharedInstance] isFollowingMode])
            [self.mapPanelViewController.mapActions stopNavigationWithoutConfirm];

        [self.mapPanelViewController.mapActions enterRoutePlanningModeGivenGpx:self.gpx
                                                                          from:nil
                                                                      fromName:nil
                                                useIntermediatePointsByDefault:YES
                                                                    showDialog:YES];
        [self hide:YES duration:.2 onComplete:^{
            [self.mapViewController hideContextPinMarker];
        }];
    }
}

- (void)openDescription
{
    OATrackMenuDescriptionViewController *descriptionViewController =
            [[OATrackMenuDescriptionViewController alloc] initWithGpxDoc:self.doc gpx:self.gpx];
    [self.navigationController pushViewController:descriptionViewController animated:YES];
}

- (void)openDuplicateTrack
{
    OASaveTrackViewController *saveTrackViewController = [[OASaveTrackViewController alloc]
            initWithFileName:[self.gpx.gpxFilePath.lastPathComponent.stringByDeletingPathExtension stringByAppendingString:@"_copy"]
                    filePath:self.gpx.gpxFilePath
                   showOnMap:YES
             simplifiedTrack:NO];

    saveTrackViewController.delegate = self;
    [self presentViewController:saveTrackViewController animated:YES completion:nil];
}

- (void)openMoveTrack
{
    OASelectTrackFolderViewController *selectFolderView = [[OASelectTrackFolderViewController alloc] initWithGPX:self.gpx];
    selectFolderView.delegate = self;
    [self presentViewController:selectFolderView animated:YES completion:nil];
}

- (void)openWptOnMap:(OAGpxWptItem *)gpxWptItem
{
    [self hide:YES duration:.2 onComplete:^{
        [self.mapPanelViewController openTargetViewWithWpt:gpxWptItem pushed:NO];
    }];
}

- (void)showAlertDeleteTrack
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:self.isCurrentTrack ? OALocalizedString(@"track_clear_q") : OALocalizedString(@"gpx_remove") preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_no") style:UIAlertActionStyleDefault handler:nil]];

    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_yes") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (self.isCurrentTrack)
        {
            self.settings.mapSettingTrackRecording = NO;
            [self.savingHelper clearData];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.mapViewController hideRecGpxTrack];
            });
        }
        else
        {
            if (self.isShown)
                [self.settings hideGpx:@[self.gpx.gpxFilePath] update:YES];

            [[OAGPXDatabase sharedDb] removeGpxItem:self.gpx.gpxFilePath];
        }

        [self hide:YES duration:.2 onComplete:^{
            [self.mapViewController hideContextPinMarker];
        }];
    }]
    ];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showAlertRenameTrack
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"gpx_rename_q")
                                                                   message:OALocalizedString(@"gpx_enter_new_name \"%@\"", [self.gpx.gpxTitle lastPathComponent])
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel")
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];

    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok")
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *_Nonnull action) {
                                                [self renameTrack:alert.textFields[0].text];
                                            }]];

    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = [self.gpx.gpxTitle lastPathComponent];
    }];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)stopLocationServices
{
    if (_locationServicesUpdateObserver)
    {
        [_locationServicesUpdateObserver detach];
        _locationServicesUpdateObserver = nil;
    }
}

#pragma mark - UIDocumentInteractionControllerDelegate

- (void)documentInteractionControllerDidDismissOptionsMenu:(UIDocumentInteractionController *)controller
{
    if (controller == _exportController)
        _exportController = nil;
}

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    if (controller == _exportController)
        _exportController = nil;
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller
            didEndSendingToApplication:(NSString *)application
{
    if (self.isCurrentTrack && _exportFilePath)
    {
        [[NSFileManager defaultManager] removeItemAtPath:_exportFilePath error:nil];
        _exportFilePath = nil;
    }
}

- (void)documentInteractionController:(UIDocumentInteractionController *)controller
        willBeginSendingToApplication:(NSString *)application
{
    if ([application isEqualToString:@"net.osmand.maps"])
    {
        [_exportController dismissMenuAnimated:YES];
        _exportFilePath = nil;
        _exportController = nil;

        OASaveTrackViewController *saveTrackViewController = [[OASaveTrackViewController alloc]
                initWithFileName:self.gpx.gpxFilePath.lastPathComponent.stringByDeletingPathExtension
                        filePath:self.gpx.gpxFilePath
                       showOnMap:YES
                 simplifiedTrack:YES];

        saveTrackViewController.delegate = self;
        [self presentViewController:saveTrackViewController animated:YES completion:nil];
    }
}

#pragma mark - OASelectTrackFolderDelegate

- (void)onFolderSelected:(NSString *)selectedFolderName
{
    [self copyGPXToNewFolder:selectedFolderName renameToNewName:nil deleteOriginalFile:YES];
    if (_selectedTab == EOATrackMenuHudActionsTab)
    {
        OAGPXTableCellData *cellData = [self getCellData:[NSIndexPath indexPathForRow:kActionsSection inSection:kActionMoveCell]];
        if (cellData.updateData)
            cellData.updateData();

        [UIView setAnimationsEnabled:NO];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kActionMoveCell
                                                                    inSection:kActionsSection]]
                              withRowAnimation:UITableViewRowAnimationNone];
        [UIView setAnimationsEnabled:YES];
    }
}

- (void)onFolderAdded:(NSString *)addedFolderName
{
    NSString *newFolderPath = [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:addedFolderName];
    if (![[NSFileManager defaultManager] fileExistsAtPath:newFolderPath])
        [[NSFileManager defaultManager] createDirectoryAtPath:newFolderPath
                                  withIntermediateDirectories:NO
                                                   attributes:nil
                                                        error:nil];

    [self onFolderSelected:addedFolderName];
}

#pragma mark - OASaveTrackViewControllerDelegate

- (void)onSaveAsNewTrack:(NSString *)fileName
               showOnMap:(BOOL)showOnMap
         simplifiedTrack:(BOOL)simplifiedTrack
{
    [self copyGPXToNewFolder:fileName.stringByDeletingLastPathComponent
             renameToNewName:[fileName.lastPathComponent stringByAppendingPathExtension:@"gpx"]
          deleteOriginalFile:NO];
}

#pragma mark - OASegmentSelectionDelegate

- (void)onSegmentSelected:(NSInteger)position gpx:(OAGPXDocument *)gpx
{
    [OAAppSettings.sharedManager.gpxRouteSegment set:position];

    [self.mapPanelViewController.mapActions setGPXRouteParamsWithDocument:self.doc path:self.doc.path];
    [OARoutingHelper.sharedInstance recalculateRouteDueToSettingsChange];
    [[OATargetPointsHelper sharedInstance] updateRouteAndRefresh:YES];

    OAGPXRouteParamsBuilder *paramsBuilder = OARoutingHelper.sharedInstance.getCurrentGPXRoute;
    if (paramsBuilder)
    {
        [paramsBuilder setSelectedSegment:position];
        NSArray<CLLocation *> *ps = [paramsBuilder getPoints];
        if (ps.count > 0)
        {
            OATargetPointsHelper *tg = [OATargetPointsHelper sharedInstance];
            [tg clearStartPoint:NO];
            CLLocation *loc = ps.lastObject;
            [tg navigateToPoint:loc updateRoute:YES intermediate:-1];
        }
    }

    [self.mapPanelViewController.mapActions stopNavigationWithoutConfirm];
    [self.mapPanelViewController.mapActions enterRoutePlanningModeGivenGpx:self.doc
                                                                      path:self.gpx.gpxFilePath
                                                                      from:nil
                                                                  fromName:nil
                                            useIntermediatePointsByDefault:YES
                                                                showDialog:YES];
    [self hide:YES duration:.2 onComplete:^{
        [self.mapViewController hideContextPinMarker];
    }];
}

#pragma mark - UITabBarDelegate

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    if (_selectedTab != item.tag)
    {
        if (_selectedTab == EOATrackMenuHudSegmentsTab)
            [self.mapViewController.mapLayers.routeMapLayer hideCurrentStatisticsLocation];

        if (_selectedTab == EOATrackMenuHudOverviewTab || _selectedTab == EOATrackMenuHudPointsTab)
            [self stopLocationServices];

        _selectedTab = (EOATrackMenuHudTab) item.tag;
        [_uiBuilder updateSelectedTab:_selectedTab];

        [self setupTableView];
        [self generateData];
        [self setupHeaderView];

        switch (_selectedTab)
        {
            case EOATrackMenuHudOverviewTab:
            case EOATrackMenuHudPointsTab:
            {
                [self startLocationServices];
                break;
            }
            case EOATrackMenuHudActionsTab:
            {
                [self goFullScreen];
                break;
            }
            default:
            {
                break;
            }
        }

        if (self.currentState == EOADraggableMenuStateInitial)
            [self goExpanded];
        else
            [self updateViewAnimated];

        [UIView transitionWithView:self.tableView
                          duration:0.35f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^(void) {
                            [self.tableView reloadData];
                        }
                        completion:nil];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _tableData.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _tableData.sections[section].cells.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return _tableData.sections[section].header;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAGPXTableCellData *cellData = [self getCellData:indexPath];
    NSInteger tag = indexPath.section << 10 | indexPath.row;
    UITableViewCell *outCell = nil;
    if ([cellData.type isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAIconTitleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTitleValueCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleValueCell *) nib[0];
            [cell showLeftIcon:NO];
        }
        if (cell)
        {
            cell.separatorInset =
                    UIEdgeInsetsMake(0., _selectedTab == EOATrackMenuHudSegmentsTab ? self.tableView.frame.size.width : 20., 0., 0.);

            UIColor *tintColor = cellData.tintColor > 0 ? UIColorFromRGB(cellData.tintColor) : UIColor.blackColor;

            cell.textView.font = [cellData.values.allKeys containsObject:@"font_value"]
                    ? cellData.values[@"font_value"] : [UIFont systemFontOfSize:17.];

            cell.selectionStyle = cellData.toggle ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
            cell.textView.text = cellData.title;
            cell.textView.textColor = tintColor;
            cell.descriptionView.text = cellData.desc;

            [cell showRightIcon:cellData.rightIconName != nil];
            if (cellData.rightIconName)
            {
                cell.rightIconView.image = [UIImage templateImageNamed:cellData.rightIconName];
                cell.rightIconView.tintColor = tintColor;
            }
        }
        outCell = cell;
    }
    else if ([cellData.type isEqualToString:[OATextViewSimpleCell getCellIdentifier]])
    {
        OATextViewSimpleCell *cell = [tableView dequeueReusableCellWithIdentifier:[OATextViewSimpleCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle]loadNibNamed:[OATextViewSimpleCell getCellIdentifier] owner:self options:nil];
            cell = (OATextViewSimpleCell *) nib[0];
            cell.separatorInset = UIEdgeInsetsMake(0., 20., 0., 0.);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textView.textContainer.maximumNumberOfLines = 10;
            cell.textView.textContainer.lineBreakMode = NSLineBreakByTruncatingTail;
        }
        if (cell)
        {
            cell.textView.attributedText = cellData.values[@"attr_string_value"];
            cell.textView.linkTextAttributes = @{NSForegroundColorAttributeName: UIColorFromRGB(color_primary_purple)};
            [cell.textView sizeToFit];
        }
        outCell = cell;
    }
    else if ([cellData.type isEqualToString:[OATextLineViewCell getCellIdentifier]])
    {
        OATextLineViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OATextLineViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextLineViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATextLineViewCell *) nib[0];
            cell.separatorInset = UIEdgeInsetsZero;
        }
        if (cell)
        {
            cell.textView.text = cellData.title;
            cell.textView.textColor = UIColorFromRGB(color_primary_purple);
        }
        outCell = cell;
    }
    else if ([cellData.type isEqualToString:[OATitleIconRoundCell getCellIdentifier]])
    {
        OATitleIconRoundCell *cell =
                [tableView dequeueReusableCellWithIdentifier:[OATitleIconRoundCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleIconRoundCell getCellIdentifier]
                                                         owner:self options:nil];
            cell = (OATitleIconRoundCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = UIColor.clearColor;
            cell.separatorHeightConstraint.constant = 1.0 / [UIScreen mainScreen].scale;
            cell.separatorView.backgroundColor = UIColorFromRGB(color_tint_gray);
        }
        if (cell)
        {
            cell.titleView.text = cellData.title;
            cell.textColorNormal = cellData.tintColor > 0 ? UIColorFromRGB(cellData.tintColor) : UIColor.blackColor;

            cell.iconColorNormal = cellData.tintColor > 0
                    ? UIColorFromRGB(cellData.tintColor) : UIColorFromRGB(color_primary_purple);
            cell.iconView.image = [UIImage templateImageNamed:cellData.rightIconName];

            BOOL isLast = indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1;
            [cell roundCorners:(indexPath.row == 0) bottomCorners:isLast];
            cell.separatorView.hidden = isLast;
        }
        outCell = cell;
    }
    else if ([cellData.type isEqualToString:[OATitleDescriptionIconRoundCell getCellIdentifier]])
    {
        OATitleDescriptionIconRoundCell *cell =
                [tableView dequeueReusableCellWithIdentifier:[OATitleDescriptionIconRoundCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleDescriptionIconRoundCell getCellIdentifier]
                                                         owner:self options:nil];
            cell = (OATitleDescriptionIconRoundCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = UIColor.clearColor;
            cell.textColorNormal = UIColor.blackColor;
            cell.iconColorNormal = UIColorFromRGB(color_primary_purple);
        }
        if (cell)
        {
            cell.titleView.text = cellData.title;
            cell.descrView.text = cellData.desc;

            cell.iconView.image = [UIImage templateImageNamed:cellData.rightIconName];

            BOOL isLast = indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1;
            [cell roundCorners:(indexPath.row == 0) bottomCorners:isLast];
            cell.separatorView.hidden = isLast;
        }
        outCell = cell;
    }
    else if ([cellData.type isEqualToString:[OATitleSwitchRoundCell getCellIdentifier]])
    {
        OATitleSwitchRoundCell *cell = [tableView dequeueReusableCellWithIdentifier:[OATitleSwitchRoundCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleSwitchRoundCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleSwitchRoundCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = UIColor.clearColor;
            cell.textColorNormal = UIColor.blackColor;
            cell.separatorHeightConstraint.constant = 1.0 / [UIScreen mainScreen].scale;
            cell.separatorView.backgroundColor = UIColorFromRGB(color_tint_gray);
        }
        if (cell)
        {
            cell.titleView.text = cellData.title;

            BOOL isLast = indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1;
            [cell roundCorners:(indexPath.row == 0) bottomCorners:isLast];
            cell.separatorView.hidden = isLast;

            cell.switchView.on = cellData.isOn ? cellData.isOn() : NO;

            cell.switchView.tag = tag;
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(onSwitchPressed:) forControlEvents:UIControlEventValueChanged];
        }
        outCell = cell;
    }
    else if ([cellData.type isEqualToString:[OAPointWithRegionTableViewCell getCellIdentifier]])
    {
        OAPointWithRegionTableViewCell *cell =
                [self.tableView dequeueReusableCellWithIdentifier:[OAPointWithRegionTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAPointWithRegionTableViewCell getCellIdentifier]
                                                         owner:self
                                                       options:nil];
            cell = (OAPointWithRegionTableViewCell *) nib[0];
            cell.separatorInset = UIEdgeInsetsMake(0., 66., 0., 0.);
        }
        if (cell)
        {
            [cell.titleView setText:cellData.title];
            [cell.iconView setImage:cellData.leftIcon];
            [cell setRegion:cellData.desc];
            [cell setDirection:cellData.values[@"string_value_distance"]];

            cell.directionIconView.transform =
                    CGAffineTransformMakeRotation([cellData.values[@"float_value_direction"] floatValue]);
            if (![cell.directionIconView.tintColor isEqual:UIColorFromRGB(color_active_light)])
            {
                cell.directionIconView.image = [UIImage templateImageNamed:@"ic_small_direction"];
                cell.directionIconView.tintColor = UIColorFromRGB(color_active_light);
            }
        }
        outCell = cell;
    }
    else if ([cellData.type isEqualToString:[OASelectionCollapsableCell getCellIdentifier]])
    {
        OASelectionCollapsableCell *cell =
                [self.tableView dequeueReusableCellWithIdentifier:[OASelectionCollapsableCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASelectionCollapsableCell getCellIdentifier]
                                                         owner:self
                                                       options:nil];
            cell = (OASelectionCollapsableCell *) nib[0];
            cell.separatorInset = UIEdgeInsetsZero;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell showOptionsButton:YES];
            [cell makeSelectable:NO];
        }
        if (cell)
        {
            [cell.titleView setText:cellData.title];

            [cell.leftIconView setImage:cellData.leftIcon];
            cell.leftIconView.tintColor = UIColorFromRGB(cellData.tintColor);

            [cell.optionsButton.imageView setImage:[UIImage templateImageNamed:@"ic_custom_overflow_menu"]];
            cell.optionsButton.tintColor = UIColorFromRGB(color_primary_purple);

            cell.arrowIconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.arrowIconView.image = [UIImage templateImageNamed:cellData.rightIconName];
            if (!cellData.toggle && [cell isDirectionRTL])
                cell.arrowIconView.image = cell.arrowIconView.image.imageFlippedForRightToLeftLayoutDirection;

            [cell.openCloseGroupButton removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
            cell.openCloseGroupButton.tag = tag;
            [cell.openCloseGroupButton addTarget:self action:@selector(openCloseGroupButtonAction:) forControlEvents:UIControlEventTouchUpInside];

            cell.optionsButton.tag = tag;
            [cell.optionsButton removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
            [cell.optionsButton addTarget:self
                                   action:@selector(cellButtonPressed:)
                         forControlEvents:UIControlEventTouchUpInside];
            cell.optionsGroupButton.tag = tag;
            [cell.optionsGroupButton removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
            [cell.optionsGroupButton addTarget:self
                                        action:@selector(cellButtonPressed:)
                              forControlEvents:UIControlEventTouchUpInside];
        }
        outCell = cell;
    }
    else if ([cellData.type isEqualToString:[OASegmentTableViewCell getCellIdentifier]])
    {
        OASegmentTableViewCell *cell =
                [tableView dequeueReusableCellWithIdentifier:[OASegmentTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASegmentTableViewCell getCellIdentifier]
                                                         owner:self
                                                       options:nil];
            cell = (OASegmentTableViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsMake(0, CGFLOAT_MAX, 0, 0);
        }
        if (cell)
        {
            NSInteger segmentsCount = cell.segmentControl.numberOfSegments;
            if ([cellData.values.allKeys containsObject:@"tab_2_string_value"] && segmentsCount < 3)
                [cell.segmentControl insertSegmentWithTitle:cellData.values[@"tab_2_string_value"] atIndex:2 animated:NO];

            [cell.segmentControl setTitle:cellData.values[@"tab_0_string_value"] forSegmentAtIndex:0];
            [cell.segmentControl setTitle:cellData.values[@"tab_1_string_value"] forSegmentAtIndex:1];
            cell.segmentControl.tag = tag;
            [cell.segmentControl removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.segmentControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
            cell.segmentControl.selectedSegmentIndex = [cellData.values[@"selected_index_int_value"] intValue];
        }
        return cell;
    }
    else if ([cellData.type isEqualToString:[OALineChartCell getCellIdentifier]])
    {
        return cellData.values[@"cell_value"];
    }
    else if ([cellData.type isEqualToString:[OARadiusCellEx getCellIdentifier]])
    {
        OARadiusCellEx *cell = [tableView dequeueReusableCellWithIdentifier:[OARadiusCellEx getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARadiusCellEx getCellIdentifier] owner:self options:nil];
            cell = (OARadiusCellEx *) nib[0];
            cell.buttonRight.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
            cell.buttonRight.titleEdgeInsets = UIEdgeInsetsMake(0., 0., 0., 30.);
            cell.buttonRight.imageEdgeInsets = UIEdgeInsetsMake(0., cell.buttonRight.frame.size.width + 19., 0., -21.);
            cell.buttonRight.imageView.layer.cornerRadius = 12;
            cell.buttonRight.imageView.backgroundColor = [UIColorFromRGB(color_primary_purple) colorWithAlphaComponent:0.1];
            cell.buttonRight.tintColor = UIColorFromRGB(color_primary_purple);
            [cell.buttonRight setTitleColor:UIColorFromRGB(color_primary_purple) forState:UIControlStateNormal];
            [cell.buttonLeft setTitleColor:UIColorFromRGB(color_primary_purple) forState:UIControlStateNormal];
        }
        if (cell)
        {
            [cell.buttonLeft setTitle:cellData.values[@"left_title_string_value"] forState:UIControlStateNormal];

            UIImage *rightIcon = [UIImage templateImageNamed:cellData.values[@"right_icon_string_value"]];

            cell.buttonLeft.tag = tag;
            [cell.buttonLeft removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
            [cell.buttonLeft addTarget:self
                                action:@selector(cellButtonPressed:)
                      forControlEvents:UIControlEventTouchUpInside];

            [cell showButtonRight:cellData.toggle];
            if (cellData.toggle)
            {
                [cell.buttonRight setImage:[OAUtilities resizeImage:rightIcon newSize:CGSizeMake(24., 24.)] forState:UIControlStateNormal];
                [cell.buttonRight setTitle:cellData.values[@"right_title_string_value"] forState:UIControlStateNormal];
                cell.buttonRight.tag = tag;
                [cell.buttonRight removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
                [cell.buttonRight addTarget:self
                                     action:@selector(cellButtonPressed:)
                           forControlEvents:UIControlEventTouchUpInside];
            }
        }
        outCell = cell;
    }
    else if ([cellData.type isEqualToString:[OAQuadItemsWithTitleDescIconCell getCellIdentifier]])
    {
        OAQuadItemsWithTitleDescIconCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAQuadItemsWithTitleDescIconCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAQuadItemsWithTitleDescIconCell getCellIdentifier] owner:self options:nil];
            cell = (OAQuadItemsWithTitleDescIconCell *) nib[0];
            cell.separatorInset = UIEdgeInsetsZero;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;

            UIColor *tintColor = UIColorFromRGB(color_icon_inactive);
            cell.topLeftIcon.tintColor = tintColor;
            cell.topRightIcon.tintColor = tintColor;
            cell.bottomLeftIcon.tintColor = tintColor;
            cell.bottomRightIcon.tintColor = tintColor;
        }
        if (cell)
        {
            NSDictionary *titles = cellData.values[@"titles"];
            NSDictionary *icons = cellData.values[@"icons"];
            NSDictionary *descriptions = cellData.values[@"descriptions"];

            cell.topLeftTitle.text = titles[@"top_left_title_string_value"];
            cell.topRightTitle.text = titles[@"top_right_title_string_value"];
            cell.bottomLeftTitle.text = titles[@"bottom_left_title_string_value"];
            cell.bottomRightTitle.text = titles[@"bottom_right_title_string_value"];

            cell.topLeftIcon.image = [UIImage templateImageNamed:icons[@"top_left_icon_name_string_value"]];
            cell.topRightIcon.image = [UIImage templateImageNamed:icons[@"top_right_icon_name_string_value"]];
            cell.bottomLeftIcon.image = [UIImage templateImageNamed:icons[@"bottom_left_icon_name_string_value"]];
            cell.bottomRightIcon.image = [UIImage templateImageNamed:icons[@"bottom_right_icon_name_string_value"]];

            cell.topLeftDescription.text = descriptions[@"top_left_description_string_value"];
            cell.topRightDescription.text = descriptions[@"top_right_description_string_value"];
            cell.bottomLeftDescription.text = descriptions[@"bottom_left_description_string_value"];
            cell.bottomRightDescription.text = descriptions[@"bottom_right_description_string_value"];

            [cell showBottomButtons:cellData.toggle];
        }
        outCell = cell;
    }

    if ([outCell needsUpdateConstraints])
        [outCell updateConstraints];

    return outCell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAGPXTableCellData *cellData = [self getCellData:indexPath];
    if ([cellData.type isEqualToString:[OATextLineViewCell getCellIdentifier]]
            || [cellData.type isEqualToString:[OATitleIconRoundCell getCellIdentifier]]
            || [cellData.type isEqualToString:[OARadiusCellEx getCellIdentifier]])
        return 48.;
    else if ([cellData.type isEqualToString:[OAQuadItemsWithTitleDescIconCell getCellIdentifier]])
        return cellData.toggle ? 136. : 69.;

    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    OAGPXTableSectionData *sectionData = _tableData.sections[section];
    return sectionData.headerHeight > 0 ? sectionData.headerHeight : 0.01;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAGPXTableCellData *cellData = [self getCellData:indexPath];

    if (cellData.onButtonPressed)
        cellData.onButtonPressed();

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Selectors

- (void)onSwitchPressed:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:switchView.tag & 0x3FF inSection:switchView.tag >> 10];
    OAGPXTableCellData *cellData = [self getCellData:indexPath];

    if (cellData.onSwitch)
        cellData.onSwitch(switchView.isOn);

    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)openCloseGroupButtonAction:(id)sender
{
    UIButton *button = (UIButton *)sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag & 0x3FF inSection:button.tag >> 10];
    OAGPXTableCellData *cellData = [self getCellData:indexPath];
    [cellData setData:@{
            kCellToggle: @(!cellData.toggle)
    }];
    if (_tableData.sections[indexPath.section].updateData)
        _tableData.sections[indexPath.section].updateData();

    [self.tableView beginUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]
                  withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

- (void)cellButtonPressed:(id)sender
{
    UIButton *button = (UIButton *) sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag & 0x3FF inSection:button.tag >> 10];
    OAGPXTableCellData *cellData = [self getCellData:indexPath];

    if (cellData.onButtonPressed)
        cellData.onButtonPressed();
    else
    {
        for (UIGestureRecognizer *recognizer in self.tableView.gestureRecognizers)
        {
            if ([recognizer isKindOfClass:UIPanGestureRecognizer.class])
            {
                BOOL isLeftButton = [recognizer locationInView:self.view].x < self.tableView.frame.size.width / 2;

                if (isLeftButton && cellData.values[@"left_on_button_pressed"])
                    ((OAGPXTableDataUpdateData) cellData.values[@"left_on_button_pressed"])();
                else if (!isLeftButton && cellData.values[@"right_on_button_pressed"])
                    ((OAGPXTableDataUpdateData) cellData.values[@"right_on_button_pressed"])();

                break;
            }
        }
    }
}

- (void)segmentChanged:(id)sender
{
    UISegmentedControl *segment = (UISegmentedControl *) sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:segment.tag & 0x3FF inSection:segment.tag >> 10];
    OAGPXTableCellData *cellData = [self getCellData:indexPath];

    NSMutableDictionary *values = [cellData.values mutableCopy];
    values[@"selected_index_int_value"] = @(segment.selectedSegmentIndex);
    [cellData setData:@{ kTableValues: values }];

    if (cellData.updateData)
        cellData.updateData();

    [self.tableView reloadRowsAtIndexPaths:@[
            [NSIndexPath indexPathForRow:[cellData.values[@"row_to_update_int_value"] intValue]
                               inSection:indexPath.section]]
                          withRowAnimation:UITableViewRowAnimationNone];
}

@end
