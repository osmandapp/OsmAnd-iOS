//
//  OATrackMenuHudViewController.mm
//  OsmAnd
//
//  Created by Skalii on 10.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OATrackMenuHudViewController.h"
#import "OARootViewController.h"
#import "OASaveTrackViewController.h"
#import "OAEditGPXColorViewController.h"
#import "OATrackSegmentsViewController.h"
#import "OATrackMenuDescriptionViewController.h"
#import "OAMapRendererView.h"
#import "OATrackMenuHeaderView.h"
#import "OATabBar.h"
#import "OAIconTitleValueCell.h"
#import "OATextViewSimpleCell.h"
#import "OATextLineViewCell.h"
#import "Localization.h"
#import "OAColors.h"
#import "OARoutingHelper.h"
#import "OATargetPointsHelper.h"
#import "OASelectedGPXHelper.h"
#import "OASavingTrackHelper.h"
#import "OAGPXDatabase.h"
#import "OAGPXTrackAnalysis.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGPXDocument.h"
#import "OAMapActions.h"
#import "OARouteProvider.h"
#import "OAOsmAndFormatter.h"

#define kOverviewTabIndex 0
#define kSegmentsTabIndex 1
#define kPointsTabIndex 2
#define kActionsTabIndex 3

@interface OATrackMenuHudViewController() <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, UITabBarDelegate, UIDocumentInteractionControllerDelegate, OASaveTrackViewControllerDelegate, OASegmentSelectionDelegate, OATrackMenuViewControllerDelegate>

@property (weak, nonatomic) IBOutlet OATabBar *tabBarView;

@property (nonatomic) OAMapPanelViewController *mapPanelViewController;
@property (nonatomic) OAMapViewController *mapViewController;

@property (nonatomic) OsmAndAppInstance app;
@property (nonatomic) OAAppSettings *settings;
@property (nonatomic) OASavingTrackHelper *savingHelper;

@property (nonatomic) OAGPX *gpx;
@property (nonatomic) OAGPXDocument *doc;
@property (nonatomic) OAGPXTrackAnalysis *analysis;
@property (nonatomic) BOOL isCurrentTrack;
@property (nonatomic) BOOL isShown;

@property (nonatomic) NSArray<NSDictionary *> *data;

@end

@implementation OATrackMenuHudViewController
{
    UIDocumentInteractionController *_exportController;
    OATrackMenuHeaderView *_headerView;

    NSString *_description;
    NSString *_exportFileName;
    NSString *_exportFilePath;
}

- (instancetype)initWithGpx:(OAGPX *)gpx
{
    self = [super initWithNibName:@"OATrackMenuHudViewController" bundle:nil];
    if (self)
    {
        self.gpx = gpx;
        [self commonInit];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.sectionFooterHeight = 0.01;

    if (!self.isShown)
        [self onShowHidePressed:nil];
}

- (void)setupView
{
    [self setupTabBar];
    [self setupDescription];

    [super setupView];
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
    [self.tabBarView makeTranslucent:YES];
}

- (void)setupDescription
{
    if (self.tabBarView.selectedItem.tag == kOverviewTabIndex)
    {
        _description = self.doc.metadata.desc;
    }
    else if (self.tabBarView.selectedItem.tag == kSegmentsTabIndex)
    {
        NSInteger segmentsCount = 0;
        for (OAGpxTrk *track in self.doc.tracks)
        {
            segmentsCount += track.segments.count;
        }
        _description = [NSString stringWithFormat: @"%@: %ld",
                OALocalizedString(@"gpx_selection_segment_title"),
                segmentsCount];
    }
    else
    {
        _description = @"";
    }
}

- (void)setupHeaderView
{
    [super setupHeaderView];

    if (_headerView)
        [_headerView removeFromSuperview];

//    if (!_headerView)
    _headerView = [[OATrackMenuHeaderView alloc] init];
    _headerView.delegate = self;
    [_headerView.titleView setText:self.isCurrentTrack ? OALocalizedString(@"track_recording_name") : [self.gpx getNiceTitle]];
    _headerView.titleIconView.image = [UIImage templateImageNamed:@"ic_custom_trip"];
    _headerView.titleIconView.tintColor = UIColorFromRGB(color_icon_inactive);

    if (self.tabBarView.selectedItem.tag == kOverviewTabIndex)
    {
        [self generateGpxBlockStatistics];

        CLLocationCoordinate2D location = self.app.locationServices.lastKnownLocation.coordinate;
        CLLocationCoordinate2D gpxLocation = self.doc.bounds.center;
        _headerView.directionIconView.image = [UIImage templateImageNamed:@"ic_small_direction"];
        _headerView.directionIconView.tintColor = UIColorFromRGB(color_primary_purple);
        [_headerView.directionTextView setText:[OAOsmAndFormatter getFormattedDistance:getDistance(location.latitude, location.longitude, gpxLocation.latitude, gpxLocation.longitude)]];
        _headerView.directionTextView.textColor = UIColorFromRGB(color_primary_purple);

        OAWorldRegion *worldRegion = [self.app.worldRegion findAtLat:self.gpx.bounds.center.latitude lon:self.gpx.bounds.center.longitude];
        _headerView.regionIconView.image = [UIImage templateImageNamed:@"ic_small_map_point"];
        _headerView.regionIconView.tintColor = UIColorFromRGB(color_footer_icon_gray);
        [_headerView.regionTextView setText:worldRegion.localizedName];
        _headerView.regionTextView.textColor = UIColorFromRGB(color_text_footer);

        [_headerView.showHideButton setTitle:self.isShown ? OALocalizedString(@"poi_hide") : OALocalizedString(@"sett_show") forState:UIControlStateNormal];
        [_headerView.showHideButton setImage:[UIImage templateImageNamed:self.isShown ? @"ic_custom_hide" : @"ic_custom_show"] forState:UIControlStateNormal];
        [_headerView.showHideButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [_headerView.showHideButton addTarget:self action:@selector(onShowHidePressed:) forControlEvents:UIControlEventTouchUpInside];

        [_headerView.appearanceButton setTitle:OALocalizedString(@"map_settings_appearance") forState:UIControlStateNormal];
        [_headerView.appearanceButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
        [_headerView.appearanceButton addTarget:self action:@selector(onAppearancePressed:) forControlEvents:UIControlEventTouchUpInside];

        if (!self.isCurrentTrack)
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

    [_headerView setDescription:_description];

    if ([_headerView needsUpdateConstraints])
        [_headerView updateConstraints];

    if (_headerView.collectionView.hidden
            && _headerView.locationContainerView.hidden
            && _headerView.actionButtonsContainerView.hidden)
    {
        CGRect headerFrame = _headerView.frame;
        headerFrame.size.height = _headerView.collectionView.frame.origin.y + 1;
        headerFrame.size.width = self.topHeaderContainerView.frame.size.width;
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
    [super generateData];

    NSMutableArray *data = [NSMutableArray array];

    if (self.tabBarView.selectedItem.tag == kOverviewTabIndex)
    {
        if (_description && _description.length > 0)
        {
            NSMutableArray *descriptionSectionData = [NSMutableArray array];
            NSAttributedString *description = [OAUtilities createAttributedString:
                    [_description componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]][0]
                                                                             font:[UIFont systemFontOfSize:17]
                                                                            color:UIColor.blackColor
                                                                      strokeColor:nil
                                                                      strokeWidth:0
                                                                        alignment:NSTextAlignmentNatural];

            [descriptionSectionData addObject:@{
                    @"value": description,
                    @"type": [OATextViewSimpleCell getCellIdentifier],
                    @"key": @"description"
            }];

            if (_description.length > description.string.length)
            {
                [descriptionSectionData addObject:@{
                        @"title": OALocalizedString(@"read_full_description"),
                        @"type": [OATextLineViewCell getCellIdentifier],
                        @"key": @"full_description"
                }];
            }

            [data addObject:@{
                    @"group_name": OALocalizedString(@"description"),
                    @"cells": descriptionSectionData
            }];
        }

        NSMutableArray *infoSectionData = [NSMutableArray array];

        NSDictionary *fileAttributes = [NSFileManager.defaultManager attributesOfItemAtPath:self.isCurrentTrack ? self.gpx.gpxFilePath : self.doc.path error:nil];
        NSString *formattedSize = [NSByteCountFormatter stringFromByteCount:fileAttributes.fileSize countStyle:NSByteCountFormatterCountStyleFile];
        [infoSectionData addObject:@{
                @"title": OALocalizedString(@"res_size"),
                @"value": formattedSize,
                @"has_options": @NO,
                @"type": [OAIconTitleValueCell getCellIdentifier],
                @"key": @"size"
        }];

        NSDate *createdOnDate = [NSDate dateWithTimeIntervalSince1970:self.doc.metadata.time];
        if ([createdOnDate earlierDate:[NSDate date]] == createdOnDate)
            [infoSectionData addObject:@{
                    @"title": OALocalizedString(@"res_created_on"),
                    @"value": [NSDateFormatter localizedStringFromDate:createdOnDate
                                                             dateStyle:NSDateFormatterMediumStyle
                                                             timeStyle:NSDateFormatterNoStyle],
                    @"has_options": @NO,
                    @"type": [OAIconTitleValueCell getCellIdentifier],
                    @"key": @"created_on"
            }];

        if (!self.isCurrentTrack)
            [infoSectionData addObject:@{
                    @"title": OALocalizedString(@"sett_arr_loc"),
                    @"value": [[OAGPXDatabase sharedDb] getFileDir:self.gpx.gpxFilePath].capitalizedString,
                    @"has_options": @NO, //@YES
                    @"type": [OAIconTitleValueCell getCellIdentifier],
                    @"key": @"location"
            }];

        /*[infoSectionData addObject:@{
                @"title": OALocalizedString(@"activity"),
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

    self.data = data;
}

- (void)generateGpxBlockStatistics
{
    NSMutableArray *statistics = [NSMutableArray array];
    if (self.analysis)
    {
        BOOL withoutGaps = !self.gpx.joinSegments && (self.isCurrentTrack ? (self.doc.tracks.count == 0 || self.doc.tracks.firstObject.generalTrack) : (self.doc.tracks.count > 0 && self.doc.tracks.firstObject.generalTrack));

        if (self.analysis.totalDistance != 0)
        {
            float totalDistance = withoutGaps ? self.analysis.totalDistanceWithoutGaps : self.analysis.totalDistance;
            [statistics addObject:@{
                    @"title": OALocalizedString(@"gpx_distance"),
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
                    @"type": @(EOARouteStatisticsModeAltitude),
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
    NSString *oldPath = self.gpx.gpxFilePath;
    NSString *oldName = self.gpx.gpxFileName;
    NSString *sourcePath = [self.app.gpxPath stringByAppendingPathComponent:oldPath];

    NSString *newFolder = [newFolderName isEqualToString:OALocalizedString(@"tracks")] ? @"" : newFolderName;
    NSString *newFolderPath = [self.app.gpxPath stringByAppendingPathComponent:newFolder];
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

        if ([self.settings.mapSettingVisibleGpx.get containsObject:oldPath])
            [self.settings showGpx:@[newStoringPath]];
    }

//    if (self.delegate)
//        [self.delegate contentChanged];
}

#pragma mark - OATrackMenuViewControllerDelegate

- (void)openAnalysis:(EOARouteStatisticsMode)modeType
{
    [self dismiss:^{
        [self.mapPanelViewController openTargetViewWithRouteDetailsGraph:self.doc analysis:self.analysis trackMenuDelegate:self modeType:modeType];
    }];
}

- (void)onExitAnalysis
{
    [self.mapPanelViewController openTargetViewWithGPX:self.gpx trackHudMode:EOATrackMenuHudMode];
}

#pragma mark - UITabBarDelegate

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    [self setupDescription];
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
        [OARootViewController.instance presentViewController:saveTrackViewController animated:YES completion:nil];
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
    /*OAEditGPXColorViewController *trackColorViewController =
            [[OAEditGPXColorViewController alloc] initWithColorValue:self.gpx.color
                                                    colorsCollection:_gpxColorCollection];
    trackColorViewController.delegate = self;
    [self presentViewController:trackColorViewController animated:YES completion:nil];*/
    [self dismiss:^{
        [self.mapPanelViewController openTargetViewWithGPX:self.gpx trackHudMode:EOATrackAppearanceHudMode];
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
        _exportFilePath = [self.app.gpxPath stringByAppendingPathComponent:self.gpx.gpxFilePath];
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
        [OARootViewController.instance presentViewController:trackSegmentViewController animated:YES completion:nil];
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
        [self dismiss:nil];
    }
}

#pragma mark - OAEditGPXColorViewControllerDelegate

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
    [self dismiss:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ((NSArray *) self.data[section][@"cells"]).count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.data[section][@"group_name"];
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
            cell.selectionStyle = hasOptions ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
            cell.textView.text = item[@"title"];
            cell.descriptionView.text = item[@"value"];
            [cell showRightIcon:hasOptions];
        }
        outCell = cell;
    }
    else if ([item[@"type"] isEqualToString:[OATextViewSimpleCell getCellIdentifier]])
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
            cell.textView.attributedText = item[@"value"];
            cell.textView.linkTextAttributes = @{NSForegroundColorAttributeName: UIColorFromRGB(color_primary_purple)};
            [cell.textView sizeToFit];
        }
        outCell = cell;
    }
    else if ([item[@"type"] isEqualToString:[OATextLineViewCell getCellIdentifier]])
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
            cell.textView.text = item[@"title"];
            cell.textView.textColor = UIColorFromRGB(color_primary_purple);
        }
        outCell = cell;
    }

    return outCell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];

    if ([item[@"key"] isEqualToString:@"full_description"])
    {
        OATrackMenuDescriptionViewController *descriptionViewController =
                [[OATrackMenuDescriptionViewController alloc] initWithGpxDoc:self.doc gpx:self.gpx];
        [self.navigationController pushViewController:descriptionViewController animated:YES];
    }
    /*else if ([item[@"key"] isEqualToString:@"location"])
    {

    }
    else if ([item[@"key"] isEqualToString:@"activity"])
    {

    }*/

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
