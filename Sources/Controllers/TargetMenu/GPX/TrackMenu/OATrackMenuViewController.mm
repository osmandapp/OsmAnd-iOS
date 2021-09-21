//
//  OATrackMenuViewController.mm
//  OsmAnd
//
//  Created by Skalii on 10.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OATrackMenuViewController.h"
#import "OARootViewController.h"
#import "OASaveTrackViewController.h"
#import "OAEditGPXColorViewController.h"
#import "OATrackSegmentsViewController.h"
#import "OAMapHudViewController.h"
#import "OARouteDetailsViewController.h"
#import "OAMapRendererView.h"
#import "OATrackMenuHeaderView.h"
#import "OATabBar.h"
#import "OAIconTitleValueCell.h"
#import "Localization.h"
#import "OAColors.h"
#import "OARoutingHelper.h"
#import "OATargetPointsHelper.h"
#import "OASelectedGPXHelper.h"
#import "OASavingTrackHelper.h"
#import "OAGPXUIHelper.h"
#import "OAGPXDatabase.h"
#import "OAGPXLayer.h"
#import "OAGPXTrackAnalysis.h"
#import "OAGPXDocument.h"
#import "OAMapActions.h"
#import "OARouteProvider.h"
#import "OAOsmAndFormatter.h"

#define VIEWPORT_SHIFTED_SCALE 1.5f
#define VIEWPORT_NON_SHIFTED_SCALE 1.0f

#define kOverviewTabIndex 0
#define kSegmentsTabIndex 1
#define kPointsTabIndex 2
#define kActionsTabIndex 3

@interface OATrackMenuViewController() <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, UITabBarDelegate, UIDocumentInteractionControllerDelegate, OAEditGPXColorViewControllerDelegate, OASaveTrackViewControllerDelegate, OASegmentSelectionDelegate, OATrackMenuHeaderViewDelegate>

@end

@implementation OATrackMenuViewController
{
    UIDocumentInteractionController *_exportController;
    OAMapPanelViewController *_mapPanelViewController;
    OAMapViewController *_mapViewController;

    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OASavingTrackHelper *_savingHelper;
    OAGPX *_gpx;
    OAGPXDocument *_doc;
    OAGPXTrackAnalysis *_analysis;

    BOOL _isCurrentTrack;
    BOOL _isShown;
    NSString *_exportFileName;
    NSString *_exportFilePath;
    OAGPXTrackColorCollection *_gpxColorCollection;

    OATrackMenuHeaderView *_headerView;
    CGFloat _cachedYViewPort;
    NSArray<NSDictionary *> *_data;
}

- (instancetype)initWithGpx:(OAGPX *)gpx
{
    self = [super initWithNibName:@"OATrackMenuViewController" bundle:nil];
    if (self)
    {
        _gpx = gpx;
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _app = [OsmAndApp instance];
    _settings = [OAAppSettings sharedManager];
    _savingHelper = [OASavingTrackHelper sharedInstance];
    _mapPanelViewController = [OARootViewController instance].mapPanel;
    _mapViewController = _mapPanelViewController.mapViewController;
    _gpxColorCollection = [[OAGPXTrackColorCollection alloc] initWithMapViewController:_mapViewController];

    _isCurrentTrack = !_gpx || _gpx.gpxFilePath.length == 0 || _gpx.gpxFileName.length == 0;
    if (_isCurrentTrack)
    {
        if (!_gpx)
            _gpx = [_savingHelper getCurrentGPX];

        _gpx.gpxTitle = OALocalizedString(@"track_recording_name");
    }
    _doc = _isCurrentTrack ? (OAGPXDocument *) _savingHelper.currentTrack
            : [[OAGPXDocument alloc] initWithGpxFile:[_app.gpxPath stringByAppendingPathComponent:_gpx.gpxFilePath]];
    _analysis = [_doc getAnalysis:_isCurrentTrack ? 0 : (long) [[OAUtilities getFileLastModificationDate:_gpx.gpxFilePath] timeIntervalSince1970]];

    _isShown = [_settings.mapSettingVisibleGpx.get containsObject:_gpx.gpxFilePath];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    [self setupView];
    if (![self isLandscape])
        [self goExpanded];
    else
        [self goFullScreen];

    [_mapPanelViewController displayGpxOnMap:_gpx];
    [_mapPanelViewController setTopControlsVisible:NO
                              customStatusBarStyle:[OAAppSettings sharedManager].nightMode
                                      ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault];
    _cachedYViewPort = _mapViewController.mapView.viewportYScale;
    [self adjustMapViewPort];

    if (!_isShown)
        [self onShowHidePressed:nil];
}

- (void)firstShowing
{
    [self show:YES
         state:[self isLandscape] ? EOADraggableMenuStateFullScreen : EOADraggableMenuStateExpanded
    onComplete:^{
        [_mapPanelViewController targetSetBottomControlsVisible:YES
                                                     menuHeight:[self isLandscape] ? 0
                                                             : [self getViewHeight] - [OAUtilities getBottomMargin]
                                                       animated:YES];
        [self changeMapRulerPosition];
        [_mapPanelViewController.hudViewController updateMapRulerData];
    }];
}

- (void)hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete
{
    [super hide:YES duration:duration onComplete:^{
        if (onComplete)
            onComplete();

        [_mapPanelViewController.hudViewController resetToDefaultRulerLayout];
        [self restoreMapViewPort];
        [_mapPanelViewController hideScrollableHudViewController];
    }];
}

- (void)dismiss
{
    [self hide:YES duration:.2 onComplete:nil];
}

- (void)setupView
{
    [self.backButton setImage:[UIImage templateImageNamed:@"ic_custom_arrow_back"] forState:UIControlStateNormal];
    self.backButton.imageView.tintColor = UIColorFromRGB(color_primary_purple);

    [self setupTabBar];
    [self generateData];
    [self setupHeaderView];
//    [self.view bringSubviewToFront:self.tableView];
}

- (void)setupTabBar
{
    UIColor *unselectedColor = UIColorFromRGB(color_dialog_buttons_dark);
    [self.tabBarView setItems:@[
                    [[UITabBarItem alloc]
                            initWithTitle:OALocalizedString(@"shared_string_overview")
                                    image:[OAUtilities tintImageWithColor:[UIImage templateImageNamed:@"ic_custom_overview"]
                                                                    color:unselectedColor]
                                      tag:kOverviewTabIndex],
                    [[UITabBarItem alloc]
                            initWithTitle:OALocalizedString(@"track")
                                    image:[OAUtilities tintImageWithColor:[UIImage templateImageNamed:@"ic_custom_trip"]
                                                                    color:unselectedColor]
                                      tag:kSegmentsTabIndex],
                    [[UITabBarItem alloc]
                            initWithTitle:OALocalizedString(@"shared_string_gpx_points")
                                    image:[OAUtilities tintImageWithColor:[UIImage templateImageNamed:@"ic_custom_waypoint"]
                                                                    color:unselectedColor]
                                      tag:kPointsTabIndex],
                    [[UITabBarItem alloc]
                            initWithTitle:OALocalizedString(@"actions")
                                    image:[OAUtilities tintImageWithColor:[UIImage templateImageNamed:@"ic_custom_overflow_menu"]
                                                                    color:unselectedColor]
                                      tag:kActionsTabIndex]
            ]
                     animated:YES];

    self.tabBarView.selectedItem = self.tabBarView.items[kOverviewTabIndex];
    self.tabBarView.itemWidth = self.scrollableView.frame.size.width / self.tabBarView.items.count;
    self.tabBarView.delegate = self;
}

#pragma mark - OATrackMenuHeaderViewDelegate

- (void)openAnalysis:(void(^)(void))onOpen
{
    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
    targetPoint.type = OATargetRouteDetailsGraph;
    targetPoint.targetObj = @{@"gpx": _doc, @"analysis": _analysis};
    [self.navigationController pushViewController:[[OARouteDetailsViewController alloc] initWithGpxData:targetPoint.targetObj] animated:YES];

    [self dismiss];
}

- (void)setupHeaderView
{
    if (_headerView)
        [_headerView removeFromSuperview];

//    if (!_headerView)
    _headerView = [[OATrackMenuHeaderView alloc] init];
    _headerView.delegate = self;
    [_headerView.titleView setText:_isCurrentTrack ? OALocalizedString(@"track_recording_name") : [_gpx getNiceTitle]];
    _headerView.titleIconView.image = [UIImage templateImageNamed:@"ic_custom_trip"];
    _headerView.titleIconView.tintColor = UIColorFromRGB(color_icon_inactive);

    if (self.tabBarView.selectedItem.tag == kOverviewTabIndex)
    {
        //todo
        NSString *docMetadataDesc = _doc.metadata.desc;
        NSString *gpxDesc = _gpx.gpxDescription;
        NSInteger docMetadataDescLength = docMetadataDesc.length;
        NSInteger gpxDescLength = gpxDesc.length;
        [_headerView setDescription:docMetadataDesc];

        [self generateGpxBlockStatistics];

        CLLocationCoordinate2D location = _app.locationServices.lastKnownLocation.coordinate;
        CLLocationCoordinate2D gpxLocation = _doc.bounds.center;
        _headerView.directionIconView.image = [UIImage templateImageNamed:@"ic_small_direction"];
        _headerView.directionIconView.tintColor = UIColorFromRGB(color_primary_purple);
        [_headerView.directionTextView setText:[OAOsmAndFormatter getFormattedDistance:getDistance(location.latitude, location.longitude, gpxLocation.latitude, gpxLocation.longitude)]];
        _headerView.directionTextView.textColor = UIColorFromRGB(color_primary_purple);

        OAWorldRegion *worldRegion = [_app.worldRegion findAtLat:_gpx.bounds.center.latitude lon:_gpx.bounds.center.longitude];
        _headerView.regionIconView.image = [UIImage templateImageNamed:@"ic_small_map_point"];
        _headerView.regionIconView.tintColor = UIColorFromRGB(color_footer_icon_gray);
        [_headerView.regionTextView setText:worldRegion.localizedName];
        _headerView.regionTextView.textColor = UIColorFromRGB(color_text_footer);

        [_headerView.showHideButton setTitle:_isShown ? OALocalizedString(@"sett_show") : OALocalizedString(@"poi_hide") forState:UIControlStateNormal];
        [_headerView.showHideButton setImage:[UIImage templateImageNamed:_isShown ? @"ic_custom_show" : @"ic_custom_hide"] forState:UIControlStateNormal];
        [_headerView.showHideButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [_headerView.showHideButton addTarget:self action:@selector(onShowHidePressed:) forControlEvents:UIControlEventTouchUpInside];

        [_headerView.appearanceButton setTitle:OALocalizedString(@"map_settings_appearance") forState:UIControlStateNormal];
        [_headerView.appearanceButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [_headerView.appearanceButton addTarget:self action:@selector(onAppearancePressed:) forControlEvents:UIControlEventTouchUpInside];

        if (!_isCurrentTrack)
        {
            [_headerView.exportButton setTitle:OALocalizedString(@"shared_string_export") forState:UIControlStateNormal];
            [_headerView.exportButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [_headerView.exportButton addTarget:self action:@selector(onExportPressed:) forControlEvents:UIControlEventTouchUpInside];

            [_headerView.navigationButton setTitle:OALocalizedString(@"routing_settings") forState:UIControlStateNormal];
            [_headerView.navigationButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [_headerView.navigationButton addTarget:self action:@selector(onNavigationPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        else
        {
            _headerView.exportButton.hidden = YES;
            _headerView.navigationButton.hidden = YES;
        }
    }
    else
    {
        [_headerView makeOnlyHeaderAndDescription];
    }

    if ([_headerView needsUpdateConstraints])
        [_headerView updateConstraints];

    if (_headerView.collectionView.hidden
            && _headerView.locationContainerView.hidden
            && _headerView.actionButtonsContainerView.hidden)
    {
        CGRect headerFrame = _headerView.frame;
        headerFrame.size.height = _headerView.collectionView.frame.origin.y + 1;
        _headerView.frame = headerFrame;
    }
    else
    {
        if (_headerView.descriptionView.hidden)
        {
            CGRect headerFrame = _headerView.frame;
            headerFrame.size.height = _headerView.frame.size.height - _headerView.descriptionView.frame.size.height;
            _headerView.frame = headerFrame;
        }
        if (_headerView.collectionView.hidden)
        {
            CGRect headerFrame = _headerView.frame;
            headerFrame.size.height = _headerView.frame.size.height - _headerView.collectionView.frame.size.height;
            _headerView.frame = headerFrame;
        }
    }

    CGRect topHeaderContainerFrame = self.topHeaderContainerView.frame;
    topHeaderContainerFrame.size.height = _headerView.frame.size.height;
    self.topHeaderContainerView.frame = topHeaderContainerFrame;
//    if (![self.topHeaderContainerView.subviews containsObject:_headerView])
//    {
    [self.topHeaderContainerView addSubview:_headerView];
    [self.topHeaderContainerView sendSubviewToBack:_headerView];
//    }
}

- (void)generateData
{
    NSMutableArray *data = [NSMutableArray array];

    if (self.tabBarView.selectedItem.tag == kOverviewTabIndex)
    {
        NSMutableArray *infoSectionData = [NSMutableArray array];

        NSDictionary *fileAttributes = [NSFileManager.defaultManager attributesOfItemAtPath:_isCurrentTrack ? _gpx.gpxFilePath : _doc.path error:nil];
        NSString *formattedSize = [NSByteCountFormatter stringFromByteCount:fileAttributes.fileSize countStyle:NSByteCountFormatterCountStyleFile];

        [infoSectionData addObject:@{
                @"name": OALocalizedString(@"res_size"),
                @"value": formattedSize,
                @"has_options": @NO,
                @"type": [OAIconTitleValueCell getCellIdentifier],
                @"key": @"size"
        }];

        [infoSectionData addObject:@{
                @"name": OALocalizedString(@"res_created_on"),
                @"value": [NSDateFormatter localizedStringFromDate:_gpx.importDate
                                                         dateStyle:NSDateFormatterMediumStyle
                                                         timeStyle:NSDateFormatterNoStyle],
                @"has_options": @NO,
                @"type": [OAIconTitleValueCell getCellIdentifier],
                @"key": @"created_on"
        }];

        if (!_isCurrentTrack)
            [infoSectionData addObject:@{
                    @"name": OALocalizedString(@"sett_arr_loc"),
                    @"value": [[OAGPXDatabase sharedDb] getFileDir:_gpx.gpxFilePath].capitalizedString,
                    @"has_options": @NO, //@YES
                    @"type": [OAIconTitleValueCell getCellIdentifier],
                    @"key": @"location"
            }];

        /*[infoSectionData addObject:@{
                @"name": OALocalizedString(@"activity"),
                @"value": @"",
                @"has_options": @NO, //@YES
                @"type": [OAIconTitleValueCell getCellIdentifier],
                @"key": @"activity"
        }];*/

        [data addObject:@{
                @"group_name": OALocalizedString(@"shared_string_info"),
                @"cells": infoSectionData
        }];
    }

    _data = data;
}

- (void)generateGpxBlockStatistics
{
    NSMutableArray *statistics = [NSMutableArray array];
    if (_analysis)
    {
        BOOL withoutGaps = _isCurrentTrack ? _gpx.totalTracks == 0 || _doc.tracks.count == 0 || _doc.tracks.firstObject.generalTrack : NO;

        if (_analysis.totalDistance != 0)
        {
            float totalDistance = withoutGaps ? _analysis.totalDistanceWithoutGaps : _analysis.totalDistance;
            [statistics addObject:@{
                    @"title": OALocalizedString(@"gpx_distance"),
                    @"value": [OAOsmAndFormatter getFormattedDistance:totalDistance],
                    @"icon": @"ic_custom_trip" //@"ic_small_track"
            }];
        }

        if (_analysis.hasElevationData)
        {
            [statistics addObject:@{
                    @"title": OALocalizedString(@"gpx_ascent"),
                    @"value": [OAOsmAndFormatter getFormattedAlt:_analysis.diffElevationUp],
                    @"icon": @"ic_custom_trip" //@"ic_small_track"
            }];
            [statistics addObject:@{
                    @"title": OALocalizedString(@"gpx_descent"),
                    @"value": [OAOsmAndFormatter getFormattedAlt:_analysis.diffElevationDown],
                    @"icon": @"ic_custom_trip" //@"ic_small_track"
            }];
            [statistics addObject:@{
                    @"title": OALocalizedString(@"gpx_alt_range"),
                    @"value": [NSString stringWithFormat:@"%@ - %@",
                                                         [OAOsmAndFormatter getFormattedAlt:_analysis.minElevation],
                                                         [OAOsmAndFormatter getFormattedAlt:_analysis.maxElevation]],
                    @"icon": @"ic_custom_trip" //@"ic_small_track"
            }];
        }

        if ([_analysis isSpeedSpecified])
        {
            [statistics addObject:@{
                    @"title": OALocalizedString(@"gpx_average_speed"),
                    @"value": [OAOsmAndFormatter getFormattedSpeed:_analysis.avgSpeed],
                    @"icon": @"ic_custom_trip" //@"ic_small_track"
            }];
            [statistics addObject:@{
                    @"title": OALocalizedString(@"gpx_max_speed"),
                    @"value": [OAOsmAndFormatter getFormattedSpeed:_analysis.maxSpeed],
                    @"icon": @"ic_custom_trip" //@"ic_small_track"
            }];
        }

        if (_analysis.hasSpeedData)
        {
            long timeSpan = withoutGaps ? _analysis.timeSpanWithoutGaps : _analysis.timeSpan;
            [statistics addObject:@{
                    @"title": OALocalizedString(@"total_time"),
                    @"value": [OAOsmAndFormatter getFormattedTimeInterval:timeSpan shortFormat:YES],
                    @"icon": @"ic_custom_trip" //@"ic_small_track"
            }];
        }

        if (_analysis.isTimeMoving)
        {
            long timeMoving = withoutGaps ? _analysis.timeMovingWithoutGaps : _analysis.timeMoving;
            [statistics addObject:@{
                    @"title": OALocalizedString(@"moving_time"),
                    @"value": [OAOsmAndFormatter getFormattedTimeInterval:timeMoving shortFormat:YES],
                    @"icon": @"ic_custom_trip" //@"ic_small_track"
            }];
        }
    }
    [_headerView setCollection:statistics];
}

- (CGFloat)initialMenuHeight
{
    CGFloat totalHeight = self.topHeaderContainerView.frame.origin.y + self.toolBarView.frame.size.height;
    if (self.tabBarView.selectedItem.tag == kOverviewTabIndex)
        totalHeight += !_headerView.collectionView.hidden
                ? _headerView.collectionView.frame.origin.y
                : _headerView.locationContainerView.frame.origin.y;
    else
        totalHeight += _headerView.bottomSeparatorView.frame.origin.y;

    return totalHeight;
}

- (CGFloat)expandedMenuHeight
{
    return DeviceScreenHeight / 2;
}

- (BOOL)showStatusBarWhenFullScreen
{
    return YES;
}

- (void)doAdditionalLayout
{
    self.backButtonLeadingConstraint.constant = [self isLandscape] ? self.scrollableView.frame.size.width + 20. : [OAUtilities getLeftMargin] + 10.;
    self.backButtonContainerView.hidden = self.currentState == EOADraggableMenuStateFullScreen;
}

- (void)adjustMapViewPort
{
    OAMapRendererView *mapView = _mapViewController.mapView;
    mapView.viewportXScale = [self isLandscape] ? VIEWPORT_SHIFTED_SCALE : VIEWPORT_NON_SHIFTED_SCALE;
    mapView.viewportYScale = [self getViewHeight] / DeviceScreenHeight;
}

- (void)restoreMapViewPort
{
    OAMapRendererView *mapView = _mapViewController.mapView;
    if (mapView.viewportXScale != VIEWPORT_NON_SHIFTED_SCALE)
        mapView.viewportXScale = VIEWPORT_NON_SHIFTED_SCALE;
    if (mapView.viewportYScale != _cachedYViewPort)
        mapView.viewportYScale = _cachedYViewPort;
}

- (void)changeMapRulerPosition
{
    CGFloat bottomMargin = [self isLandscape] ? 0 : (-[self getViewHeight] + [OAUtilities getBottomMargin] - 20.);
    [_mapPanelViewController targetSetMapRulerPosition:bottomMargin
                                                  left:([self isLandscape] ? self.scrollableView.frame.size.width
                                                          : [OAUtilities getLeftMargin] + 20.)];
}

- (NSString *)getUniqueFileName:(NSString *)fileName inFolderPath:(NSString *)folderPath
{
    NSString *name = [fileName stringByDeletingPathExtension];
    NSString *newName = name;
    int i = 1;
    while ([[NSFileManager defaultManager] fileExistsAtPath:[[folderPath stringByAppendingPathComponent:newName] stringByAppendingPathExtension:@"gpx"]])
    {
        newName = [NSString stringWithFormat:@"%@ %i", name, i++];
    }
    return [newName stringByAppendingPathExtension:@"gpx"];
}

- (void)copyGPXToNewFolder:(NSString *)newFolderName
           renameToNewName:(NSString *)newFileName
        deleteOriginalFile:(BOOL)deleteOriginalFile
{
    NSString *oldPath = _gpx.gpxFilePath;
    NSString *oldName = _gpx.gpxFileName;
    NSString *sourcePath = [_app.gpxPath stringByAppendingPathComponent:oldPath];

    NSString *newFolder = [newFolderName isEqualToString:OALocalizedString(@"tracks")] ? @"" : newFolderName;
    NSString *newFolderPath = [_app.gpxPath stringByAppendingPathComponent:newFolder];
    NSString *newName = newFileName ? newFileName : oldName;
    newName = [self getUniqueFileName:newName inFolderPath:newFolderPath];
    NSString *newStoringPath = [newFolder stringByAppendingPathComponent:newName];
    NSString *destinationPath = [newFolderPath stringByAppendingPathComponent:newName];

    [[NSFileManager defaultManager] copyItemAtPath:sourcePath toPath:destinationPath error:nil];

    OAGPXDatabase *gpxDatabase = [OAGPXDatabase sharedDb];
    if (deleteOriginalFile)
    {
        [gpxDatabase updateGPXFolderName:newStoringPath oldFilePath:oldPath];
        [gpxDatabase save];
        [[NSFileManager defaultManager] removeItemAtPath:sourcePath error:nil];

//        self.titleView.text = [newName stringByDeletingPathExtension];
        [OASelectedGPXHelper renameVisibleTrack:oldPath newPath:newStoringPath];
    }
    else
    {
        OAGPXDocument *gpxDoc = [[OAGPXDocument alloc] initWithGpxFile:sourcePath];
        OAGPXTrackAnalysis *analysis = [gpxDoc getAnalysis:0];
        [gpxDatabase addGpxItem:[newFolder stringByAppendingPathComponent:newName]
                          title:newName
                           desc:gpxDoc.metadata.desc
                         bounds:gpxDoc.bounds
                       analysis:analysis];

        if ([_settings.mapSettingVisibleGpx.get containsObject:oldPath])
            [_settings showGpx:@[newStoringPath]];
    }

//    if (self.delegate)
//        [self.delegate contentChanged];
}

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][@"cells"][indexPath.row];
}

- (IBAction)onBackButtonPressed:(id)sender
{
    [self dismiss];
}

#pragma mark - OADraggableViewActions

- (void)onViewHeightChanged:(CGFloat)height
{
    [_mapPanelViewController targetSetBottomControlsVisible:YES
                                                 menuHeight:[self isLandscape] ? 0
                                                         : height - [OAUtilities getBottomMargin]
                                                   animated:YES];
    [self changeMapRulerPosition];

//    [self adjustActionButtonsPosition:height];
//    [self changeMapRulerPosition];
    [self adjustMapViewPort];
}

#pragma mark - UITabBarDelegate

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    [self setupHeaderView];
    [self generateData];

    switch (item.tag)
    {
        case kActionsTabIndex:
        {
            [self goFullScreen];
            break;
        }
        default:
        {
            if (self.currentState == EOADraggableMenuStateInitial)
                [self goExpanded];
            else
                [self updateViewAnimated];
            break;
        }
    }

    [UIView transitionWithView:self.tableView
                      duration:0.35f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^(void)
                    {
                        [self.tableView reloadData];
                    }
                    completion: nil];
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
    if (_isCurrentTrack && _exportFilePath)
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
                initWithFileName:_gpx.gpxFilePath.lastPathComponent.stringByDeletingPathExtension
                        filePath:_gpx.gpxFilePath
                       showOnMap:YES
                 simplifiedTrack:YES];

        saveTrackViewController.delegate = self;
        [OARootViewController.instance presentViewController:saveTrackViewController animated:YES completion:nil];
    }
}

#pragma mark - Action buttons pressed

- (void)onShowHidePressed:(id)sender
{
    if (_isShown)
        [_settings hideGpx:@[_gpx.gpxFilePath] update:YES];
    else
        [_settings showGpx:@[_gpx.gpxFilePath] update:YES];

    _isShown = [_settings.mapSettingVisibleGpx.get containsObject:_gpx.gpxFilePath];

    [_headerView.showHideButton setTitle:_isShown ? OALocalizedString(@"sett_show") : OALocalizedString(@"poi_hide")
                                forState:UIControlStateNormal];
    [_headerView.showHideButton setImage:[UIImage templateImageNamed:_isShown ? @"ic_custom_show" : @"ic_custom_hide"]
                                forState:UIControlStateNormal];
}

- (void)onAppearancePressed:(id)sender
{
    OAEditGPXColorViewController *trackColorViewController =
            [[OAEditGPXColorViewController alloc] initWithColorValue:_gpx.color
                                                    colorsCollection:_gpxColorCollection];
    trackColorViewController.delegate = self;
    [self presentViewController:trackColorViewController animated:YES completion:nil];
}

- (void)onExportPressed:(id)sender
{
    if (_isCurrentTrack)
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

        [_savingHelper saveCurrentTrack:_exportFilePath];
    }
    else
    {
        _exportFileName = _gpx.gpxFileName;
        _exportFilePath = [_app.gpxPath stringByAppendingPathComponent:_gpx.gpxFilePath];
    }

    _exportController = [UIDocumentInteractionController interactionControllerWithURL:[NSURL fileURLWithPath:_exportFilePath]];
    _exportController.UTI = @"com.topografix.gpx";
    _exportController.delegate = self;
    _exportController.name = _exportFileName;
    [_exportController presentOptionsMenuFromRect:CGRectZero inView:self.view animated:YES];
}

- (void)onNavigationPressed:(id)sender
{
    if ([_doc getNonEmptySegmentsCount] > 1)
    {
        OATrackSegmentsViewController *trackSegmentViewController = [[OATrackSegmentsViewController alloc] initWithFile:_doc];
        trackSegmentViewController.delegate = self;
        [OARootViewController.instance presentViewController:trackSegmentViewController animated:YES completion:nil];
    }
    else
    {
        if (![[OARoutingHelper sharedInstance] isFollowingMode])
            [_mapPanelViewController.mapActions stopNavigationWithoutConfirm];

        [_mapPanelViewController.mapActions enterRoutePlanningModeGivenGpx:_gpx
                                                                      from:nil
                                                                  fromName:nil
                                            useIntermediatePointsByDefault:YES
                                                                showDialog:YES];
        [self dismiss];
    }
}

#pragma mark - OAEditGPXColorViewControllerDelegate

-(void)trackColorChanged:(NSInteger)colorIndex
{
    OAGPXTrackColor *gpxColor = [_gpxColorCollection getAvailableGPXColors][colorIndex];
    _gpx.color = gpxColor.colorValue;
    [[OAGPXDatabase sharedDb] save];
    [[_app mapSettingsChangeObservable] notifyEvent];
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

    [_mapPanelViewController.mapActions setGPXRouteParamsWithDocument:_doc path:_doc.path];
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

    [_mapPanelViewController.mapActions stopNavigationWithoutConfirm];
    [_mapPanelViewController.mapActions enterRoutePlanningModeGivenGpx:_doc
                                                                  path:_gpx.gpxFilePath
                                                                  from:nil
                                                              fromName:nil
                                        useIntermediatePointsByDefault:YES
                                                            showDialog:YES];
    [self dismiss];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ((NSArray *) _data[section][@"cells"]).count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return _data[section][@"group_name"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    BOOL hasOptions = [item[@"has_options"] boolValue];

    UITableViewCell *outCell = nil;
    if ([item[@"type"] isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAIconTitleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTitleValueCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleValueCell *) nib[0];
            [cell showLeftIcon:NO];
            cell.separatorInset = UIEdgeInsetsMake(0., 20., 0., 0.);
        }
        if (cell)
        {
            NSString *value = item[@"value"];
            cell.selectionStyle = hasOptions ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
            cell.textView.text = item[@"name"];
            cell.descriptionView.text = value;
            [cell showRightIcon:hasOptions];
        }
        outCell = cell;
    }

    return outCell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return section == [self numberOfSectionsInTableView:tableView] - 1 && _data.count > 0 ? 100. : 0.;
}

/*- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];

    if (item[@"has_options"])
    {
        if ([item[@"key"] isEqualToString:@"location"])
        {

        }
        else if ([item[@"key"] isEqualToString:@"activity"])
        {

        }
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}*/

@end
