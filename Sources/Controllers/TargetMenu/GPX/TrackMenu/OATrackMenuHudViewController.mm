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
#import "OATargetPointsHelper.h"
#import "OASelectedGPXHelper.h"
#import "OAGPXUIHelper.h"
#import "OAGPXTrackAnalysis.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGPXDocument.h"
#import "OAGPXMutableDocument.h"
#import "OAMapActions.h"
#import "OARouteProvider.h"
#import "OAOsmAndFormatter.h"
#import "OASavingTrackHelper.h"
#import "OAAutoObserverProxy.h"
#import "OAGpxWptItem.h"
#import "OADefaultFavorite.h"
#import "OAMapLayers.h"
#import "OARouteStatisticsHelper.h"

#import <Charts/Charts-Swift.h>
#import "OsmAnd_Maps-Swift.h"

#define kActionsSection 4

#define kInfoCreatedOnCell 0
#define kActionMoveCell 1

@implementation OATrackMenuViewControllerState

@end

@interface OATrackMenuHudViewController() <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, UITabBarDelegate, UIDocumentInteractionControllerDelegate, ChartViewDelegate, OASaveTrackViewControllerDelegate, OASegmentSelectionDelegate, OATrackMenuViewControllerDelegate, OASelectTrackFolderDelegate>

@property (weak, nonatomic) IBOutlet OATabBar *tabBarView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomSeparatorHeight;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomSeparatorTopConstraint;

@property (nonatomic) BOOL isShown;
@property (nonatomic) NSArray<OAGPXTableSectionData *> *tableData;

@end

@implementation OATrackMenuHudViewController
{
    OsmAndAppInstance _app;
    OAGPXMutableDocument *_mutableDoc;
    OARouteLineChartHelper *_routeLineChartHelper;

    OAAutoObserverProxy *_locationServicesUpdateObserver;
    NSTimeInterval _lastUpdate;

    UIDocumentInteractionController *_exportController;
    OATrackMenuHeaderView *_headerView;

    NSString *_description;
    NSString *_exportFileName;
    NSString *_exportFilePath;

    EOATrackMenuHudTab _selectedTab;
    OATrackMenuViewControllerState *_reopeningState;

    NSDictionary<NSString *, NSArray<OAGpxWptItem *> *> *_waypointGroups;
    NSMutableDictionary<NSString *, NSString *> *_waypointGroupsOldNewNames;
    NSArray<OAGpxTrkSeg *> *_segments;

    BOOL _hasTranslated;
    CGPoint _lastTranslation;
    double _highlightDrawX;
}

@dynamic isShown, tableData;

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
    _routeLineChartHelper = [[OARouteLineChartHelper alloc] initWithGpxDoc:self.doc
                                                           centerMapOnBBox:^(OABBox rect) {
        [self.mapPanelViewController displayAreaOnMap:CLLocationCoordinate2DMake(rect.top, rect.left)
                                          bottomRight:CLLocationCoordinate2DMake(rect.bottom, rect.right)
                                                 zoom:0
                                          bottomInset:DeviceScreenHeight - ([self isLandscape] ? 0.0 : [self getViewHeight])
                                            leftInset:DeviceScreenWidth - ([self isLandscape] ? DeviceScreenWidth * 0.45 : 0.0)];
                                                           }
                                                            adjustViewPort:^() {
                                                                [self adjustMapViewPort];
                                                            }];
    _routeLineChartHelper.isLandscape = [self isLandscape];
    _routeLineChartHelper.screenBBox = CGRectMake(0., 0.,
            DeviceScreenWidth - ([self isLandscape]? DeviceScreenWidth * 0.45 : 0.0),
            DeviceScreenHeight - ([self isLandscape] ? 0.0 : [self getViewHeight]));
    _lastTranslation = CGPointZero;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    if (!self.isShown)
        [self onShowHidePressed:nil];

    [self startLocationServices];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {

    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        _routeLineChartHelper.isLandscape = [self isLandscape];
        _routeLineChartHelper.screenBBox = CGRectMake(0., 0.,
                DeviceScreenWidth - ([self isLandscape] ? DeviceScreenWidth * 0.45 : 0.0),
                DeviceScreenHeight - ([self isLandscape] ? 0.0 : [self getViewHeight]));
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
    [self setupTabBar];
    [self setupTableView];
    [self setupDescription];
}

- (void)setupTableView
{
    if (_selectedTab == EOATrackMenuHudActionsTab)
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    else
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
}

- (void)setupTabBar
{
    [self.tabBarView setItems:@[
            [self createTabBarItem:EOATrackMenuHudOverviewTab],
            [self createTabBarItem:EOATrackMenuHudSegmentsTab],
            [self createTabBarItem:EOATrackMenuHudPointsTab],
            [self createTabBarItem:EOATrackMenuHudActionsTab]
    ] animated:YES];

    self.tabBarView.selectedItem = self.tabBarView.items[_selectedTab];
    self.tabBarView.itemWidth = self.scrollableView.frame.size.width / self.tabBarView.items.count;
    self.tabBarView.delegate = self;
    self.tabBarView.backgroundImage = [UIImage new];
    self.tabBarView.shadowImage = [UIImage new];
}

- (UITabBarItem *)createTabBarItem:(EOATrackMenuHudTab)tab
{
    UIColor *unselectedColor = UIColorFromRGB(unselected_tab_icon);
    UIFont *titleFont = [UIFont systemFontOfSize:12];
    NSString *title;
    NSString *icon;

    switch (tab)
    {
        case EOATrackMenuHudActionsTab:
        {
            title = @"actions";
            icon = @"ic_custom_overflow_menu";
            break;
        }
        case EOATrackMenuHudSegmentsTab:
        {
            title = @"track";
            icon = @"ic_custom_trip";
            break;
        }
        case EOATrackMenuHudPointsTab:
        {
            title = @"shared_string_gpx_points";
            icon = @"ic_custom_waypoint";
            break;
        }
        case EOATrackMenuHudOverviewTab:
        default:
        {
            title = @"shared_string_overview";
            icon = @"ic_custom_overview";
            break;
        }
    }

    UITabBarItem *tabBarItem = [[UITabBarItem alloc] initWithTitle:OALocalizedString(title)
            image:[OAUtilities tintImageWithColor:[UIImage templateImageNamed:icon] color:unselectedColor]
                                                               tag:tab];

    [tabBarItem setTitleTextAttributes:@{
            NSForegroundColorAttributeName: UIColorFromRGB(color_text_footer),
            NSFontAttributeName: titleFont
    } forState:UIControlStateNormal];

    [tabBarItem setTitleTextAttributes:@{
            NSForegroundColorAttributeName: UIColorFromRGB(color_primary_purple),
            NSFontAttributeName: titleFont
    } forState:UIControlStateSelected];

    return tabBarItem;
}

- (void)setupDescription
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
}

- (void)setupHeaderView
{
    if (_headerView)
        [_headerView removeFromSuperview];

    _headerView = [[OATrackMenuHeaderView alloc] init];
    _headerView.trackMenuDelegate = self;
    [_headerView setDescription:_description];

    BOOL isOverview = _selectedTab == EOATrackMenuHudOverviewTab;
    _headerView.backgroundColor = isOverview ? UIColor.whiteColor : UIColorFromRGB(color_bottom_sheet_background);
    self.topHeaderContainerView.superview.backgroundColor =
            isOverview ? UIColor.whiteColor : UIColorFromRGB(color_bottom_sheet_background);

    if (_selectedTab != EOATrackMenuHudActionsTab)
    {
        [_headerView.titleView setText:self.isCurrentTrack ? OALocalizedString(@"track_recording_name") : [self.gpx getNiceTitle]];
        _headerView.titleIconView.image = [UIImage templateImageNamed:@"ic_custom_trip"];
        _headerView.titleIconView.tintColor = UIColorFromRGB(color_icon_inactive);
    }

    if (isOverview)
    {
        [self generateGpxBlockStatistics];

        CLLocationCoordinate2D gpxLocation = self.doc.bounds.center;
        CLLocation *lastKnownLocation = _app.locationServices.lastKnownLocation;
        NSString *direction = lastKnownLocation && gpxLocation.latitude != DBL_MAX ?
                [OAOsmAndFormatter getFormattedDistance:getDistance(
                        lastKnownLocation.coordinate.latitude, lastKnownLocation.coordinate.longitude,
                        gpxLocation.latitude, gpxLocation.longitude)] : @"";

        [_headerView setDirection:direction];
        if (!_headerView.directionContainerView.hidden)
        {
            _headerView.directionIconView.image = [UIImage templateImageNamed:@"ic_small_direction"];
            _headerView.directionIconView.tintColor = UIColorFromRGB(color_primary_purple);
            _headerView.directionTextView.textColor = UIColorFromRGB(color_primary_purple);
        }

        if (gpxLocation.latitude != DBL_MAX)
        {
            OAWorldRegion *worldRegion = [_app.worldRegion findAtLat:gpxLocation.latitude
                                                                     lon:gpxLocation.longitude];
            _headerView.regionIconView.image = [UIImage templateImageNamed:@"ic_small_map_point"];
            _headerView.regionIconView.tintColor = UIColorFromRGB(color_tint_gray);
            [_headerView.regionTextView setText:worldRegion.localizedName ? worldRegion.localizedName : worldRegion.nativeName];
            _headerView.regionTextView.textColor = UIColorFromRGB(color_text_footer);
        }
        else
        {
            [_headerView showLocation:NO];
        }

        [_headerView.showHideButton setTitle:self.isShown ? OALocalizedString(@"poi_hide") : OALocalizedString(@"sett_show")
                                    forState:UIControlStateNormal];
        [_headerView.showHideButton setImage:[UIImage templateImageNamed:self.isShown ? @"ic_custom_hide" : @"ic_custom_show"]
                                    forState:UIControlStateNormal];
        [_headerView.showHideButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [_headerView.showHideButton addTarget:self action:@selector(onShowHidePressed:)
                             forControlEvents:UIControlEventTouchUpInside];

        [_headerView.appearanceButton setTitle:OALocalizedString(@"map_settings_appearance")
                                      forState:UIControlStateNormal];
        [_headerView.appearanceButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [_headerView.appearanceButton addTarget:self action:@selector(onAppearancePressed:)
                               forControlEvents:UIControlEventTouchUpInside];

        if (!self.isCurrentTrack)
        {
            [_headerView.exportButton setTitle:OALocalizedString(@"shared_string_export") forState:UIControlStateNormal];
            [_headerView.exportButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [_headerView.exportButton addTarget:self action:@selector(onExportPressed:)
                               forControlEvents:UIControlEventTouchUpInside];

            [_headerView.navigationButton setTitle:OALocalizedString(@"routing_settings") forState:UIControlStateNormal];
            [_headerView.navigationButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [_headerView.navigationButton addTarget:self action:@selector(onNavigationPressed:)
                                   forControlEvents:UIControlEventTouchUpInside];
        }
        else
        {
            _headerView.exportButton.hidden = YES;
            _headerView.navigationButton.hidden = YES;
        }
    }
    else if (_selectedTab == EOATrackMenuHudActionsTab)
    {
        [_headerView.titleView setText:OALocalizedString(@"actions")];
        _headerView.titleIconView.image = nil;
        [_headerView makeOnlyHeader:NO];
    }
    else
    {
        [_headerView makeOnlyHeader:YES];
    }

    if ([_headerView needsUpdateConstraints])
        [_headerView updateConstraints];

    [_headerView updateFrame];

    CGRect topHeaderContainerFrame = self.topHeaderContainerView.frame;
    topHeaderContainerFrame.size.height = _headerView.frame.size.height;
    self.topHeaderContainerView.frame = topHeaderContainerFrame;

    [self.topHeaderContainerView insertSubview:_headerView atIndex:0];
    [self.topHeaderContainerView sendSubviewToBack:_headerView];

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

    if (_selectedTab == EOATrackMenuHudOverviewTab)
    {
        [self generateDataForOverviewScreen];
    }
    else if (_selectedTab == EOATrackMenuHudSegmentsTab)
    {
        [self generateDataForSegmentsScreen];
    }
    else if (_selectedTab == EOATrackMenuHudPointsTab)
    {
        [self generateDataForPointsScreen];
    }
    else if (_selectedTab == EOATrackMenuHudActionsTab)
    {
        [self generateDataForActionsScreen];
    }
}

- (void)generateDataForOverviewScreen
{
    NSMutableArray<OAGPXTableSectionData *> *tableSections = [NSMutableArray array];

    if (_description && _description.length > 0)
    {
        NSMutableArray<OAGPXTableCellData *> *descriptionCells = [NSMutableArray array];

        NSAttributedString * (^generateDescriptionAttrString) (void) = ^{
            return [OAUtilities createAttributedString:
                            [_description componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]][0]
                                                  font:[UIFont systemFontOfSize:17]
                                                 color:UIColor.blackColor
                                           strokeColor:nil
                                           strokeWidth:0
                                             alignment:NSTextAlignmentNatural];
        };

        NSAttributedString *descriptionAttr = generateDescriptionAttrString();
        OAGPXTableCellData *description = [OAGPXTableCellData withData:@{
                kCellKey: @"description",
                kCellType: [OATextViewSimpleCell getCellIdentifier],
                kTableValues: @{ @"attr_string_value": descriptionAttr }
        }];

        [description setData:@{
                kTableUpdateData: ^() {
                    [description setData:@{kTableValues: @{ @"attr_string_value": generateDescriptionAttrString() } }];
                }
        }];
        [descriptionCells addObject:description];

        OAGPXTableCellData * (^generateDataForFullDescriptionCell) (void) = ^{
            return [OAGPXTableCellData withData:@{
                    kCellKey: @"full_description",
                    kCellType: [OATextLineViewCell getCellIdentifier],
                    kCellTitle: OALocalizedString(@"read_full_description")
            }];
        };

        if (_description.length > descriptionAttr.length)
            [descriptionCells addObject:generateDataForFullDescriptionCell()];

        OAGPXTableSectionData *descriptionSection = [OAGPXTableSectionData withData:@{
                kSectionCells: descriptionCells,
                kSectionHeader: OALocalizedString(@"description")
        }];
        [descriptionSection setData:@{
                kTableUpdateData: ^() {
                    NSAttributedString *newDescriptionAttr = generateDescriptionAttrString();

                    BOOL hasFullDescription = [descriptionSection.cells.lastObject.key isEqualToString:@"full_description"];
                    if (_description.length > newDescriptionAttr.length && !hasFullDescription)
                        [descriptionSection.cells addObject:generateDataForFullDescriptionCell()];
                    else if (_description.length <= newDescriptionAttr.length && hasFullDescription)
                        [descriptionSection.cells removeObject:descriptionSection.cells.lastObject];

                    for (OAGPXTableCellData *cellData in descriptionSection.cells)
                    {
                        if (cellData.updateData)
                            cellData.updateData();
                    }
                }
        }];
        [tableSections addObject:descriptionSection];
    }

    NSMutableArray<OAGPXTableCellData *> *infoCells = [NSMutableArray array];

    NSString * (^generateSizeString) (void) = ^{
        NSDictionary *fileAttributes = [NSFileManager.defaultManager attributesOfItemAtPath:self.isCurrentTrack
                ? self.gpx.gpxFilePath : self.doc.path error:nil];
        return [NSByteCountFormatter stringFromByteCount:fileAttributes.fileSize
                                              countStyle:NSByteCountFormatterCountStyleFile];
    };

    OAGPXTableCellData *size = [OAGPXTableCellData withData:@{
            kCellKey: @"size",
            kCellType: [OAIconTitleValueCell getCellIdentifier],
            kCellTitle: OALocalizedString(@"res_size"),
            kCellDesc: generateSizeString()
    }];

    [size setData:@{
            kTableUpdateData: ^() {
                [size setData:@{ kCellDesc: generateSizeString() }];
            }
    }];
    [infoCells addObject:size];

    OAGPXTableCellData * (^generateDataForCreatedOnCell) (void) = ^{

        NSString * (^generateCreatedOnString) (void) = ^{
            return [NSDateFormatter localizedStringFromDate:[NSDate dateWithTimeIntervalSince1970:self.doc.metadata.time]
                                                  dateStyle:NSDateFormatterMediumStyle
                                                  timeStyle:NSDateFormatterNoStyle];
        };

        OAGPXTableCellData *createdOn = [OAGPXTableCellData withData:@{
                kCellKey: @"created_on",
                kCellType: [OAIconTitleValueCell getCellIdentifier],
                kCellTitle: OALocalizedString(@"res_created_on"),
                kCellDesc: generateCreatedOnString()
        }];
        [createdOn setData:@{
                kTableUpdateData: ^() {
                    [createdOn setData:@{ kCellDesc: generateCreatedOnString() }];
                }
        }];

        return createdOn;
    };

    if (self.doc.metadata.time > 0)
        [infoCells addObject:generateDataForCreatedOnCell()];

    OAGPXTableCellData * (^generateDataForLocationCell) (void) = ^{
        OAGPXTableCellData *createdOn = [OAGPXTableCellData withData:@{
                kCellKey: @"location",
                kCellType: [OAIconTitleValueCell getCellIdentifier],
                kCellTitle: OALocalizedString(@"sett_arr_loc"),
                kCellDesc: [[OAGPXDatabase sharedDb] getFileDir:self.gpx.gpxFilePath].capitalizedString
        }];
        [createdOn setData:@{
                kTableUpdateData: ^() {
                    [createdOn setData:@{ kCellDesc: [[OAGPXDatabase sharedDb] getFileDir:self.gpx.gpxFilePath].capitalizedString }];
                }
        }];
        return createdOn;
    };

    if (!self.isCurrentTrack)
        [infoCells addObject:generateDataForLocationCell()];

    OAGPXTableSectionData *infoSection = [OAGPXTableSectionData withData:@{
            kSectionCells: infoCells,
            kSectionHeader: OALocalizedString(@"shared_string_info")
    }];
    [infoSection setData:@{
            kTableUpdateData: ^() {
                BOOL hasCreatedOn = [infoSection containsCell:@"created_on"];
                if (self.doc.metadata.time > 0 && !hasCreatedOn)
                    [infoSection.cells insertObject:generateDataForCreatedOnCell() atIndex:kInfoCreatedOnCell];
                else if (self.doc.metadata.time <= 0 && hasCreatedOn)
                    [infoSection.cells removeObjectAtIndex:kInfoCreatedOnCell];

                BOOL hasLocation = [infoSection.cells.lastObject.key isEqualToString:@"location"];
                if (!self.isCurrentTrack && !hasLocation)
                    [infoSection.cells addObject:generateDataForLocationCell()];
                else if (self.isCurrentTrack && hasLocation)
                    [infoSection.cells removeObject:infoSection.cells.lastObject];

                for (OAGPXTableCellData *cellData in infoSection.cells)
                {
                    if (cellData.updateData)
                        cellData.updateData();
                }
            }
    }];

    [tableSections addObject:infoSection];

    self.tableData = tableSections;
}

- (void)generateDataForSegmentsScreen
{
    NSMutableArray<OAGPXTableSectionData *> *tableSections = [NSMutableArray array];

    NSInteger index = 0;
    for (OAGpxTrkSeg *segment in _segments)
    {
        OAGPXTrackAnalysis *analysis = [OAGPXTrackAnalysis segment:0 seg:segment];
        __block EOARouteStatisticsMode mode = EOARouteStatisticsModeAltitudeSpeed;

        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OALineChartCell getCellIdentifier] owner:self options:nil];
        OALineChartCell *cell = (OALineChartCell *) nib[0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.lineChartView.delegate = self;
        cell.separatorInset = UIEdgeInsetsMake(0, CGFLOAT_MAX, 0, 0);

        [GpxUIHelper setupGPXChartWithChartView:cell.lineChartView
                                   yLabelsCount:4
                                      topOffset:20
                                   bottomOffset:4
                            useGesturesAndScale:YES
        ];

        [_routeLineChartHelper changeChartMode:mode
                                         chart:cell.lineChartView
                                      analysis:analysis
                                      modeCell:nil];

        for (UIGestureRecognizer *recognizer in cell.lineChartView.gestureRecognizers)
        {
            if ([recognizer isKindOfClass:UIPanGestureRecognizer.class])
                [recognizer addTarget:self action:@selector(onBarChartScrolled:lineChartView:)];

            [recognizer addTarget:self action:@selector(onChartGesture:lineChartView:)];
        }

        OAGPXTableCellData *segmentCellData = index != 0 ? [OAGPXTableCellData withData:@{
                kCellKey: [NSString stringWithFormat:@"segment_%li", index],
                kCellType: [OAIconTitleValueCell getCellIdentifier],
                kCellTitle: [NSString stringWithFormat:OALocalizedString(@"segnet_num"), index],
                kCellToggle: @NO
        }] : nil;

        OAGPXTableCellData *chartCellData = [OAGPXTableCellData withData:@{
                kCellKey: [NSString stringWithFormat:@"chart_%li", index],
                kCellType: [OALineChartCell getCellIdentifier],
                kTableValues: @{
                        @"cell_value": cell,
                        @"points_value": [_routeLineChartHelper generateTrackChartPoints:cell.lineChartView]
                }
        }];
        [chartCellData setData:@{
                kTableUpdateData: ^() {
                    [_routeLineChartHelper changeChartMode:mode
                                                     chart:cell.lineChartView
                                                  analysis:analysis
                                                  modeCell:nil];
                }
        }];

        OAGPXTableCellData *statisticsCellData = [OAGPXTableCellData withData:@{
                kCellKey: [NSString stringWithFormat:@"statistics_%li", index],
                kCellType: [OAQuadItemsWithTitleDescIconCell getCellIdentifier],
                kTableValues: [self getStatisticsDataForAnalysis:analysis segment:segment mode:mode],
                kCellToggle: @((mode == EOARouteStatisticsModeAltitudeSpeed && analysis.timeSpan > 0)
                        || mode != EOARouteStatisticsModeAltitudeSpeed)
        }];
        [statisticsCellData setData:@{
                kTableUpdateData: ^() {
                    [statisticsCellData setData:@{
                            kTableValues: [self getStatisticsDataForAnalysis:analysis segment:segment mode:mode],
                            kCellToggle: @((mode == EOARouteStatisticsModeAltitudeSpeed && analysis.timeSpan > 0)
                                    || mode != EOARouteStatisticsModeAltitudeSpeed)
                    }];
                }
        }];

        OAGPXTableCellData *tabsCellData = [OAGPXTableCellData withData:@{
                kCellKey: [NSString stringWithFormat:@"tabs_%li", index],
                kCellType: [OASegmentTableViewCell getCellIdentifier]
        }];
        [tabsCellData setData:@{
                kTableUpdateData: ^() {
                    NSInteger selectedIndex = [tabsCellData.values[@"selected_index_int_value"] intValue];
                    mode = selectedIndex == 0 ? EOARouteStatisticsModeAltitudeSpeed
                            : selectedIndex == 1 ? EOARouteStatisticsModeAltitudeSlope : EOARouteStatisticsModeSpeed;

                    if (chartCellData.updateData)
                        chartCellData.updateData();

                    if (statisticsCellData.updateData)
                        statisticsCellData.updateData();
                }
        }];

        OAGPXTableCellData *buttonsCellData = [OAGPXTableCellData withData:@{
                kCellKey: [NSString stringWithFormat:@"buttons_%li", index],
                kCellType: [OARadiusCellEx getCellIdentifier],
                kTableValues: @{
                        @"left_title_string_value": OALocalizedString(@"analyze_on_map"),
                        @"right_title_string_value": OALocalizedString(@"shared_string_options"),
                        @"right_icon_string_value": @"ic_custom_overflow_menu",
                        @"left_on_button_pressed":  ^() {
                            [self openAnalysis:analysis withMode:mode];
                        },
                        @"right_on_button_pressed": ^() {
                            OAEditWaypointsGroupBottomSheetViewController *editWaypointsBottomSheet =
                                    [[OAEditWaypointsGroupBottomSheetViewController alloc] initWithSegment:segment
                                                                                                  analysis:analysis];
                            editWaypointsBottomSheet.trackMenuDelegate = self;
                            [editWaypointsBottomSheet presentInViewController:self];
                        }
                },
                kCellToggle: @(!segment.generalSegment)
        }];

        NSMutableArray<OAGPXTableCellData *> *segmentCells = [NSMutableArray array];
        if (segmentCellData != nil)
            [segmentCells addObject:segmentCellData];
        [segmentCells addObject:tabsCellData];
        [segmentCells addObject:chartCellData];
        [segmentCells addObject:statisticsCellData];
        [segmentCells addObject:buttonsCellData];

        NSMutableDictionary *values = [NSMutableDictionary dictionary];
        values[@"tab_0_string_value"] = OALocalizedString(@"shared_string_overview");
        values[@"tab_1_string_value"] = OALocalizedString(@"map_widget_altitude");
        if (analysis.isSpeedSpecified)
            values[@"tab_2_string_value"] = OALocalizedString(@"gpx_speed");
        values[@"statistics_row_int_value"] = @([segmentCells indexOfObject:statisticsCellData]);
        values[@"selected_index_int_value"] = @0;
        [tabsCellData setData:@{ kTableValues: values }];

        OAGPXTableSectionData *segmentSectionData = [OAGPXTableSectionData withData:@{ kSectionCells: segmentCells }];
        [segmentSectionData setData:@{
                kTableUpdateData: ^() {
                    if ([segmentSectionData.values[@"delete_section_bool_value"] boolValue])
                    {
                        NSMutableArray<OAGPXTableSectionData *> *newTableData = [self.tableData mutableCopy];
                        [newTableData removeObject:segmentSectionData];
                        self.tableData = newTableData;
                    }
                    else
                    {
                        for (OAGPXTableCellData *cellData in segmentSectionData.cells)
                        {
                            if (cellData.updateData)
                                cellData.updateData();
                        }
                    }
                }
        }];
        [tableSections addObject:segmentSectionData];

        cell.lineChartView.tag =
                [tableSections indexOfObject:segmentSectionData] << 10 | [segmentCells indexOfObject:chartCellData];

        index++;
    }

    self.tableData = tableSections;
}

- (NSDictionary<NSString *, NSDictionary *> *)getStatisticsDataForAnalysis:(OAGPXTrackAnalysis *)analysis
                                                                   segment:(OAGpxTrkSeg *)segment
                                                                      mode:(EOARouteStatisticsMode)mode
{
    NSMutableDictionary *titles = [NSMutableDictionary dictionary];
    NSMutableDictionary *icons = [NSMutableDictionary dictionary];
    NSMutableDictionary *descriptions = [NSMutableDictionary dictionary];

    OAGpxTrk *track;
    for (OAGpxTrk *trk in _mutableDoc.tracks)
    {
        if ([trk.segments containsObject:segment])
        {
            track = trk;
            break;
        }
    }

    switch (mode)
    {
        case EOARouteStatisticsModeAltitudeSpeed:
        {
            titles[@"top_left_title_string_value"] = OALocalizedString(@"shared_string_distance");
            titles[@"top_right_title_string_value"] = OALocalizedString(@"shared_string_time_span");
            titles[@"bottom_left_title_string_value"] = OALocalizedString(@"shared_string_start_time");
            titles[@"bottom_right_title_string_value"] = OALocalizedString(@"shared_string_end_time");

            icons[@"top_left_icon_name_string_value"] = @"ic_small_distance";
            icons[@"top_right_icon_name_string_value"] = @"ic_small_time_interval";
            icons[@"bottom_left_icon_name_string_value"] = @"ic_small_time_start";
            icons[@"bottom_right_icon_name_string_value"] = @"ic_small_time_end";

            descriptions[@"top_left_description_string_value"] = [OAOsmAndFormatter getFormattedDistance:
                    !self.gpx.joinSegments && track && track.generalTrack
                            ? analysis.totalDistanceWithoutGaps : analysis.totalDistance];

            descriptions[@"top_right_description_string_value"] = [OAOsmAndFormatter getFormattedTimeInterval:
                    !self.gpx.joinSegments && track && track.generalTrack
                            ? analysis.timeSpanWithoutGaps : analysis.timeSpan shortFormat:YES];

            NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"HH:mm, MM-dd-yy"];
            descriptions[@"bottom_left_description_string_value"] =
                    [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:analysis.startTime]];
            descriptions[@"bottom_right_description_string_value"] =
                    [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:analysis.endTime]];

            break;
        }
        case EOARouteStatisticsModeAltitudeSlope:
        {
            titles[@"top_left_title_string_value"] = OALocalizedString(@"gpx_avg_altitude");
            titles[@"top_right_title_string_value"] = OALocalizedString(@"gpx_alt_range");
            titles[@"bottom_left_title_string_value"] = OALocalizedString(@"gpx_ascent");
            titles[@"bottom_right_title_string_value"] = OALocalizedString(@"gpx_descent");

            icons[@"top_left_icon_name_string_value"] = @"ic_small_altitude_average";
            icons[@"top_right_icon_name_string_value"] = @"ic_small_altitude_range";
            icons[@"bottom_left_icon_name_string_value"] = @"ic_small_ascent";
            icons[@"bottom_right_icon_name_string_value"] = @"ic_small_descent";

            descriptions[@"top_left_description_string_value"] = [OAOsmAndFormatter getFormattedAlt:analysis.avgElevation];
            descriptions[@"top_right_description_string_value"] = [NSString stringWithFormat:@"%@ - %@",
                            [OAOsmAndFormatter getFormattedAlt:analysis.minElevation],
                            [OAOsmAndFormatter getFormattedAlt:analysis.maxElevation]];
            descriptions[@"bottom_left_description_string_value"] = [OAOsmAndFormatter getFormattedAlt:analysis.diffElevationUp];
            descriptions[@"bottom_right_description_string_value"] = [OAOsmAndFormatter getFormattedAlt:analysis.diffElevationDown];

            break;
        }
        case EOARouteStatisticsModeSpeed:
        {
            titles[@"top_left_title_string_value"] = OALocalizedString(@"gpx_average_speed");
            titles[@"top_right_title_string_value"] = OALocalizedString(@"gpx_max_speed");
            titles[@"bottom_left_title_string_value"] = OALocalizedString(@"shared_string_time_moving");
            titles[@"bottom_right_title_string_value"] = OALocalizedString(@"distance_moving");

            icons[@"top_left_icon_name_string_value"] = @"ic_small_speed";
            icons[@"top_right_icon_name_string_value"] = @"ic_small_max_speed";
            icons[@"bottom_left_icon_name_string_value"] = @"ic_small_time_start";
            icons[@"bottom_right_icon_name_string_value"] = @"ic_small_time_end";

            descriptions[@"top_left_description_string_value"] = [OAOsmAndFormatter getFormattedSpeed:analysis.avgSpeed];
            descriptions[@"top_right_description_string_value"] = [OAOsmAndFormatter getFormattedSpeed:analysis.maxSpeed];

            descriptions[@"bottom_left_description_string_value"] = [OAOsmAndFormatter getFormattedTimeInterval:
                    !self.gpx.joinSegments && track && track.generalTrack ? analysis.timeSpanWithoutGaps : analysis.timeSpan
                                                                    shortFormat:YES];
            descriptions[@"bottom_right_description_string_value"] = [OAOsmAndFormatter getFormattedDistance:
                    !self.gpx.joinSegments && track && track.generalTrack
                            ? analysis.totalDistanceWithoutGaps : analysis.totalDistance];

            break;
        }
        default:
            return @{ };
    }

    return @{
            @"titles": titles,
            @"icons": icons,
            @"descriptions": descriptions
    };
}

- (void)generateDataForPointsScreen
{
    NSMutableArray<OAGPXTableSectionData *> *tableSections = [NSMutableArray array];

    for (NSString *groupName in _waypointGroups.keyEnumerator)
    {
        __block BOOL isHidden = [self.gpx.hiddenGroups containsObject:[self isDefaultGroup:groupName] ? @"" : groupName];
        __block UIImage *leftIcon = [UIImage templateImageNamed:
                isHidden ? @"ic_custom_folder_hidden" : @"ic_custom_folder"];
        __block UIColor *tintColor = isHidden ? UIColorFromRGB(color_footer_icon_gray)
                : UIColorFromRGB([self getWaypointsGroupColor:groupName]);
        OAGPXTableCellData *groupCellData = [OAGPXTableCellData withData:@{
                kCellKey: [NSString stringWithFormat:@"group_%@", groupName],
                kCellType: [OASelectionCollapsableCell getCellIdentifier],
                kCellTitle: groupName,
                kCellLeftIcon: leftIcon,
                kCellRightIconName: @"ic_custom_arrow_up",
                kCellToggle: @YES,
                kCellTintColor: @([OAUtilities colorToNumber:tintColor]),
                kCellButtonPressed: ^() {
                    [self openWaypointsGroupOptionsScreen:groupName];
                }
        }];

        __block NSString *currentGroupName = groupName;
        __block BOOL updated = NO;
        void (^newGroupName) (void) = ^{
            if (_waypointGroupsOldNewNames && [_waypointGroupsOldNewNames.allKeys containsObject:currentGroupName])
            {
                currentGroupName = _waypointGroupsOldNewNames[currentGroupName];
                [_waypointGroupsOldNewNames removeObjectForKey:groupCellData.title];
                updated = YES;
            }
        };

        [groupCellData setData:@{
                kTableUpdateData: ^() {
                    newGroupName();
                    isHidden = [self.gpx.hiddenGroups containsObject:[self isDefaultGroup:currentGroupName] ? @"" : currentGroupName];
                    leftIcon = [UIImage templateImageNamed:
                            isHidden ? @"ic_custom_folder_hidden" : @"ic_custom_folder"];
                    tintColor = isHidden ? UIColorFromRGB(color_footer_icon_gray)
                            : UIColorFromRGB([self getWaypointsGroupColor:currentGroupName]);
                    [groupCellData setData:@{
                            kCellKey: [NSString stringWithFormat:@"group_%@", currentGroupName],
                            kCellTitle: currentGroupName,
                            kCellLeftIcon: leftIcon,
                            kCellRightIconName: groupCellData.toggle ? @"ic_custom_arrow_up" : @"ic_custom_arrow_right",
                            kCellTintColor: @([OAUtilities colorToNumber:tintColor]),
                            kCellButtonPressed: ^() {
                                [self openWaypointsGroupOptionsScreen:currentGroupName];
                            }
                    }];
                }
        }];

        NSArray<OAGPXTableCellData *> * (^generateDataForWaypointCells) (void) = ^{
            NSMutableArray<OAGPXTableCellData *> *waypointsCells = [NSMutableArray array];
            if (groupCellData.toggle)
            {
                NSArray<OAGpxWptItem *> *waypoints = _waypointGroups[currentGroupName];

                for (OAGpxWptItem *waypoint in waypoints)
                {
                    NSInteger waypointIndex = [waypoints indexOfObject:waypoint];
                    __block OAGpxWptItem *currentWaypoint = waypoint;
                    void (^newWaypoint) (void) = ^{
                        if (updated)
                        {
                            currentWaypoint = _waypointGroups[currentGroupName][waypointIndex];
                            updated = NO;
                        }
                    };
                    newWaypoint();

                    CLLocationCoordinate2D gpxLocation = self.doc.bounds.center;
                    OAWorldRegion *worldRegion = gpxLocation.latitude != DBL_MAX
                            ? [_app.worldRegion findAtLat:gpxLocation.latitude lon:gpxLocation.longitude] : nil;

                    OAGPXTableCellData *waypointCellData = [OAGPXTableCellData withData:@{
                            kCellKey: [NSString stringWithFormat:@"waypoint_%@", currentWaypoint.point.name],
                            kCellType: [OAPointWithRegionTableViewCell getCellIdentifier],
                            kTableValues: @{
                                    @"string_value_distance": currentWaypoint.distance
                                            ? currentWaypoint.distance : [OAOsmAndFormatter getFormattedDistance:0],
                                    @"float_value_direction": @(currentWaypoint.direction)
                            },
                            kCellTitle: currentWaypoint.point.name,
                            kCellDesc: worldRegion != nil
                                    ? (worldRegion.localizedName ? worldRegion.localizedName : worldRegion.nativeName)
                                    : @"",
                            kCellLeftIcon: [currentWaypoint getCompositeIcon]
                    }];

                    [waypointCellData setData:@{
                            kTableUpdateData: ^() {
                                newWaypoint();
                                CLLocation *newLocation = _app.locationServices.lastKnownLocation;
                                if (newLocation)
                                {
                                    CLLocationDirection newHeading = _app.locationServices.lastKnownHeading;
                                    CLLocationDirection newDirection =
                                            (newLocation.speed >= 1 /* 3.7 km/h */ && newLocation.course >= 0.0f)
                                                    ? newLocation.course : newHeading;

                                    OsmAnd::LatLon latLon(currentWaypoint.point.position.latitude, currentWaypoint.point.position.longitude);
                                    const auto &wptPosition31 = OsmAnd::Utilities::convertLatLonTo31(latLon);
                                    const auto wptLon = OsmAnd::Utilities::get31LongitudeX(wptPosition31.x);
                                    const auto wptLat = OsmAnd::Utilities::get31LatitudeY(wptPosition31.y);

                                    const auto distance = OsmAnd::Utilities::distance(
                                            newLocation.coordinate.longitude,
                                            newLocation.coordinate.latitude,
                                            wptLon,
                                            wptLat
                                    );

                                    currentWaypoint.distance = [OAOsmAndFormatter getFormattedDistance:distance];
                                    currentWaypoint.distanceMeters = distance;
                                    CGFloat itemDirection = [_app.locationServices radiusFromBearingToLocation:[
                                            [CLLocation alloc] initWithLatitude:wptLat longitude:wptLon]];
                                    currentWaypoint.direction =
                                            OsmAnd::Utilities::normalizedAngleDegrees(itemDirection - newDirection) * (M_PI / 180);
                                }

                                [waypointCellData setData:@{
                                        kTableValues: @{
                                                @"string_value_distance": currentWaypoint.distance
                                                        ? currentWaypoint.distance : [OAOsmAndFormatter getFormattedDistance:0],
                                                @"float_value_direction": @(currentWaypoint.direction)
                                        },
                                        kCellTitle: currentWaypoint.point.name,
                                        kCellLeftIcon: [currentWaypoint getCompositeIcon]
                                }];
                            }
                    }];
                    [waypointsCells addObject:waypointCellData];
                }
            }
            return waypointsCells;
        };

        OAGPXTableSectionData *waypointsSection = [OAGPXTableSectionData withData:@{
                kSectionCells: [@[groupCellData] arrayByAddingObjectsFromArray:generateDataForWaypointCells()],
        }];
        [tableSections addObject:waypointsSection];

        [waypointsSection setData:@{
                kTableUpdateData: ^() {
                    if (groupCellData.updateData)
                        groupCellData.updateData();
                    NSInteger sectionIndex = [_waypointGroups.allKeys indexOfObject:currentGroupName];

                    BOOL isDuplicate = [waypointsSection.values[@"is_duplicate_bool_value"] boolValue];
                    if (!isDuplicate && sectionIndex != NSNotFound)
                    {
                        if (updated || waypointsSection.cells.count != [self getWaypointsCount:currentGroupName] + 1
                                || !groupCellData.toggle)
                        {
                            [waypointsSection setData:@{
                                    kSectionCells: [@[groupCellData] arrayByAddingObjectsFromArray:generateDataForWaypointCells()]
                            }];
                        }
                        else
                        {
                            for (OAGPXTableCellData *cellData in waypointsSection.cells)
                            {
                                if (groupCellData != cellData && cellData.updateData)
                                    cellData.updateData();
                            }
                        }
                    }

                    if (isDuplicate || (waypointsSection.cells.count == 1 && [self getWaypointsCount:currentGroupName] == 0)
                            || sectionIndex == NSNotFound)
                    {
                        NSMutableArray<OAGPXTableSectionData *> *newTableData = [self.tableData mutableCopy];
                        [newTableData removeObject:waypointsSection];
                        self.tableData = newTableData;
                    }
                }
        }];
    }

    OAGPXTableCellData *deleteWaypoints = [OAGPXTableCellData withData:@{
            kCellKey: @"delete_waypoints",
            kCellType: [OAIconTitleValueCell getCellIdentifier],
            kCellTitle: OALocalizedString(@"delete_waypoints"),
            kCellRightIconName: @"ic_custom_remove_outlined",
            kCellToggle: @([self hasWaypoints]),
            kCellTintColor: [self hasWaypoints] ? @color_primary_purple : @unselected_tab_icon
    }];

    [deleteWaypoints setData:@{
            kTableUpdateData: ^() {
                [deleteWaypoints setData:@{
                        kCellToggle: @([self hasWaypoints]),
                        kCellTintColor: [self hasWaypoints] ? @color_primary_purple : @unselected_tab_icon
                }];
            }
    }];

    OAGPXTableSectionData *actionsSection = [OAGPXTableSectionData withData:@{
            kSectionCells: @[
                    [OAGPXTableCellData withData:@{
                            kCellKey: @"add_waypoint",
                            kCellType: [OAIconTitleValueCell getCellIdentifier],
                            kCellTitle: OALocalizedString(@"add_waypoint"),
                            kCellRightIconName: @"ic_custom_add_gpx_waypoint",
                            kCellToggle: @YES,
                            kCellTintColor: @color_primary_purple
                    }],
                    deleteWaypoints
            ],
            kSectionHeader: OALocalizedString(@"actions")
    }];

    [actionsSection setData:@{
            kTableUpdateData: ^() {
                for (OAGPXTableCellData *cellData in actionsSection.cells)
                {
                    if (cellData.updateData)
                        cellData.updateData();
                }
            }
    }];

    [tableSections addObject:actionsSection];

    self.tableData = tableSections;
}

- (void)generateDataForActionsScreen
{
    NSMutableArray<OAGPXTableSectionData *> *tableSections = [NSMutableArray array];

    NSMutableArray<OAGPXTableCellData *> *controlCells = [NSMutableArray array];

    OAGPXTableCellData *showOnMap = [OAGPXTableCellData withData:@{
            kCellKey: @"control_show_on_map",
            kCellType: [OATitleSwitchRoundCell getCellIdentifier],
            kTableValues: @{ @"bool_value": @(self.isShown) },
            kCellTitle: OALocalizedString(@"map_settings_show"),
            kCellOnSwitch: ^(BOOL toggle) { [self onShowHidePressed:nil]; },
            kCellIsOn: ^() { return self.isShown; }
    }];

    [showOnMap setData:@{
            kTableUpdateData: ^() {
                [showOnMap setData:@{ kTableValues: @{ @"bool_value": @(self.isShown) } }];
            }
    }];
    [controlCells addObject:showOnMap];

    [controlCells addObject:[OAGPXTableCellData withData:@{
            kCellKey: @"control_appearance",
            kCellType: [OATitleIconRoundCell getCellIdentifier],
            kCellRightIconName: @"ic_custom_appearance",
            kCellTitle: OALocalizedString(@"map_settings_appearance")
    }]];

    [controlCells addObject:[OAGPXTableCellData withData:@{
            kCellKey: @"control_navigation",
            kCellType: [OATitleIconRoundCell getCellIdentifier],
            kCellRightIconName: @"ic_custom_navigation",
            kCellTitle: OALocalizedString(@"routing_settings")
    }]];

    OAGPXTableSectionData *controlsSection = [OAGPXTableSectionData withData:@{ kSectionCells: controlCells }];
    [controlsSection setData:@{
            kTableUpdateData: ^() {
                for (OAGPXTableCellData *cellData in controlsSection.cells)
                {
                    if (cellData.updateData)
                        cellData.updateData();
                }
            }
    }];

    [tableSections addObject:controlsSection];
    [tableSections addObject:[OAGPXTableSectionData withData:@{
            kSectionCells: @[
                    [OAGPXTableCellData withData:@{
                            kCellKey: @"analyze",
                            kCellType: [OATitleIconRoundCell getCellIdentifier],
                            kCellRightIconName: @"ic_custom_appearance",
                            kCellTitle: OALocalizedString(@"analyze_on_map")
                    }]
            ]
    }]];
    [tableSections addObject:[OAGPXTableSectionData withData:@{
            kSectionCells: @[
                    [OAGPXTableCellData withData:@{
                            kCellKey: @"share",
                            kCellType: [OATitleIconRoundCell getCellIdentifier],
                            kCellRightIconName: @"ic_custom_export",
                            kCellTitle: OALocalizedString(@"ctx_mnu_share")
                    }]
            ]
    }]];
    [tableSections addObject:[OAGPXTableSectionData withData:@{
            kSectionCells: @[
                    [OAGPXTableCellData withData:@{
                            kCellKey: @"edit",
                            kCellType: [OATitleIconRoundCell getCellIdentifier],
                            kCellRightIconName: @"ic_custom_trip_edit",
                            kCellTitle: OALocalizedString(@"edit_track")
                    }],
                    [OAGPXTableCellData withData:@{
                            kCellKey: @"edit_create_duplicate",
                            kCellType: [OATitleIconRoundCell getCellIdentifier],
                            kCellRightIconName: @"ic_custom_copy",
                            kCellTitle: OALocalizedString(@"duplicate_track")
                    }]
            ]
    }]];

    NSMutableArray<OAGPXTableCellData *> *changeCells = [NSMutableArray array];

    [changeCells addObject:[OAGPXTableCellData withData:@{
            kCellKey: @"change_rename",
            kCellType: [OATitleIconRoundCell getCellIdentifier],
            kCellRightIconName: @"ic_custom_edit",
            kCellTitle: OALocalizedString(@"gpx_rename_q")
    }]];

    OAGPXTableCellData *move = [OAGPXTableCellData withData:@{
            kCellKey: @"change_move",
            kCellType: [OATitleDescriptionIconRoundCell getCellIdentifier],
            kCellDesc: [[OAGPXDatabase sharedDb] getFileDir:self.gpx.gpxFilePath].capitalizedString,
            kCellRightIconName: @"ic_custom_folder_move",
            kCellTitle: OALocalizedString(@"plan_route_change_folder")
    }];

    [move setData:@{
            kTableUpdateData: ^() {
                [move setData:@{ kCellDesc: [[OAGPXDatabase sharedDb] getFileDir:self.gpx.gpxFilePath].capitalizedString }];
            }
    }];
    [changeCells addObject:move];

    OAGPXTableSectionData *changeSection = [OAGPXTableSectionData withData:@{ kSectionCells: changeCells }];
    [changeSection setData:@{
            kTableUpdateData: ^() {
                for (OAGPXTableCellData *cellData in changeSection.cells)
                {
                    if (cellData.updateData)
                        cellData.updateData();
                }
            }
    }];
    [tableSections addObject:changeSection];

    [tableSections addObject:[OAGPXTableSectionData withData:@{
            kSectionCells: @[
                    [OAGPXTableCellData withData:@{
                            kCellKey: @"delete",
                            kCellType: [OATitleIconRoundCell getCellIdentifier],
                            kCellRightIconName: @"ic_custom_remove_outlined",
                            kCellTitle: OALocalizedString(@"shared_string_delete"),
                            kCellTintColor: @color_primary_red
                    }]
            ]
    }]];

    self.tableData = tableSections;
}

- (void)generateGpxBlockStatistics
{
    NSMutableArray *statistics = [NSMutableArray array];
    if (self.analysis)
    {
        BOOL withoutGaps = !self.gpx.joinSegments && (self.isCurrentTrack
                ? (self.doc.tracks.count == 0 || self.doc.tracks.firstObject.generalTrack)
                : (self.doc.tracks.count > 0 && self.doc.tracks.firstObject.generalTrack));

        if (self.analysis.totalDistance != 0)
        {
            float totalDistance = withoutGaps ? self.analysis.totalDistanceWithoutGaps : self.analysis.totalDistance;
            [statistics addObject:@{
                    @"title": OALocalizedString(@"shared_string_distance"),
                    @"value": [OAOsmAndFormatter getFormattedDistance:totalDistance],
                    @"type": @(EOARouteStatisticsModeAltitude),
                    @"icon": @"ic_small_distance@2x"
            }];
        }

        if (self.analysis.hasElevationData)
        {
            [statistics addObject:@{
                    @"title": OALocalizedString(@"gpx_ascent"),
                    @"value": [OAOsmAndFormatter getFormattedAlt:self.analysis.diffElevationUp],
                    @"type": @(EOARouteStatisticsModeSlope),
                    @"icon": @"ic_small_ascent"
            }];
            [statistics addObject:@{
                    @"title": OALocalizedString(@"gpx_descent"),
                    @"value": [OAOsmAndFormatter getFormattedAlt:self.analysis.diffElevationDown],
                    @"icon": @"ic_small_descent"
            }];
            [statistics addObject:@{
                    @"title": OALocalizedString(@"gpx_alt_range"),
                    @"value": [NSString stringWithFormat:@"%@ - %@",
                                                         [OAOsmAndFormatter getFormattedAlt:self.analysis.minElevation],
                                                         [OAOsmAndFormatter getFormattedAlt:self.analysis.maxElevation]],
                    @"type": @(EOARouteStatisticsModeAltitude),
                    @"icon": @"ic_small_altitude_range"
            }];
        }

        if ([self.analysis isSpeedSpecified])
        {
            [statistics addObject:@{
                    @"title": OALocalizedString(@"gpx_average_speed"),
                    @"value": [OAOsmAndFormatter getFormattedSpeed:self.analysis.avgSpeed],
                    @"type": @(EOARouteStatisticsModeSpeed),
                    @"icon": @"ic_small_speed"
            }];
            [statistics addObject:@{
                    @"title": OALocalizedString(@"gpx_max_speed"),
                    @"value": [OAOsmAndFormatter getFormattedSpeed:self.analysis.maxSpeed],
                    @"type": @(EOARouteStatisticsModeSpeed),
                    @"icon": @"ic_small_max_speed"
            }];
        }

        if (self.analysis.hasSpeedData)
        {
            long timeSpan = withoutGaps ? self.analysis.timeSpanWithoutGaps : self.analysis.timeSpan;
            [statistics addObject:@{
                    @"title": OALocalizedString(@"total_time"),
                    @"value": [OAOsmAndFormatter getFormattedTimeInterval:timeSpan shortFormat:YES],
                    @"type": @(EOARouteStatisticsModeSpeed),
                    @"icon": @"ic_small_time_interval"
            }];
        }

        if (self.analysis.isTimeMoving)
        {
            long timeMoving = withoutGaps ? self.analysis.timeMovingWithoutGaps : self.analysis.timeMoving;
            [statistics addObject:@{
                    @"title": OALocalizedString(@"moving_time"),
                    @"value": [OAOsmAndFormatter getFormattedTimeInterval:timeMoving shortFormat:YES],
                    @"type": @(EOARouteStatisticsModeSpeed),
                    @"icon": @"ic_small_time_moving"
            }];
        }
    }
    [_headerView setCollection:statistics];
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

        [self hide:YES duration:.2 onComplete:nil];
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
    OATrackMenuViewControllerState *state = [[OATrackMenuViewControllerState alloc] init];
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

- (void)stopLocationServices
{
    if (_locationServicesUpdateObserver)
    {
        [_locationServicesUpdateObserver detach];
        _locationServicesUpdateObserver = nil;
    }
}

- (void)updateGpxData
{
    [super updateGpxData];

    _mutableDoc = [[OAGPXMutableDocument alloc] initWithGpxFile:
            [(_app ? _app : [OsmAndApp instance]).gpxPath stringByAppendingPathComponent:self.gpx.gpxFilePath]];
    _segments = [_mutableDoc && [_mutableDoc getGeneralSegment] ? @[_mutableDoc.generalSegment] : @[]
            arrayByAddingObjectsFromArray:[_mutableDoc getNonEmptyTrkSegments:NO]];

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

    _waypointGroups = waypointGroups;
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
            for (OAGPXTableSectionData *sectionData in self.tableData)
            {
                if (sectionData.updateData)
                    sectionData.updateData();
            }
            [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows] withRowAnimation:UITableViewRowAnimationNone];
        });
    }
}

- (BOOL)hasWaypoints
{
    return _waypointGroups.allKeys.count > 0;
}

- (void)syncVisibleCharts:(LineChartView *)chartView
{
    for (OAGPXTableSectionData *sectionData in self.tableData)
    {
        for (OAGPXTableCellData *cellData in sectionData.cells)
        {
            if ([cellData.type isEqualToString:[OALineChartCell getCellIdentifier]])
            {
                OALineChartCell *chartCell = cellData.values[@"cell_value"];
                if (chartCell)
                    [chartCell.lineChartView.viewPortHandler refreshWithNewMatrix:chartView.viewPortHandler.touchMatrix chart:chartCell.lineChartView invalidate:YES];
            }
        }
    }
}

- (CGFloat)heightForRow:(NSIndexPath *)indexPath
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

- (double)getRoundedDouble:(double)toRound
{
    return floorf(toRound * 100 + 0.5) / 100;
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

- (void)editSegment
{
    [self hide:YES duration:.2 onComplete:^{
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
                    OAGPXTableSectionData *sectionData = self.tableData[segmentIndex];
                    [sectionData setData:@{kTableValues: @{@"delete_section_bool_value": @YES}}];
                    if (sectionData.updateData)
                        sectionData.updateData();

                    [self.tableView beginUpdates];
                    [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:segmentIndex]
                                  withRowAnimation:UITableViewRowAnimationNone];
                    [self.tableView endUpdates];
                }

                [self setupDescription];
                if (_headerView)
                    [_headerView setDescription:_description];
            }
        }
    }
}

- (void)refreshWaypoints
{
    [self updateGpxData];
    for (OAGPXTableSectionData *sectionData in self.tableData)
    {
        if (sectionData.updateData)
            sectionData.updateData();
    }
    [self.tableView reloadData];

    [self setupDescription];
    if (_headerView)
        [_headerView setDescription:_description];
}

- (void)refreshLocationServices
{
    if (_selectedTab == EOATrackMenuHudPointsTab)
    {
        if ([self hasWaypoints])
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
                : waypoint.point.color ? [OAUtilities colorFromString:waypoint.point.color] : nil;
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
    OAGPXTableSectionData *groupSection = self.tableData[groupIndex];
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
        OAGPXTableSectionData *sectionToDelete = self.tableData[existGroupIndex];
        [sectionToDelete setData:@{ kTableValues: @{@"is_duplicate_bool_value": @YES } }];
    }
    [self refreshWaypoints];
}

- (void)openConfirmDeleteWaypointsScreen:(NSString *)groupName
{
    OADeleteWaypointsGroupBottomSheetViewController *deleteWaypointsGroupBottomSheet =
            [[OADeleteWaypointsGroupBottomSheetViewController alloc] initWithGroupName:groupName];
    deleteWaypointsGroupBottomSheet.trackMenuDelegate = self;
    [deleteWaypointsGroupBottomSheet presentInViewController:self];
}

- (void)openWaypointsGroupOptionsScreen:(NSString *)groupName
{
    [self stopLocationServices];

    OAEditWaypointsGroupBottomSheetViewController *editWaypointsBottomSheet =
            [[OAEditWaypointsGroupBottomSheetViewController alloc] initWithWaypointsGroupName:groupName];
    editWaypointsBottomSheet.trackMenuDelegate = self;
    [editWaypointsBottomSheet presentInViewController:self];
}

- (NSString *)checkGroupName:(NSString *)groupName
{
    return !groupName || groupName.length == 0 ? OALocalizedString(@"shared_string_gpx_points") : groupName;
}

- (BOOL)isDefaultGroup:(NSString *)groupName
{
    return [groupName isEqualToString:OALocalizedString(@"shared_string_gpx_points")];
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

        [self setupTableView];
        [self setupDescription];
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

#pragma mark - Action buttons pressed

- (void)onShowHidePressed:(id)sender
{
    if (self.isShown)
        [self.settings hideGpx:@[self.gpx.gpxFilePath] update:YES];
    else
        [self.settings showGpx:@[self.gpx.gpxFilePath] update:YES];

    self.isShown = !self.isShown;

    [_headerView.showHideButton setTitle:self.isShown ? OALocalizedString(@"poi_hide") : OALocalizedString(@"sett_show")
                                forState:UIControlStateNormal];
    [_headerView.showHideButton setImage:[UIImage templateImageNamed:self.isShown ? @"ic_custom_hide" : @"ic_custom_show"]
                                forState:UIControlStateNormal];
}

- (void)onAppearancePressed:(id)sender
{
    [self hide:YES duration:.2 onComplete:^{
        [self.mapPanelViewController openTargetViewWithGPX:self.gpx
                                              trackHudMode:EOATrackAppearanceHudMode
                                                     state:[self getCurrentState]];
    }];
}

- (void)onExportPressed:(id)sender
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

- (void)onNavigationPressed:(id)sender
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
        [self hide:YES duration:.2 onComplete:nil];
    }
}

#pragma mark - OASelectTrackFolderDelegate

- (void)onFolderSelected:(NSString *)selectedFolderName
{
    [self copyGPXToNewFolder:selectedFolderName renameToNewName:nil deleteOriginalFile:YES];
    if (_selectedTab == EOATrackMenuHudActionsTab)
    {
        self.tableData[kActionsSection].cells[kActionMoveCell].updateData();
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
    [self hide:YES duration:.2 onComplete:nil];
}

#pragma - mark ChartViewDelegate

- (void)chartValueNothingSelected:(ChartViewBase *)chartView
{
    [self.mapViewController.mapLayers.routeMapLayer hideCurrentStatisticsLocation];
}

- (void)chartValueSelected:(ChartViewBase *)chartView
                     entry:(ChartDataEntry *)entry
                 highlight:(ChartHighlight *)highlight
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:chartView.tag & 0x3FF inSection:chartView.tag >> 10];
    OAGPXTableCellData *cellData = [self getCellData:indexPath];

    [_routeLineChartHelper refreshHighlightOnMap:NO
                                   lineChartView:(LineChartView *) chartView
                                trackChartPoints:cellData.values[@"points_value"]];
}

- (void)chartScaled:(ChartViewBase *)chartView scaleX:(CGFloat)scaleX scaleY:(CGFloat)scaleY
{
        [self syncVisibleCharts:(LineChartView *) chartView];
}

- (void)chartTranslated:(ChartViewBase *)chartView dX:(CGFloat)dX dY:(CGFloat)dY
{
    LineChartView *lineChartView = (LineChartView *) chartView;
    _hasTranslated = YES;
    if (_highlightDrawX != -1)
    {
        ChartHighlight *h = [lineChartView getHighlightByTouchPoint:CGPointMake(_highlightDrawX, 0.)];
        if (h != nil)
            [lineChartView highlightValue:h callDelegate:true];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.tableData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableData[section].cells.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.tableData[section].header;
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
    return [self heightForRow:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (_selectedTab == EOATrackMenuHudOverviewTab
            || (_selectedTab == EOATrackMenuHudPointsTab && section == self.tableData.count - 1))
        return 56.;
    else if (_selectedTab == EOATrackMenuHudSegmentsTab && section != 0)
        return 36.;
    else if (_selectedTab == EOATrackMenuHudPointsTab && section != 0)
        return 14.;
    else if (_selectedTab == EOATrackMenuHudActionsTab)
        return 20.;
    else
        return 0.01;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAGPXTableCellData *cellData = [self getCellData:indexPath];

    if ([cellData.key isEqualToString:@"full_description"])
    {
        OATrackMenuDescriptionViewController *descriptionViewController =
                [[OATrackMenuDescriptionViewController alloc] initWithGpxDoc:self.doc gpx:self.gpx];
        [self.navigationController pushViewController:descriptionViewController animated:YES];
    }
    else if ([cellData.key hasPrefix:@"waypoint_"])
    {
        [self hide:YES duration:.2 onComplete:^{
            [self.mapPanelViewController openTargetViewWithWpt:_waypointGroups[_waypointGroups.allKeys[indexPath.section]][indexPath.row - 1] pushed:NO];
        }];
    }
    else if ([cellData.key isEqualToString:@"add_waypoint"])
    {
        [self hide:YES duration:.2 onComplete:^{
            [self.mapPanelViewController openTargetViewWithNewGpxWptMovableTarget:self.gpx
                                                                 menuControlState:[self getCurrentState]];
        }];
    }
    else if ([cellData.key isEqualToString:@"delete_waypoints"])
    {
        if (cellData.toggle)
        {
            [self stopLocationServices];

            NSMutableArray<OAGPXTableSectionData *> *sectionsData = [NSMutableArray array];
            for (OAGPXTableSectionData *sectionData in self.tableData)
            {
                if (![sectionData.header isEqualToString:OALocalizedString(@"actions")])
                    [sectionsData addObject:sectionData];
            }
            OADeleteWaypointsViewController *deleteWaypointsViewController =
                    [[OADeleteWaypointsViewController alloc] initWithSectionsData:sectionsData
                                                                   waypointGroups:_waypointGroups
                                                                   isCurrentTrack:self.isCurrentTrack
                                                                      gpxFilePath:self.gpx.gpxFilePath];
            deleteWaypointsViewController.trackMenuDelegate = self;
            [self presentViewController:deleteWaypointsViewController animated:YES completion:nil];
        }
    }
    else if ([cellData.key isEqualToString:@"control_appearance"])
    {
        [self onAppearancePressed:nil];
    }
    else if ([cellData.key isEqualToString:@"control_navigation"])
    {
        [self onNavigationPressed:nil];
    }
    else if ([cellData.key isEqualToString:@"analyze"])
    {
        [self openAnalysis:EOARouteStatisticsModeAltitudeSlope];
    }
    else if ([cellData.key isEqualToString:@"share"])
    {
        [self onExportPressed:nil];
    }
    else if ([cellData.key isEqualToString:@"edit"])
    {
        [self editSegment];
    }
    else if ([cellData.key isEqualToString:@"edit_create_duplicate"])
    {
        OASaveTrackViewController *saveTrackViewController = [[OASaveTrackViewController alloc]
                initWithFileName:[self.gpx.gpxFilePath.lastPathComponent.stringByDeletingPathExtension stringByAppendingString:@"_copy"]
                        filePath:self.gpx.gpxFilePath
                       showOnMap:YES
                 simplifiedTrack:NO];

        saveTrackViewController.delegate = self;
        [self presentViewController:saveTrackViewController animated:YES completion:nil];
    }
    else if ([cellData.key isEqualToString:@"change_rename"])
    {
        [self showAlertRenameTrack];
    }
    else if ([cellData.key isEqualToString:@"change_move"])
    {
        OASelectTrackFolderViewController *selectFolderView = [[OASelectTrackFolderViewController alloc] initWithGPX:self.gpx];
        selectFolderView.delegate = self;
        [self presentViewController:selectFolderView animated:YES completion:nil];
    }
    else if ([cellData.key isEqualToString:@"delete"])
    {
        [self showAlertDeleteTrack];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - selectors

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
    if (self.tableData[indexPath.section].updateData)
        self.tableData[indexPath.section].updateData();

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

    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[cellData.values[@"statistics_row_int_value"] intValue]
                                                                inSection:indexPath.section]]
                          withRowAnimation:UITableViewRowAnimationNone];
}

- (void)onBarChartScrolled:(UIPanGestureRecognizer *)recognizer
             lineChartView:(LineChartView *)lineChartView
{
    if (recognizer.state == UIGestureRecognizerStateChanged)
    {
        if (lineChartView.lowestVisibleX > 0.1
                && [self getRoundedDouble:lineChartView.highestVisibleX] != [self getRoundedDouble:lineChartView.chartXMax])
        {
            _lastTranslation = [recognizer translationInView:lineChartView];
            return;
        }

        ChartHighlight *lastHighlighted = lineChartView.lastHighlighted;
        CGPoint touchPoint = [recognizer locationInView:lineChartView];
        CGPoint translation = [recognizer translationInView:lineChartView];
        ChartHighlight *h = [lineChartView getHighlightByTouchPoint:CGPointMake(lineChartView.isFullyZoomedOut
                ? touchPoint.x : _highlightDrawX + (_lastTranslation.x - translation.x), 0.)];

        if (h != lastHighlighted)
        {
            lineChartView.lastHighlighted = h;
            [lineChartView highlightValue:h callDelegate:YES];
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        _lastTranslation = CGPointZero;
        if (lineChartView.highlighted.count > 0)
            _highlightDrawX = lineChartView.highlighted.firstObject.drawX;
    }
}

- (void)onChartGesture:(UIGestureRecognizer *)recognizer
         lineChartView:(LineChartView *)lineChartView
{
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        _hasTranslated = NO;
        if (lineChartView.highlighted.count > 0)
            _highlightDrawX = lineChartView.highlighted.firstObject.drawX;
        else
            _highlightDrawX = -1;
    }
    else if (([recognizer isKindOfClass:UIPinchGestureRecognizer.class] ||
            ([recognizer isKindOfClass:UITapGestureRecognizer.class]
                    && (((UITapGestureRecognizer *) recognizer).nsuiNumberOfTapsRequired == 2)))
            && recognizer.state == UIGestureRecognizerStateEnded)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:lineChartView.tag & 0x3FF inSection:lineChartView.tag >> 10];
        OAGPXTableCellData *cellData = [self getCellData:indexPath];

        [_routeLineChartHelper refreshHighlightOnMap:YES
                                           lineChartView:lineChartView
                                        trackChartPoints:cellData.values[@"points_value"]];
    }
}

@end
