//
//  OATrackMenuHudViewController.mm
//  OsmAnd
//
//  Created by Skalii on 10.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OATrackMenuHudViewController.h"
#import "OATrackMenuHeaderView.h"
#import "OAFoldersCollectionView.h"
#import "OASaveTrackViewController.h"
#import "OATrackSegmentsViewController.h"
#import "OASelectTrackFolderViewController.h"
#import "OARoutePlanningHudViewController.h"
#import "OADeleteWaypointsViewController.h"
#import "OAEditWaypointsGroupBottomSheetViewController.h"
#import "OAEditWaypointsGroupOptionsViewController.h"
#import "OADeleteWaypointsGroupBottomSheetViewController.h"
#import "OARouteBaseViewController.h"
#import "OAGPXListViewController.h"
#import "OARootViewController.h"
#import "OAMapRendererView.h"
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
#import "OATargetPointsHelper.h"
#import "OASavingTrackHelper.h"
#import "OASelectedGPXHelper.h"
#import "OAGPXUIHelper.h"
#import "OAGPXTrackAnalysis.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGPXMutableDocument.h"
#import "OAMapActions.h"
#import "OARouteProvider.h"
#import "OAOsmAndFormatter.h"
#import "OAGpxWptItem.h"
#import "OADefaultFavorite.h"
#import "OAMapLayers.h"
#import "OATrackMenuUIBuilder.h"
#import "QuadRect.h"
#import "OAImageDescTableViewCell.h"
#import "OAEditDescriptionViewController.h"
#import "OAWikiArticleHelper.h"
#import "OAMapHudViewController.h"

#import <Charts/Charts-Swift.h>
#import "OsmAnd_Maps-Swift.h"

#define kGpxDescriptionImageHeight 149

@implementation OATrackMenuViewControllerState

+ (instancetype)withPinLocation:(CLLocationCoordinate2D)pinLocation openedFromMap:(BOOL)openedFromMap
{
    OATrackMenuViewControllerState *state = [[OATrackMenuViewControllerState alloc] init];
    if (state)
    {
        state.pinLocation = pinLocation;
        state.openedFromMap = openedFromMap;
    }
    return state;
}

@end

@interface OATrackMenuHudViewController() <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, UITabBarDelegate, UIDocumentInteractionControllerDelegate, OASaveTrackViewControllerDelegate, OASegmentSelectionDelegate, OATrackMenuViewControllerDelegate, OASelectTrackFolderDelegate, OAEditWaypointsGroupOptionsDelegate, OAFoldersCellDelegate, OAEditDescriptionViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *statusBarBackgroundView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIView *groupsButtonContainerView;
@property (weak, nonatomic) IBOutlet UIButton *groupsButton;
@property (weak, nonatomic) IBOutlet UIView *contentContainer;
@property (weak, nonatomic) IBOutlet OATabBar *tabBarView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *groupsButtonTrailingConstraint;

@property (nonatomic) OAGPX *gpx;
@property (nonatomic) OAGPXTrackAnalysis *analysis;
@property (nonatomic) BOOL isShown;

@end

@implementation OATrackMenuHudViewController
{
    OsmAndAppInstance _app;
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

    NSMutableDictionary<NSString *, NSMutableArray<OAGpxWptItem *> *> *_waypointGroups;
    NSArray<NSString *> *_waypointSortedGroupNames;

    BOOL _isHeaderBlurred;
    BOOL _isTabSelecting;
    BOOL _wasFirstOpening;
    
    BOOL _isImageDownloadFinished;
    BOOL _isImageDownloadSucceed;
    UIImage *_cachedImage;
    NSString *_cachedImageURL;
    BOOL _isViewVisible;
}

@dynamic gpx, analysis, isShown, backButton, statusBarBackgroundView, contentContainer;

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

    if ([self openedFromMap])
        [self.backButton setImage:[UIImage templateImageNamed:@"ic_custom_cancel"] forState:UIControlStateNormal];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    [self startLocationServices];

    if (_reopeningState && _reopeningState.showingState != EOADraggableMenuStateInitial)
        [self updateShowingState:_reopeningState.showingState];

    UIImage *groupsImage = [UIImage templateImageNamed:@"ic_custom_folder_visible"];
    [self.groupsButton setImage:groupsImage forState:UIControlStateNormal];
    self.groupsButton.imageView.tintColor = UIColorFromRGB(color_primary_purple);
    [self.groupsButton addBlurEffect:YES cornerRadius:12. padding:0];
    BOOL isRTL = [self.groupsButton isDirectionRTL];
    self.groupsButton.titleEdgeInsets = UIEdgeInsetsMake(0., isRTL ? -4. : 0., 0., isRTL ? 0. : -4.);
    self.groupsButton.imageEdgeInsets = UIEdgeInsetsMake(0., isRTL ? 10. : -4., 0., isRTL ? -4. : 10.);
    [self updateGroupsButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _isViewVisible = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _wasFirstOpening = YES;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        if (_headerView)
        {
            _headerView.sliderView.hidden = [self isLandscape];
            [_headerView updateFrame:[self isLandscape] ? [self getLandscapeViewWidth] : DeviceScreenWidth];
        }

        if (_selectedTab == EOATrackMenuHudOverviewTab && _headerView)
        {
            _headerView.statisticsCollectionView.contentInset = UIEdgeInsetsMake(0., 20. , 0., 20.);
            NSArray<NSIndexPath *> *visibleItems = _headerView.statisticsCollectionView.indexPathsForVisibleItems;
            if (visibleItems && visibleItems.count > 0 && visibleItems.firstObject.row == 0)
            {
                [_headerView.statisticsCollectionView scrollToItemAtIndexPath:visibleItems.firstObject
                                                             atScrollPosition:UICollectionViewScrollPositionLeft
                                                                     animated:NO];
            }
        }
        if (_selectedTab == EOATrackMenuHudPointsTab && _headerView)
        {
            _headerView.groupsCollectionView.contentInset = UIEdgeInsetsMake(0., 16 , 0., 16);
            NSArray<NSIndexPath *> *visibleItems = _headerView.groupsCollectionView.indexPathsForVisibleItems;
            if (visibleItems && visibleItems.count > 0 && visibleItems.firstObject.row == 0)
            {
                [_headerView.groupsCollectionView scrollToItemAtIndexPath:visibleItems.firstObject
                                                         atScrollPosition:UICollectionViewScrollPositionLeft
                                                                 animated:NO];
            }
        }
        else if (_selectedTab == EOATrackMenuHudSegmentsTab && _tableData.subjects.count > 0)
        {
            NSMutableArray *indexPaths = [NSMutableArray array];
            for (NSInteger i = 0; i < _tableData.subjects.count; i++)
            {
                OAGPXTableSectionData *sectionData = _tableData.subjects[i];
                for (NSInteger j = 0; j < sectionData.subjects.count; j++)
                {
                    OAGPXTableCellData *cellData = sectionData.subjects[j];
                    if ([cellData.type isEqualToString:[OARadiusCellEx getCellIdentifier]])
                        [indexPaths addObject:[NSIndexPath indexPathForRow:j inSection:i]];
                }
            }
            if (indexPaths.count > 0)
                [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
        }
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        _routeLineChartHelper.isLandscape = [self isLandscape];
        _routeLineChartHelper.screenBBox = CGRectMake(
                [self isLandscape] ? [self getLandscapeViewWidth] : 0.,
                0.,
                [self isLandscape] ? DeviceScreenWidth - [self getLandscapeViewWidth] : DeviceScreenWidth,
                [self isLandscape] ? DeviceScreenHeight : DeviceScreenHeight - [self getViewHeight]);
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    _exportController = nil;
    _isViewVisible = YES;
}

- (void)hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete
{
    [super hide:YES duration:duration onComplete:^{
        [self stopLocationServices];
        [self.mapViewController.mapLayers.routeMapLayer hideCurrentStatisticsLocation];
        if (onComplete)
            onComplete();
        [_headerView removeFromSuperview];
    }];
}

- (UIView *)getCustomHeader
{
    return _headerView;
}

- (CGFloat)initialMenuHeight
{
    return [_headerView getInitialHeight:self.toolBarView.frame.size.height];
}

- (CGFloat)expandedMenuHeight
{
    if (![self isFirstStateChanged] && _selectedTab == EOATrackMenuHudOverviewTab)
        return self.toolBarView.frame.size.height + _headerView.frame.size.height - 0.5;

    return DeviceScreenHeight / 2;
}

- (BOOL)hasCustomHeaderFooter
{
    return YES;
}

- (void)setupView
{
    [_uiBuilder setupTabBar:self.tabBarView
                parentWidth:self.scrollableView.frame.size.width];
    self.tabBarView.delegate = self;
    [self.tabBarView makeTranslucent:YES];
    [self.toolBarView addBlurEffect:YES cornerRadius:0. padding:0.];

    [self setupTableView];
}

- (void)setupTableView
{
    if (_selectedTab == EOATrackMenuHudActionsTab)
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    else
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;

    if (_selectedTab == EOATrackMenuHudPointsTab)
        self.tableView.estimatedRowHeight = 66.;
    else
        self.tableView.estimatedRowHeight = 48.;
}

- (NSArray<NSDictionary *> *)generateGroupCollectionData
{
    NSMutableArray<NSDictionary *> *groupsData = [NSMutableArray array];
    for (NSString *groupName in _waypointSortedGroupNames)
    {
        [groupsData addObject:@{
                @"title": groupName.length > 5 ? [[groupName substringToIndex:5] stringByAppendingString:@"..."] : groupName,
                @"enabled": @([self isWaypointsGroupVisible:groupName])
        }];
    }
    return groupsData;
}

- (void)setupHeaderView
{
    if (_headerView)
        [_headerView removeFromSuperview];

    _headerView = [[OATrackMenuHeaderView alloc] initWithFrame:CGRectMake(
            0.,
            CGRectGetMaxY(self.statusBarBackgroundView.frame),
            [self isLandscape] ? [self getLandscapeViewWidth] : DeviceScreenWidth,
            0.
    )];
    _headerView.trackMenuDelegate = self;
    _headerView.sliderView.hidden = [self isLandscape];
    [_headerView updateSelectedTab:_selectedTab];
    [_headerView setDescription];

    if (_selectedTab == EOATrackMenuHudOverviewTab)
    {
        _headerView.statisticsCollectionView.contentInset = UIEdgeInsetsMake(0., 20., 0., 20.);
        [_headerView generateGpxBlockStatistics:self.analysis
                                    withoutGaps:!self.gpx.joinSegments && (self.isCurrentTrack
                                            ? (self.doc.tracks.count == 0 || self.doc.tracks.firstObject.generalTrack)
                                            : (self.doc.tracks.count > 0 && self.doc.tracks.firstObject.generalTrack))];
    }
    else if (_selectedTab == EOATrackMenuHudPointsTab)
    {
        _headerView.groupsCollectionView.foldersDelegate = self;
        _headerView.groupsCollectionView.contentInset = UIEdgeInsetsMake(0., 16. , 0., 16.);
        [_headerView setGroupsCollection:[self generateGroupCollectionData] withSelectedIndex:0];
    }

    [_headerView updateHeader:self.isCurrentTrack
                   shownTrack:self.isShown
                        title:[self.gpx getNiceTitle]];

    [self.scrollableView addSubview:_headerView];

    CGRect topHeaderContainerFrame = self.topHeaderContainerView.frame;
    topHeaderContainerFrame.size.height = _headerView.frame.size.height;
    self.topHeaderContainerView.frame = topHeaderContainerFrame;

    [self.scrollableView bringSubviewToFront:self.toolBarView];
    [self.scrollableView bringSubviewToFront:self.statusBarBackgroundView];
}

- (void)generateData
{
    _tableData = nil;
    _tableData = [_uiBuilder generateSectionsData];
    if (_selectedTab == EOATrackMenuHudOverviewTab)
        [self fetchDescriptionImageIfNeeded];
}

- (void)fetchDescriptionImageIfNeeded
{
    OAGPXTableSectionData *sectionData = [_tableData getSubject:@"section_description"];
    if (sectionData)
    {
        OAGPXTableCellData *cellData = [sectionData getSubject:@"image"];
        if (cellData && [cellData.type isEqualToString:[OAImageDescTableViewCell getCellIdentifier]])
        {
            NSString *url = cellData.values[@"img"];
            if (!_cachedImage || ![url isEqualToString:_cachedImageURL])
            {
                _isImageDownloadFinished = NO;
                _cachedImage = nil;
                _cachedImageURL = url;

                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString: url]];
                    UIImage *image = [UIImage imageWithData:data];
                    _isImageDownloadFinished = YES;
                    _isImageDownloadSucceed = image != nil;

                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (!_isViewVisible)
                        {
                            _cachedImage = image;
                            NSIndexPath *imageCellIndex = [NSIndexPath indexPathForRow:[sectionData.subjects indexOfObject:cellData]
                                                                             inSection:[_tableData.subjects indexOfObject:sectionData]];
                            [self.tableView reloadRowsAtIndexPaths:@[imageCellIndex]
                                                  withRowAnimation:UITableViewRowAnimationAutomatic];
                        }
                    });
                });
            }
        }
    }
}

- (BOOL)isTabSelecting
{
    return _isTabSelecting;
}

- (BOOL)adjustCentering
{
    return [self openedFromMap] && _wasFirstOpening
            || ![self openedFromMap] && _wasFirstOpening
            || ![self openedFromMap] && !_wasFirstOpening;
}

- (BOOL)stopChangingHeight:(UIView *)view
{
    return [view isKindOfClass:[LineChartView class]] || [view isKindOfClass:[UICollectionView class]];
}

- (void)doAdditionalLayout
{
    [super doAdditionalLayout];
    BOOL isRTL = [self.groupsButtonContainerView isDirectionRTL];
    self.groupsButtonTrailingConstraint.constant = [self isLandscape]
            ? (isRTL ? [self getLandscapeViewWidth] - [OAUtilities getLeftMargin] + 10. : 0.)
            : [OAUtilities getLeftMargin] + 10.;
    self.groupsButtonContainerView.hidden = ![self isLandscape] && self.currentState == EOADraggableMenuStateFullScreen;
}

- (OAGPXTableCellData *)getCellData:(NSIndexPath *)indexPath
{
    return _tableData.subjects[indexPath.section].subjects[indexPath.row];
}

- (void)copyGPXToNewFolder:(NSString *)newFolderName
           renameToNewName:(NSString *)newFileName
        deleteOriginalFile:(BOOL)deleteOriginalFile
                 openTrack:(BOOL)openTrack
{
    NSString *oldPath = self.gpx.gpxFilePath;
    NSString *sourcePath = [_app.gpxPath stringByAppendingPathComponent:oldPath];

    NSString *newFolder = [newFolderName isEqualToString:OALocalizedString(@"tracks")] ? @"" : newFolderName;
    NSString *newFolderPath = [_app.gpxPath stringByAppendingPathComponent:newFolder];
    NSString *newName = self.gpx.gpxFileName;

    if (newFileName)
    {
        if ([[NSFileManager defaultManager]
                fileExistsAtPath:[newFolderPath stringByAppendingPathComponent:newFileName]])
            newName = [OAUtilities createNewFileName:newFileName];
        else
            newName = newFileName;
    }

    NSString *newStoringPath = [newFolder stringByAppendingPathComponent:newName];
    NSString *destinationPath = [newFolderPath stringByAppendingPathComponent:newName];

    [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:nil];

    OAGPXDatabase *gpxDatabase = [OAGPXDatabase sharedDb];
    if (deleteOriginalFile)
    {
        [self.gpx updateFolderName:newStoringPath];
        self.doc.path = [[OsmAndApp instance].gpxPath stringByAppendingPathComponent:self.gpx.gpxFilePath];
        [gpxDatabase save];
        [[NSFileManager defaultManager] removeItemAtPath:sourcePath error:nil];

        [OASelectedGPXHelper renameVisibleTrack:oldPath newPath:newStoringPath];
    }
    else
    {
        OAGPXMutableDocument *gpxDoc = [[OAGPXMutableDocument alloc] initWithGpxFile:sourcePath];
        [gpxDatabase addGpxItem:[newFolder stringByAppendingPathComponent:newName]
                          title:newName
                           desc:gpxDoc.metadata.desc
                         bounds:gpxDoc.bounds
                       document:gpxDoc];

        if ([self.settings.mapSettingVisibleGpx.get containsObject:oldPath])
            [self.settings showGpx:@[newStoringPath]];
    }
    if (openTrack)
    {
        OAGPX *gpx = [[OAGPXDatabase sharedDb] getGPXItem:[newFolderName stringByAppendingPathComponent:newFileName]];
        if (gpx)
        {
            [self hide:YES duration:.2 onComplete:^{
                [self.mapViewController hideContextPinMarker];
                [self.mapPanelViewController openTargetViewWithGPX:gpx];
            }];
        }
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

            OAMetadata *metadata;
            if (self.doc.metadata)
            {
                metadata = self.doc.metadata;
            }
            else
            {
                metadata = [[OAMetadata alloc] init];
                long time = 0;
                if (self.doc.points.count > 0)
                    time = self.doc.points[0].time;
                if (self.doc.tracks.count > 0)
                {
                    OATrack *track = self.doc.tracks[0];
                    track.name = newName;
                    if (track.segments.count > 0)
                    {
                        OATrkSegment *seg = track.segments[0];
                        if (seg.points.count > 0)
                         {
                            OAWptPt *p = seg.points[0];
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
    state.showingState = self.currentState;

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

- (void)updateGpxData:(BOOL)replaceGPX updateDocument:(BOOL)updateDocument
{
    [super updateGpxData:replaceGPX updateDocument:updateDocument];
    [self updateWaypointsData];
    [self updateWaypointSortedGroups];
}

- (void)updateWaypointsData
{
    if (!_waypointGroups)
        _waypointGroups = [NSMutableDictionary dictionary];
    else
        [_waypointGroups removeAllObjects];

    if ([self.doc hasWptPt])
    {
        for (OAWptPt *gpxWpt in self.doc.points)
        {
            OAGpxWptItem *gpxWptItem = [OAGpxWptItem withGpxWpt:gpxWpt];
            if (gpxWpt.type.length == 0)
            {
                NSMutableArray<OAGpxWptItem *> *withoutGroup = _waypointGroups[OALocalizedString(@"shared_string_gpx_points")];
                if (!withoutGroup)
                {
                    withoutGroup = [NSMutableArray array];
                    [withoutGroup addObject:gpxWptItem];
                    _waypointGroups[OALocalizedString(@"shared_string_gpx_points")] = withoutGroup;
                }
                else
                {
                    [withoutGroup addObject:gpxWptItem];
                }
            }
            else
            {
                NSMutableArray<OAGpxWptItem *> *group = _waypointGroups[gpxWpt.type];
                if (!group)
                {
                    group = [NSMutableArray array];
                    [group addObject:gpxWptItem];
                    _waypointGroups[gpxWpt.type] = group;
                }
                else
                {
                    [group addObject:gpxWptItem];
                }
            }
        }
    }

    if ([self.doc hasRtePt])
    {
        for (OAWptPt *rtePt in [self.doc getRoutePoints])
        {
            OAGpxWptItem *rtePtItem = [OAGpxWptItem withGpxWpt:rtePt];
            NSMutableArray<OAGpxWptItem *> *rtePtsGroup = _waypointGroups[OALocalizedString(@"route_points")];
            if (!rtePtsGroup)
            {
                rtePtsGroup = [NSMutableArray array];
                [rtePtsGroup addObject:rtePtItem];
                _waypointGroups[OALocalizedString(@"route_points")] = rtePtsGroup;
            }
            else
            {
                [rtePtsGroup addObject:rtePtItem];
            }
        }
    }
}

- (void)updateWaypointSortedGroups
{
    _waypointSortedGroupNames = _waypointGroups ? [_waypointGroups.allKeys
            sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
                return [obj1 isEqualToString:OALocalizedString(@"route_points")] ? NSOrderedDescending
                        : [obj2 isEqualToString:OALocalizedString(@"route_points")] ? NSOrderedAscending
                                : [obj1 compare:obj2];
            }]: [NSArray array];
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

    if (_selectedTab == EOATrackMenuHudOverviewTab && CLLocationCoordinate2DIsValid(self.gpx.bounds.center))
    {
        CLLocationDirection newHeading = _app.locationServices.lastKnownHeading;
        CLLocationDirection newDirection = (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0.0f)
                ? newLocation.course : newHeading;

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
            NSArray<NSIndexPath *> *visibleRows = [self.tableView indexPathsForVisibleRows];
            for (NSIndexPath *visibleRow in visibleRows)
            {
                OAGPXTableCellData *cellData = _tableData.subjects[visibleRow.section].subjects[visibleRow.row];
                [_uiBuilder updateProperty:@"update_distance_and_direction" tableData:cellData];
            }
            [self.tableView reloadRowsAtIndexPaths:visibleRows
                                  withRowAnimation:UITableViewRowAnimationNone];
        });
    }
}

- (void)updateGroupsButton
{
    NSInteger groupsCount = [self.doc hasRtePt] ? _waypointSortedGroupNames.count - 1 : _waypointSortedGroupNames.count;
    [self.groupsButton setTitle:[NSString stringWithFormat:@"%li/%li", groupsCount - self.gpx.hiddenGroups.count, groupsCount]
                       forState:UIControlStateNormal];
    self.groupsButtonContainerView.hidden = groupsCount == 0;
    self.groupsButton.hidden = groupsCount == 0;
    if (_selectedTab == EOATrackMenuHudPointsTab)
    {
        [_headerView setGroupsCollection:[self generateGroupCollectionData]
                       withSelectedIndex:[_headerView.groupsCollectionView getSelectedIndex]];
    }
}

- (void)fitSelectedPointsGroupOnMap:(NSInteger)groupIndex
{
    if (_waypointSortedGroupNames.count > groupIndex && _tableData.subjects.count - 1 > groupIndex)
    {
        OAGPXTableSectionData *sectionData = _tableData.subjects[groupIndex];
        if (sectionData.values[@"quad_rect_value_points_area"])
        {
            CGSize screenBBox = CGSizeMake(
                    [self isLandscape] ? DeviceScreenWidth - [self getLandscapeViewWidth] : DeviceScreenWidth,
                    [self isLandscape] ? DeviceScreenHeight : DeviceScreenHeight - [self getViewHeight]
            );
            QuadRect *pointsRect = sectionData.values[@"quad_rect_value_points_area"];
            [self.mapPanelViewController displayAreaOnMap:CLLocationCoordinate2DMake(pointsRect.top, pointsRect.left)
                                              bottomRight:CLLocationCoordinate2DMake(pointsRect.bottom, pointsRect.right)
                                                     zoom:0.
                                                  maxZoom:18.
                                               screenBBox:screenBBox
                                              bottomInset:0.
                                                leftInset:0.
                                                 topInset:0.
                                                 animated:YES];
            if (![self isAdjustedMapViewPort])
                [self adjustMapViewPort];
        }
    }
}

- (IBAction)onBackButtonPressed:(id)sender
{
    [self hide:YES duration:.2 onComplete:^{
        [self.mapViewController hideContextPinMarker];

        if (![self openedFromMap])
        {
            UITabBarController *myPlacesViewController =
                    [[UIStoryboard storyboardWithName:@"MyPlaces" bundle:nil] instantiateInitialViewController];
            [myPlacesViewController setSelectedIndex:1];

            OAGPXListViewController *gpxController = myPlacesViewController.viewControllers[1];
            if (gpxController == nil)
                return;

            [gpxController setShouldPopToParent:YES];

            [[OARootViewController instance].navigationController pushViewController:myPlacesViewController animated:YES];
        }
    }];
}

- (IBAction)onGroupsButtonPressed:(id)sender
{
    OAEditWaypointsGroupOptionsViewController *editWaypointsGroupOptions =
            [[OAEditWaypointsGroupOptionsViewController alloc]
                    initWithScreenType:EOAEditWaypointsGroupVisibleScreen
                             groupName:nil
                            groupColor:nil];
    editWaypointsGroupOptions.delegate = self;
    [self presentViewController:editWaypointsGroupOptions animated:YES completion:nil];
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

- (OAGPXTrackAnalysis *)getGeneralAnalysis
{
    if (!self.analysis)
        [self updateAnalysis];

    return self.analysis;
}

- (OATrkSegment *)getGeneralSegment
{
    return [self.doc getGeneralSegment];
}

- (NSArray<OATrkSegment *> *)getSegments
{
    if (self.doc)
        return [self.doc getNonEmptyTrkSegments:NO];

    return @[];
}

- (void)editSegment
{
    [self hide:YES duration:.2 onComplete:^{
        [self.mapViewController hideContextPinMarker];
        [self.mapPanelViewController showScrollableHudViewController:[
                [OARoutePlanningHudViewController alloc] initWithFileName:self.gpx.gpxFilePath
                                                          targetMenuState:[self getCurrentState]]];
    }];
}

- (void)deleteAndSaveSegment:(OATrkSegment *)segment
{
    if (self.doc && segment && [self.doc removeTrackSegment:segment])
    {
        [self.doc saveTo:self.doc.path];
        [self.doc processPoints];
        [self updateGpxData:YES updateDocument:NO];

        if (self.isCurrentTrack)
            [[_app updateRecTrackOnMapObservable] notifyEvent];
        else
            [[_app updateGpxTracksOnMapObservable] notifyEvent];

        OAGPXTableSectionData *sectionData = [_tableData getSubject:[NSString stringWithFormat:@"section_%p", (__bridge void *) segment]];
        if (sectionData)
        {
            NSInteger sectionIndexToDelete = [_tableData.subjects indexOfObject:sectionData];
            [sectionData setData:@{ kTableValues: @{ @"delete_section_bool_value": @YES } }];
            [_uiBuilder updateData:sectionData];

            if (sectionIndexToDelete != NSNotFound)
            {
                [self.tableView beginUpdates];
                [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndexToDelete]
                              withRowAnimation:UITableViewRowAnimationNone];
                [self.tableView endUpdates];
            }

            [self.mapViewController.mapLayers.routeMapLayer hideCurrentStatisticsLocation];
        }

        if (_headerView)
            [_headerView setDescription];
    }
}

- (void)openEditSegmentScreen:(OATrkSegment *)segment
                     analysis:(OAGPXTrackAnalysis *)analysis
{
    OAEditWaypointsGroupBottomSheetViewController *editWaypointsBottomSheet =
            [[OAEditWaypointsGroupBottomSheetViewController alloc] initWithSegment:segment
                                                                          analysis:analysis];
    editWaypointsBottomSheet.trackMenuDelegate = self;
    [editWaypointsBottomSheet presentInViewController:self];
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

- (NSMutableDictionary<NSString *, NSMutableArray<OAGpxWptItem *> *> *)getWaypointsData
{
    return _waypointGroups;
}

- (NSArray<NSString *> *)getWaypointSortedGroups
{
    return _waypointSortedGroupNames;
}

- (NSInteger)getWaypointsCount:(NSString *)groupName
{
    return [_waypointGroups.allKeys containsObject:groupName] ? _waypointGroups[groupName].count : 0;
}

- (NSInteger)getWaypointsGroupColor:(NSString *)groupName
{
    if ([self isRteGroup:groupName])
        return [OAUtilities colorToNumber:UIColorFromRGB(color_footer_icon_gray)];

    UIColor *groupColor;
    if (groupName && groupName.length > 0 && [self getWaypointsCount:groupName] > 0)
    {
        OAGpxWptItem *waypoint = _waypointGroups[groupName].firstObject;
        groupColor = waypoint.color ? waypoint.color : [waypoint.point getColor];
    }
    if (!groupColor)
        groupColor = [OADefaultFavorite getDefaultColor];

    return [OAUtilities colorToNumber:groupColor];
}

- (BOOL)isWaypointsGroupVisible:(NSString *)groupName
{
    return ![self.gpx.hiddenGroups containsObject:[self isDefaultGroup:groupName] ? @"" : groupName];
}

- (void)setWaypointsGroupVisible:(NSString *)groupName show:(BOOL)show
{
    if (show)
        [self.gpx removeHiddenGroups:[self isDefaultGroup:groupName] ? @"" : groupName];
    else
        [self.gpx addHiddenGroups:[self isDefaultGroup:groupName] ? @"" : groupName];
    [[OAGPXDatabase sharedDb] save];

    if (_selectedTab == EOATrackMenuHudPointsTab)
    {
        OAGPXTableSectionData *sectionData = [_tableData getSubject:[NSString stringWithFormat:@"section_waypoints_group_%@", groupName]];
        if (sectionData)
        {
            [_uiBuilder updateData:sectionData];

            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0
                                                                        inSection:[_tableData.subjects indexOfObject:sectionData]]]
                                  withRowAnimation:UITableViewRowAnimationNone];
        }
    }

    [self updateGroupsButton];

    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.isCurrentTrack)
        {
            [self.mapViewController.mapLayers.gpxRecMapLayer refreshGpxWaypoints];
        }
        else
        {
            [self.mapViewController.mapLayers.gpxMapLayer updateCachedGpxItem:self.doc.path];
            [self.mapViewController.mapLayers.gpxMapLayer refreshGpxWaypoints];
        }
    });
}

- (void)deleteWaypointsGroup:(NSString *)groupName
           selectedWaypoints:(NSArray<OAGpxWptItem *> *)selectedWaypoints
{
    NSMutableArray<NSNumber *> *waypointsIdxToDelete = [NSMutableArray array];
    NSArray<OAGpxWptItem *> *waypointsToDelete = selectedWaypoints ? selectedWaypoints : _waypointGroups[groupName];
    for (OAGpxWptItem *waypoint in _waypointGroups[groupName])
    {
        if ([waypointsToDelete containsObject:waypoint])
            [waypointsIdxToDelete addObject:@([_waypointGroups[groupName] indexOfObject:waypoint])];
    }

    NSString *path = !self.isCurrentTrack ? [_app.gpxPath stringByAppendingPathComponent:self.gpx.gpxFilePath] : nil;
    [self.mapViewController deleteWpts:waypointsToDelete docPath:path];

    NSDictionary *dataToUpdate = @{
            @"delete_group_name_index": @([_waypointSortedGroupNames indexOfObject:groupName]),
            @"delete_waypoints_idx": waypointsIdxToDelete
    };

    [self updateGpxData:YES updateDocument:YES];

    [_uiBuilder updateProperty:dataToUpdate tableData:_tableData];
    [_uiBuilder updateData:_tableData];

    [self.tableView reloadData];
    [self updateGroupsButton];
    if (_headerView)
    {
        [_headerView setDescription];
        [_headerView updateFrame:_headerView.frame.size.width];
    }
}

- (void)changeWaypointsGroup:(NSString *)groupName
                newGroupName:(NSString *)newGroupName
               newGroupColor:(UIColor *)newGroupColor
{
    NSMutableDictionary *dataToUpdate = [NSMutableDictionary dictionary];
    dataToUpdate[@"old_group_name_index"] = @([_waypointSortedGroupNames indexOfObject:groupName]);
    if (newGroupName)
    {
        dataToUpdate[@"new_group_name"] = newGroupName;
        dataToUpdate[@"exist_group_name_index"] = @([_waypointSortedGroupNames indexOfObject:newGroupName]);
    }
    else if (newGroupColor)
    {
        dataToUpdate[@"new_group_color"] = newGroupColor;
    }

    NSMutableArray<OAGpxWptItem *> *waypoints = _waypointGroups[groupName];
    for (OAGpxWptItem *waypoint in waypoints)
    {
        if (newGroupName)
            waypoint.point.type = newGroupName;

        if (newGroupColor)
            waypoint.color = newGroupColor;

        if (self.isCurrentTrack)
        {
            [OAGPXDocument fillWpt:waypoint.point.wpt usingWpt:waypoint.point];
            [self.savingHelper saveWpt:waypoint.point];
        }
    }

    NSMutableArray<OAGpxWptItem *> *existWaypoints;
    if (newGroupName)
    {
        [_waypointGroups removeObjectForKey:groupName];
        NSInteger existI = [dataToUpdate[@"exist_group_name_index"] integerValue];
        if (existI != NSNotFound)
        {
            existWaypoints = _waypointGroups[newGroupName];
            if (existWaypoints)
            {
                for (OAGpxWptItem *existWaypoint in existWaypoints)
                {
                    existWaypoint.color = UIColorFromRGB([self getWaypointsGroupColor:groupName]);
                    if (self.isCurrentTrack)
                    {
                        [OAGPXDocument fillWpt:existWaypoint.point.wpt usingWpt:existWaypoint.point];
                        [self.savingHelper saveWpt:existWaypoint.point];
                    }
                }
                [existWaypoints addObjectsFromArray:waypoints];
            }
        }
        else
        {
            _waypointGroups[newGroupName] = waypoints;
        }
    }
    [self updateWaypointSortedGroups];

    if (!self.isCurrentTrack)
    {
        NSString *path = [_app.gpxPath stringByAppendingPathComponent:self.gpx.gpxFilePath];
        [self.mapViewController updateWpts:existWaypoints ? existWaypoints :waypoints docPath:path updateMap:YES];
    }
    else if (newGroupColor)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.mapViewController.mapLayers.gpxRecMapLayer refreshGpxWaypoints];
        });
    }

    if (newGroupName)
    {
        NSInteger newI = [_waypointSortedGroupNames indexOfObject:newGroupName];
        if (newI != NSNotFound)
            dataToUpdate[@"new_group_name_index"] = @(newI);
    }

    [_uiBuilder updateProperty:dataToUpdate tableData:_tableData];
    [_uiBuilder updateData:_tableData];

    [self.tableView reloadData];
    [self updateGroupsButton];
    if (_headerView)
        [_headerView setDescription];
}

- (void)openConfirmDeleteWaypointsScreen:(NSString *)groupName
//- (void)openDeleteWaypointsScreen:(OAGPXTableData *)tableData
{
    OADeleteWaypointsGroupBottomSheetViewController *deleteWaypointsGroupBottomSheet =
            [[OADeleteWaypointsGroupBottomSheetViewController alloc] initWithGroupName:groupName/*tableData*/];
    deleteWaypointsGroupBottomSheet.trackMenuDelegate = self;
    [deleteWaypointsGroupBottomSheet presentInViewController:self];
}

- (void)openDeleteWaypointsScreen:(NSArray *)sectionsData
{
    OADeleteWaypointsViewController *deleteWaypointsViewController =
            [[OADeleteWaypointsViewController alloc] initWithSectionsData:sectionsData];
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

- (BOOL)isRteGroup:(NSString *)groupName
{
    return [groupName isEqualToString:OALocalizedString(@"route_points")];
}

- (void)updateChartHighlightValue:(LineChartView *)chart
                          segment:(OATrkSegment *)segment
{
    CLLocationCoordinate2D pinLocation = [self getPinLocation];
    LineChartData *lineData = chart.lineData;
    NSArray<id <IChartDataSet>> *ds = lineData != nil ? lineData.dataSets : nil;
    if (ds && ds.count > 0 && segment)
    {
        float pos;
        double totalDistance = 0;
        OAWptPt *previousPoint = nil;
        for (OAWptPt *currentPoint in segment.points)
        {
           if (currentPoint.position.latitude == pinLocation.latitude
                   && currentPoint.position.longitude == pinLocation.longitude)
            {
                totalDistance += getDistance(previousPoint.position.latitude,
                                             previousPoint.position.longitude,
                                             currentPoint.position.latitude,
                                             currentPoint.position.longitude);
                pos = (float) (totalDistance / [GpxUIHelper getDivXWithDataSet:ds[0]]);

                float lowestVisibleX = chart.lowestVisibleX;
                float highestVisibleX = chart.highestVisibleX;
                float nextVisibleX = lowestVisibleX + (pos - chart.lastHighlighted.x);
                float oneFourthDiff = (highestVisibleX - lowestVisibleX) / 4;
                if (pos > oneFourthDiff)
                    nextVisibleX = pos - oneFourthDiff;

                [chart moveViewToX:nextVisibleX];

                [chart highlightValueWithX:pos
                              dataSetIndex:0
                                 dataIndex:-1];

                break;
            }

            if (previousPoint)
            {
                totalDistance += getDistance(previousPoint.position.latitude,
                        previousPoint.position.longitude,
                        currentPoint.position.latitude,
                        currentPoint.position.longitude);
            }
            previousPoint = currentPoint;
        }
    }
}

- (OARouteLineChartHelper *)getLineChartHelper
{
    if (!_routeLineChartHelper)
    {
        __weak OATrackMenuHudViewController *weakSelf = self;
        _routeLineChartHelper = [[OARouteLineChartHelper alloc] initWithGpxDoc:self.doc
                                                               centerMapOnBBox:^(OABBox rect) {
            [weakSelf.mapPanelViewController displayAreaOnMap:CLLocationCoordinate2DMake(rect.top, rect.left)
                                              bottomRight:CLLocationCoordinate2DMake(rect.bottom, rect.right)
                                                     zoom:0
                                              bottomInset:([weakSelf isLandscape] ? 0. : [weakSelf getViewHeight])
                                                leftInset:([weakSelf isLandscape] ? [weakSelf getLandscapeViewWidth] : 0.)
                                                 animated:YES];
                                                               }
                                                                adjustViewPort:^() {
                                                                    [weakSelf adjustMapViewPort];
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

- (OATrack *)getTrack:(OATrkSegment *)segment
{
    for (OATrack *trk in self.doc.tracks)
    {
        if ([trk.segments containsObject:segment])
            return trk;
    }
    return nil;
}

- (NSString *)getTrackSegmentTitle:(OATrkSegment *)segment
{
    OATrack *track = [self getTrack:segment];
    if (track)
        return [OAGPXDocument buildTrackSegmentName:self.doc track:track segment:segment];

    return nil;
}

- (NSString *)getDirName
{
    NSString *dirName = self.gpx.gpxFolderName.capitalizedString;
    return dirName.length > 0 ? dirName : OALocalizedString(@"tracks");
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
    if (self.doc.metadata.time <= [[NSDate date] timeIntervalSince1970])
        return [NSDateFormatter localizedStringFromDate:[NSDate dateWithTimeIntervalSince1970:self.doc.metadata.time]
                                              dateStyle:NSDateFormatterMediumStyle
                                              timeStyle:NSDateFormatterNoStyle];

    return @"";
}

- (NSString *)generateDescription
{
    switch (_selectedTab)
    {
        case EOATrackMenuHudOverviewTab:
        {
            if (self.doc.metadata.desc && self.doc.metadata.desc.length > 0)
            {
                _description = self.doc.metadata.desc;
            }
            else if (self.doc.metadata.extensions.count > 0)
            {
                for (OAGpxExtension *e in self.doc.metadata.extensions)
                {
                    if ([e.name isEqualToString:@"desc"])
                        _description = e.value;
                }
            }
            else
            {
                _description = @"";
            }
            break;
        }
        case EOATrackMenuHudSegmentsTab:
        {
            _description = [NSString stringWithFormat:@"%@: %li",
                    OALocalizedString(@"gpx_selection_segment_title"),
                            [self getGeneralSegment] ? _tableData.subjects.count - 1 : _tableData.subjects.count];
            break;
        }
        case EOATrackMenuHudPointsTab:
        {
            _description = [NSString stringWithFormat:@"%@: %li", OALocalizedString(@"groups"), _waypointGroups.allKeys.count];
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

- (NSString *)getMetadataImageLink
{
    NSArray *links = self.doc.metadata.links;
    if (links && links.count > 0)
    {
        for (OALink *link in links)
        {
            if (link.url && link.url.absoluteString && link.url.absoluteString.length > 0)
            {
                NSString *lowerCaseLink = [link.url.absoluteString lowerCase];
                if ([lowerCaseLink containsString:@".jpg"] ||
                    [lowerCaseLink containsString:@".jpeg"] ||
                    [lowerCaseLink containsString:@".png"] ||
                    [lowerCaseLink containsString:@".bmp"] ||
                    [lowerCaseLink containsString:@".webp"])
                {
                    return link.url.absoluteString;
                }
            }
        }
    }
    return nil;
}

- (BOOL)changeTrackVisible
{
    BOOL visible = [super changeTrackVisible];
    [_uiBuilder resetDataInTab:_selectedTab == EOATrackMenuHudOverviewTab ? EOATrackMenuHudActionsTab : EOATrackMenuHudOverviewTab];
    return visible;
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

- (CLLocationCoordinate2D)getPinLocation
{
    return _reopeningState.pinLocation;
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
        _exportFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:self.gpx.gpxFileName];
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
    OAEditDescriptionViewController *editDescController = [[OAEditDescriptionViewController alloc] initWithDescription:_description isNew:NO isEditing:NO readOnly:NO];
    editDescController.delegate = self;
    [self.navigationController pushViewController:editDescController animated:YES];
}

- (void)openDescriptionEditor
{
    OAEditDescriptionViewController *editDescController = [[OAEditDescriptionViewController alloc] initWithDescription:_description isNew:NO isEditing:YES readOnly:NO];
    editDescController.delegate = self;
    [self.navigationController pushViewController:editDescController animated:YES];
}

- (void)openDuplicateTrack
{
    OASaveTrackViewController *saveTrackViewController = [[OASaveTrackViewController alloc]
            initWithFileName:self.gpx.gpxFileName.stringByDeletingPathExtension
                    filePath:self.gpx.gpxFilePath
                   showOnMap:YES
             simplifiedTrack:NO
                   duplicate:YES];

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
        textField.text = self.gpx.gpxTitle.lastPathComponent.stringByDeletingPathExtension;
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

- (BOOL)openedFromMap
{
    return _reopeningState ? _reopeningState.openedFromMap : NO;
}

- (void)reloadSections:(NSIndexSet *)sections
{
    [self.tableView reloadSections:sections
                  withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - UIDocumentInteractionControllerDelegate

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
                initWithFileName:self.gpx.gpxFileName
                        filePath:self.gpx.gpxFilePath
                       showOnMap:YES
                 simplifiedTrack:YES
                       duplicate:NO];

        saveTrackViewController.delegate = self;
        [self presentViewController:saveTrackViewController animated:YES completion:nil];
    }
}

#pragma mark - OASelectTrackFolderDelegate

- (void)onFolderSelected:(NSString *)selectedFolderName
{
    [self copyGPXToNewFolder:selectedFolderName renameToNewName:nil deleteOriginalFile:YES openTrack:NO];
    [_uiBuilder resetDataInTab:EOATrackMenuHudOverviewTab];
    if (_selectedTab == EOATrackMenuHudActionsTab)
    {
        OAGPXTableSectionData *sectionData = [_tableData getSubject:@"section_change"];
        if (sectionData)
        {
            OAGPXTableCellData *cellData = [sectionData getSubject:@"change_move"];
            if (cellData)
            {
                [_uiBuilder updateData:cellData];

                [UIView setAnimationsEnabled:NO];
                [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[sectionData.subjects indexOfObject:cellData]
                                                                            inSection:[_tableData.subjects indexOfObject:sectionData]]]
                                      withRowAnimation:UITableViewRowAnimationNone];
                [UIView setAnimationsEnabled:YES];
            }
        }
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
               openTrack:(BOOL)openTrack
{
    [self copyGPXToNewFolder:fileName.stringByDeletingLastPathComponent
             renameToNewName:[fileName.lastPathComponent stringByAppendingPathExtension:@"gpx"]
          deleteOriginalFile:NO
                   openTrack:YES];
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
        _isTabSelecting = YES;
        if (_selectedTab == EOATrackMenuHudSegmentsTab)
            [self.mapViewController.mapLayers.routeMapLayer hideCurrentStatisticsLocation];

        if (_selectedTab == EOATrackMenuHudOverviewTab || _selectedTab == EOATrackMenuHudPointsTab)
            [self stopLocationServices];

        _selectedTab = (EOATrackMenuHudTab) item.tag;
        [_uiBuilder updateSelectedTab:_selectedTab];

        [self setupTableView];
        [self generateData];
        [self setupHeaderView];
        [_uiBuilder runAdditionalActions];

        BOOL animated = self.currentState != EOADraggableMenuStateFullScreen;
        if (_selectedTab == EOATrackMenuHudActionsTab)
        {
            [self goFullScreen:animated];
        }
        else if ([self isFirstStateChanged])
        {
            if (self.currentState == EOADraggableMenuStateInitial)
                [self goExpanded:animated];
            else
                [self updateView:animated];
        }
        else
        {
            [self updateView:animated];
        }

        [UIView transitionWithView:self.tableView
                          duration:0.35f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^(void) {
                            [self.tableView reloadData];
                            [self.tableView setContentOffset:CGPointZero];
                        }
                        completion: ^(BOOL finished) {
                            _isTabSelecting = NO;

                            if (_selectedTab == EOATrackMenuHudOverviewTab || (_selectedTab == EOATrackMenuHudPointsTab && _waypointGroups.count > 0))
                                [self startLocationServices];
                        }];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _tableData.subjects.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    OAGPXTableSectionData *sectionData = _tableData.subjects[section];
    if (_selectedTab == EOATrackMenuHudPointsTab)
    {
        OAGPXTableCellData *groupCellData = sectionData.subjects.firstObject;
        BOOL isGroup = [groupCellData.key hasPrefix:@"cell_waypoints_group_"];
        return (isGroup && groupCellData.toggle) || !isGroup ? sectionData.subjects.count : 1;
    }

    return sectionData.subjects.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return _tableData.subjects[section].header;
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
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextViewSimpleCell getCellIdentifier] owner:self options:nil];
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
            cell.separatorView.backgroundColor = UIColorFromRGB(color_tint_gray);
        }
        if (cell)
        {
            cell.titleView.font = [cellData.values.allKeys containsObject:@"font_value"]
                    ? cellData.values[@"font_value"] : [UIFont systemFontOfSize:17];
            cell.titleView.text = cellData.title;
            cell.textColorNormal = cellData.tintColor > 0 ? UIColorFromRGB(cellData.tintColor) : UIColor.blackColor;

            cell.iconColorNormal = cellData.tintColor > 0
                    ? UIColorFromRGB(cellData.tintColor) : UIColorFromRGB(color_primary_purple);
            cell.iconView.image = [UIImage templateImageNamed:cellData.rightIconName];

            BOOL isLast = indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1;
            [cell roundCorners:(indexPath.row == 0) bottomCorners:isLast hasLeftMargin:YES];
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
            [cell roundCorners:(indexPath.row == 0) bottomCorners:isLast hasLeftMargin:YES];
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
            cell.separatorView.backgroundColor = UIColorFromRGB(color_tint_gray);
        }
        if (cell)
        {
            cell.titleView.text = cellData.title;

            BOOL isLast = indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1;
            [cell roundCorners:(indexPath.row == 0) bottomCorners:isLast hasLeftMargin:YES];
            cell.separatorView.hidden = isLast;

            cell.switchView.on = [_uiBuilder isOn:cellData];

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
            cell.separatorInset = UIEdgeInsetsMake(0., 20., 0., 0.);
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell makeSelectable:NO];
        }
        if (cell)
        {
            [cell showOptionsButton:![self isRteGroup:cellData.title]];
            [cell.titleView setText:cellData.title];

            [cell.leftIconView setImage:cellData.leftIcon];
            cell.leftIconView.tintColor = UIColorFromRGB(cellData.tintColor);

            [cell.optionsButton setImage:[UIImage templateImageNamed:@"ic_custom_overflow_menu"]
                                forState:UIControlStateNormal];
            cell.optionsButton.imageView.tintColor = UIColorFromRGB(color_primary_purple);

            cell.arrowIconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.arrowIconView.image = [UIImage templateImageNamed:cellData.rightIconName];
            if (!cellData.toggle && [cell isDirectionRTL])
                cell.arrowIconView.image = cell.arrowIconView.image.imageFlippedForRightToLeftLayoutDirection;

            cell.openCloseGroupButton.tag = tag;
            [cell.openCloseGroupButton removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
            [cell.openCloseGroupButton addTarget:self
                                          action:@selector(openCloseGroupButtonAction:)
                                forControlEvents:UIControlEventTouchUpInside];

            cell.optionsButton.tag = tag;
            [cell.optionsButton removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
            [cell.optionsButton addTarget:self
                                   action:@selector(cellExtraButtonPressed:)
                         forControlEvents:UIControlEventTouchUpInside];

            cell.optionsGroupButton.tag = tag;
            [cell.optionsGroupButton removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
            [cell.optionsGroupButton addTarget:self
                                        action:@selector(cellExtraButtonPressed:)
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
            NSInteger segmentsCount = 0;
            for (NSString *key in cellData.values.allKeys)
            {
                if ([key hasPrefix:@"tab_"])
                    segmentsCount++;
            }

            [cell.segmentControl setTitle:cellData.values[@"tab_0_string_value"] forSegmentAtIndex:0];
            if (segmentsCount == 3)
            {
                if (cell.segmentControl.numberOfSegments < 2)
                    [cell.segmentControl insertSegmentWithTitle:cellData.values[@"tab_1_string_value"] atIndex:1 animated:NO];
                else
                    [cell.segmentControl setTitle:cellData.values[@"tab_1_string_value"] forSegmentAtIndex:1];
                if (cell.segmentControl.numberOfSegments < 3)
                    [cell.segmentControl insertSegmentWithTitle:cellData.values[@"tab_2_string_value"] atIndex:2 animated:NO];
                else
                    [cell.segmentControl setTitle:cellData.values[@"tab_2_string_value"] forSegmentAtIndex:2];
            }
            else if (segmentsCount == 2)
            {
                NSString *value = cellData.values[[cellData.values.allKeys containsObject:@"tab_2_string_value"] ? @"tab_2_string_value" : @"tab_1_string_value"];
                if (cell.segmentControl.numberOfSegments < 2)
                    [cell.segmentControl insertSegmentWithTitle:value atIndex:1 animated:NO];
                else
                    [cell.segmentControl setTitle:value forSegmentAtIndex:1];
                if (cell.segmentControl.numberOfSegments == 3)
                    [cell.segmentControl removeSegmentAtIndex:2 animated:NO];
            }
            else
            {
                if (cell.segmentControl.numberOfSegments > 2)
                    [cell.segmentControl removeSegmentAtIndex:2 animated:NO];
                if (cell.segmentControl.numberOfSegments > 1)
                    [cell.segmentControl removeSegmentAtIndex:1 animated:NO];
            }

            cell.segmentControl.tag = tag;
            [cell.segmentControl removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.segmentControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
            NSInteger selectedIndex = [cellData.values[@"selected_index_int_value"] integerValue];
            cell.segmentControl.selectedSegmentIndex = selectedIndex != NSNotFound ? selectedIndex : 0;
        }
        return cell;
    }
    else if ([cellData.type isEqualToString:[OALineChartCell getCellIdentifier]])
    {
        OAGPXTableSectionData *sectionData = _tableData.subjects[indexPath.section];
        return sectionData.values[@"cell_value"];
    }
    else if ([cellData.type isEqualToString:[OARadiusCellEx getCellIdentifier]])
    {
        OARadiusCellEx *cell = [tableView dequeueReusableCellWithIdentifier:[OARadiusCellEx getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARadiusCellEx getCellIdentifier] owner:self options:nil];
            cell = (OARadiusCellEx *) nib[0];
            cell.buttonRight.imageView.layer.cornerRadius = 12;
            cell.buttonRight.imageView.backgroundColor = [UIColorFromRGB(color_primary_purple) colorWithAlphaComponent:0.1];
            cell.buttonRight.tintColor = UIColorFromRGB(color_primary_purple);
            [cell.buttonRight setTitleColor:UIColorFromRGB(color_primary_purple) forState:UIControlStateNormal];
            [cell.buttonLeft setTitleColor:UIColorFromRGB(color_primary_purple) forState:UIControlStateNormal];
        }
        if (cell)
        {
            [cell.buttonLeft setTitle:cellData.values[@"left_title_string_value"] forState:UIControlStateNormal];

            cell.buttonLeft.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
            cell.buttonLeft.tag = tag;
            [cell.buttonLeft removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
            [cell.buttonLeft addTarget:self
                                action:@selector(cellButtonPressed:)
                      forControlEvents:UIControlEventTouchUpInside];

            [cell showButtonRight:cellData.toggle];
            if (cellData.toggle)
            {
                UIImage *rightIcon = [UIImage imageNamed:cellData.values[@"right_icon_string_value"]];
                rightIcon = [OAUtilities resizeImage:rightIcon newSize:CGSizeMake(30., 30.)];
                [cell.buttonRight setImage:[OAUtilities getTintableImage:rightIcon] forState:UIControlStateNormal];
                cell.buttonRight.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
                cell.buttonRight.imageView.backgroundColor = UIColor.clearColor;
                cell.buttonRight.imageView.tintColor = UIColorFromRGB(color_primary_purple);

                CGFloat buttonWidth = ((![self isLandscape] ? tableView.frame.size.width
                        : tableView.frame.size.width - [OAUtilities getLeftMargin]) - 40) / 2;
                CGFloat imageWidth = cell.buttonRight.imageView.image.size.width;

                cell.buttonRight.titleEdgeInsets = UIEdgeInsetsMake(0., 0., 0., imageWidth + 6);
                cell.buttonRight.imageEdgeInsets = UIEdgeInsetsMake(0., buttonWidth - imageWidth, 0., 0.);

                [cell.buttonRight setTitle:cellData.values[@"right_title_string_value"] forState:UIControlStateNormal];
                cell.buttonRight.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
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
    else if ([cellData.type isEqualToString:[OAImageDescTableViewCell getCellIdentifier]])
    {
        OAImageDescTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAImageDescTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAImageDescTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAImageDescTableViewCell *)[nib objectAtIndex:0];
        }
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.separatorInset = UIEdgeInsetsMake(0., DBL_MAX, 0., 0.);
        cell.iconView.contentMode = UIViewContentModeScaleAspectFill;
        cell.descView.hidden = YES;
        cell.imageBottomToLabelConstraint.priority = 1;
        cell.imageBottomConstraint.priority = 1000;
        cell.imageBottomConstraint.constant = 0;

        if (!_isImageDownloadFinished)
        {
            cell.activityIndicatorView.hidden = NO;
            [cell.activityIndicatorView startAnimating];
            cell.iconView.image = nil;
            cell.iconViewHeight.constant = 40;
        }
        else
        {
            cell.activityIndicatorView.hidden = YES;
            [cell.activityIndicatorView stopAnimating];
            if (_isImageDownloadSucceed)
            {
                cell.iconView.image = _cachedImage;
                cell.imageTopConstraint.constant = 16;
                cell.iconViewHeight.constant = kGpxDescriptionImageHeight;
            }
            else
            {
                cell.iconView.image = nil;
                cell.imageTopConstraint.constant = 1;
                cell.iconViewHeight.constant = 1;
            }
        }
        outCell =  cell;
    }

    if ([outCell needsUpdateConstraints])
        [outCell updateConstraints];

    return outCell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAGPXTableCellData *cellData = [self getCellData:indexPath];
    if ([cellData.type isEqualToString:[OATitleIconRoundCell getCellIdentifier]])
        return [OATitleIconRoundCell getHeight:cellData.title cellWidth:tableView.bounds.size.width];
    else if ([cellData.type isEqualToString:[OATitleDescriptionIconRoundCell getCellIdentifier]])
        return [OATitleDescriptionIconRoundCell getHeight:cellData.title descr:cellData.desc cellWidth:tableView.bounds.size.width];
    else if ([cellData.type isEqualToString:[OATitleSwitchRoundCell getCellIdentifier]])
        return [OATitleSwitchRoundCell getHeight:cellData.title cellWidth:tableView.bounds.size.width];

    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    OAGPXTableSectionData *sectionData = _tableData.subjects[section];
    CGFloat sectionHeaderHeight = sectionData.headerHeight > 0 ? sectionData.headerHeight : 0.01;
    return section == 0 ? sectionHeaderHeight + _headerView.frame.size.height : sectionHeaderHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return _tableData.subjects && _tableData.subjects.count > 0 && section == _tableData.subjects.count - 1
            ? self.toolBarView.frame.size.height + 60. : 0.01;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAGPXTableCellData *cellData = [self getCellData:indexPath];
    [_uiBuilder onButtonPressed:cellData];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Selectors

- (void)onSwitchPressed:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:switchView.tag & 0x3FF inSection:switchView.tag >> 10];
    OAGPXTableCellData *cellData = [self getCellData:indexPath];
    [_uiBuilder onSwitch:switchView.isOn tableData:cellData];
}

- (void)openCloseGroupButtonAction:(id)sender
{
    UIButton *button = (UIButton *)sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag & 0x3FF inSection:button.tag >> 10];
    OAGPXTableCellData *cellData = [self getCellData:indexPath];
    [cellData setData:@{
            kCellToggle: @(!cellData.toggle)
    }];
    [cellData setData:@{
            kCellRightIconName: cellData.toggle ? @"ic_custom_arrow_up" : @"ic_custom_arrow_right"
    }];

    [self.tableView beginUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]
                  withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

- (void)cellExtraButtonPressed:(id)sender
{
    UIButton *button = (UIButton *) sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag & 0x3FF inSection:button.tag >> 10];
    OAGPXTableCellData *cellData = [self getCellData:indexPath];
    [_uiBuilder onButtonPressed:cellData];
}

- (void)cellButtonPressed:(id)sender
{
    UIButton *button = (UIButton *) sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag & 0x3FF inSection:button.tag >> 10];
    OAGPXTableCellData *cellData = [self getCellData:indexPath];

    if ([cellData.key hasPrefix:@"segment_buttons_"])
    {
        for (UIGestureRecognizer *recognizer in self.tableView.gestureRecognizers)
        {
            if ([recognizer isKindOfClass:UIPanGestureRecognizer.class])
            {
                BOOL isLeftButton = [recognizer locationInView:self.view].x < self.tableView.frame.size.width / 2;
                BOOL isRTL = [button isDirectionRTL];
                cellData.values[@"is_left_button_selected"] = @(((isLeftButton && !isRTL) || (!isLeftButton && isRTL)));
                [_uiBuilder onButtonPressed:cellData];
                [cellData.values removeObjectForKey:@"is_left_button_selected"];
                break;
            }
        }
    }
    else if (![cellData.key hasPrefix:@"cell_waypoints_group_"])
    {
        [_uiBuilder onButtonPressed:cellData];
    }
}

- (void)segmentChanged:(id)sender
{
    UISegmentedControl *segment = (UISegmentedControl *) sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:segment.tag & 0x3FF inSection:segment.tag >> 10];
    OAGPXTableCellData *cellData = [self getCellData:indexPath];
    cellData.values[@"selected_index_int_value"] = @(segment.selectedSegmentIndex);

    [_uiBuilder updateData:cellData];

    NSInteger rowToUpdateIndex = [cellData.values[@"row_to_update_int_value"] integerValue];
    if (rowToUpdateIndex != NSNotFound)
    {
        [self.tableView reloadRowsAtIndexPaths:@[
                        [NSIndexPath indexPathForRow:rowToUpdateIndex
                                           inSection:indexPath.section]]
                              withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (_selectedTab == EOATrackMenuHudSegmentsTab || _selectedTab == EOATrackMenuHudPointsTab)
    {
        if (!_isHeaderBlurred && scrollView.contentOffset.y > 0)
        {
            [_headerView addBlurEffect:YES cornerRadius:0. padding:0.];
            _isHeaderBlurred = YES;
        }
        else if (_isHeaderBlurred && scrollView.contentOffset.y <= 0)
        {
            [_headerView removeBlurEffect];
            _isHeaderBlurred = NO;
        }
        if (_selectedTab == EOATrackMenuHudPointsTab && _waypointSortedGroupNames.count > 0)
        {
            CGPoint p = scrollView.contentOffset;
            p.y += _headerView.frame.size.height;
            NSIndexPath *ip = [self.tableView indexPathForRowAtPoint:p];
            if (ip && ip.section > 0)
            {
                p.y += [self tableView:self.tableView heightForHeaderInSection:ip.section];
                ip = [self.tableView indexPathForRowAtPoint:p];
            }
            if (ip)
            {
                [_headerView setSelectedIndexGroupsCollection:ip.section];
                if (ip.section < _waypointSortedGroupNames.count)
                {
                    [_headerView.groupsCollectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:ip.section inSection:0]
                                                             atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                                                     animated:YES];
                }
            }
        }
    }

    if ([self shouldScrollInAllModes])
        return;

    if (scrollView.contentOffset.y <= 0 || self.contentContainer.frame.origin.y != [OAUtilities getStatusBarHeight])
        [scrollView setContentOffset:CGPointZero animated:NO];

    BOOL shouldShow = self.tableView.contentOffset.y > 0;
    self.topHeaderContainerView.layer.shadowOpacity = shouldShow ? 0.15 : 0.0;
}

#pragma mark - OAFoldersCellDelegate

- (void)onItemSelected:(NSInteger)index
{
    if (_selectedTab == EOATrackMenuHudPointsTab)
    {
        CGRect rectForSection = [self.tableView rectForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:index]];
        [self.tableView setContentOffset:CGPointMake(0, rectForSection.origin.y - _headerView.frame.size.height)
                                animated:NO];
        [self fitSelectedPointsGroupOnMap:index];
        [_headerView.groupsCollectionView reloadData];
        [self.mapPanelViewController.hudViewController updateMapRulerDataWithDelay];
    }
}

#pragma mark - OAEditDescriptionViewControllerDelegate

- (void) descriptionChanged:(NSString *)descr
{
    self.doc.metadata.desc = descr;
    [self.doc saveTo:self.doc.path];
    _description = [self generateDescription];
    if (_headerView)
    {
        [_headerView setDescription];
        [_headerView updateFrame:_headerView.frame.size.width];
    }
    OAGPXTableSectionData *sectionData = [_tableData getSubject:@"section_description"];
    if (sectionData)
    {
        [_uiBuilder updateData:sectionData];

        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:[_tableData.subjects indexOfObject:sectionData]]
                      withRowAnimation:UITableViewRowAnimationNone];
    }
}

@end
