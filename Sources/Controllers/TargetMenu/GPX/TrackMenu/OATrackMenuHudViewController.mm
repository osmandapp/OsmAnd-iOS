//
//  OATrackMenuHudViewController.mm
//  OsmAnd
//
//  Created by Skalii on 10.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OATrackMenuHudViewController.h"
#import "OATrackMenuHeaderView.h"
#import "OAMapPanelViewController.h"
#import "OASaveTrackViewController.h"
#import "OATrackSegmentsViewController.h"
#import "OATrackMenuDescriptionViewController.h"
#import "OASelectTrackFolderViewController.h"
#import "PXAlertView.h"
#import "OATabBar.h"
#import "OAIconTitleValueCell.h"
#import "OATextViewSimpleCell.h"
#import "OATextLineViewCell.h"
#import "OATitleIconRoundCell.h"
#import "OATitleDescriptionIconRoundCell.h"
#import "OATitleSwitchRoundCell.h"
#import "Localization.h"
#import "OAColors.h"
#import "OARoutingHelper.h"
#import "OATargetPointsHelper.h"
#import "OASelectedGPXHelper.h"
#import "OAGPXTrackAnalysis.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAGPXDocument.h"
#import "OAMapActions.h"
#import "OARouteProvider.h"
#import "OAOsmAndFormatter.h"

typedef NS_ENUM(NSUInteger, EOATrackMenuHudActionsSection)
{
    EOATrackMenuHudActionsControlSection = 0,
    EOATrackMenuHudActionsAnalyzeSection,
    EOATrackMenuHudActionsShareSection,
    EOATrackMenuHudActionsEditSection,
    EOATrackMenuHudActionsChangeSection,
    EOATrackMenuHudActionsDeleteSection,
};

typedef NS_ENUM(NSUInteger, EOATrackMenuHudChangeRow)
{
    EOATrackMenuHudActionsChangeRenameRow = 0,
    EOATrackMenuHudActionsChangeMoveRow
};

@interface OATrackMenuHudViewController() <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, UITabBarDelegate, UIDocumentInteractionControllerDelegate, OASaveTrackViewControllerDelegate, OASegmentSelectionDelegate, OATrackMenuViewControllerDelegate, OASelectTrackFolderDelegate>

@property (weak, nonatomic) IBOutlet OATabBar *tabBarView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomSeparatorHeight;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomSeparatorTopConstraint;

@property (nonatomic) NSArray<NSDictionary *> *tableData;
@property (nonatomic) BOOL isShown;
@property (nonatomic) OATableData *menuTableData;

@end

@implementation OATrackMenuHudViewController
{
    UIDocumentInteractionController *_exportController;
    OATrackMenuHeaderView *_headerView;

    NSString *_description;
    NSString *_exportFileName;
    NSString *_exportFilePath;

    EOATrackMenuHudTab _selectedTab;
}

@dynamic tableData, isShown, menuTableData;

- (instancetype)initWithGpx:(OAGPX *)gpx
{
    self = [super initWithGpx:gpx];
    if (self)
    {
        _selectedTab = EOATrackMenuHudOverviewTab;
    }
    return self;
}

- (instancetype)initWithGpx:(OAGPX *)gpx tab:(EOATrackMenuHudTab)tab
{
    self = [super initWithGpx:gpx];
    if (self)
    {
        _selectedTab = tab >= EOATrackMenuHudOverviewTab ? tab : EOATrackMenuHudOverviewTab;
    }
    return self;
}

- (NSString *)getNibName
{
    return @"OATrackMenuHudViewController";
}

- (void)commonInit
{
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    self.bottomSeparatorHeight.constant = 0.5;
    self.bottomSeparatorTopConstraint.constant = -0.5;

    if (!self.isShown)
        [self onShowHidePressed:nil];
}

- (void)setupView
{
    [self setupTabBar];
    [self setupTableView];
    [self setupDescription];
}

- (void)setupTableView
{
    UITableViewCellSeparatorStyle separatorStyle = UITableViewCellSeparatorStyleNone;

    if (_selectedTab == EOATrackMenuHudOverviewTab)
        separatorStyle = UITableViewCellSeparatorStyleSingleLine;

    self.tableView.separatorStyle = separatorStyle;
}

- (void)setupTabBar
{
    UIColor *unselectedColor = UIColorFromRGB(color_dialog_buttons_dark);
    [self.tabBarView setItems:@[
                    [[UITabBarItem alloc]
                            initWithTitle:OALocalizedString(@"shared_string_overview")
                                    image:[OAUtilities tintImageWithColor:[UIImage templateImageNamed:@"ic_custom_overview"]
                                                                    color:unselectedColor]
                                      tag:EOATrackMenuHudOverviewTab],
                    [[UITabBarItem alloc]
                            initWithTitle:OALocalizedString(@"actions")
                                    image:[OAUtilities tintImageWithColor:[UIImage templateImageNamed:@"ic_custom_overflow_menu"]
                                                                    color:unselectedColor]
                                      tag:EOATrackMenuHudActionsTab]
            ]
                     animated:YES];

    self.tabBarView.selectedItem = self.tabBarView.items[_selectedTab];
    self.tabBarView.itemWidth = self.scrollableView.frame.size.width / self.tabBarView.items.count;
    self.tabBarView.delegate = self;
    self.tabBarView.backgroundImage = [UIImage new];
    self.tabBarView.shadowImage = [UIImage new];
}

- (void)setupDescription
{
    if (_selectedTab == EOATrackMenuHudOverviewTab)
    {
        _description = self.doc.metadata.desc;
    }
    else
    {
        _description = @"";
    }
}

- (void)setupHeaderView
{
    if (_headerView)
        [_headerView removeFromSuperview];

    _headerView = [[OATrackMenuHeaderView alloc] init];
    [_headerView setDescription:_description];

    if (_selectedTab != EOATrackMenuHudActionsTab)
    {
        [_headerView.titleView setText:self.isCurrentTrack ? OALocalizedString(@"track_recording_name") : [self.gpx getNiceTitle]];
        _headerView.titleIconView.image = [UIImage templateImageNamed:@"ic_custom_trip"];
        _headerView.titleIconView.tintColor = UIColorFromRGB(color_icon_inactive);
    }

    if (_selectedTab == EOATrackMenuHudOverviewTab)
    {
        [self generateGpxBlockStatistics];

        CLLocationCoordinate2D gpxLocation = self.doc.bounds.center;
        CLLocation *lastKnownLocation = self.app.locationServices.lastKnownLocation;
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
            OAWorldRegion *worldRegion = [self.app.worldRegion findAtLat:gpxLocation.latitude
                                                                     lon:gpxLocation.longitude];
            _headerView.regionIconView.image = [UIImage templateImageNamed:@"ic_small_map_point"];
            _headerView.regionIconView.tintColor = UIColorFromRGB(color_footer_icon_gray);
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

    CGRect headerFrame = _headerView.frame;

    if (_headerView.locationContainerView.hidden)
        headerFrame.size.height -= _headerView.locationContainerView.frame.size.height;

    if (_headerView.collectionView.hidden)
    {
        if (_headerView.locationContainerView.hidden && _headerView.actionButtonsContainerView.hidden)
            headerFrame.size.height = _headerView.collectionView.frame.origin.y;
        else
            headerFrame.size.height -= _headerView.collectionView.frame.size.height;
    }

    if (_headerView.descriptionContainerView.hidden)
        headerFrame.size.height -= _headerView.descriptionContainerView.frame.size.height;

    _headerView.frame = headerFrame;

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
    NSMutableArray *newData = [NSMutableArray array];

    if (_selectedTab == EOATrackMenuHudOverviewTab)
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

            [newData addObject:@{
                    @"group_name": OALocalizedString(@"description"),
                    @"cells": descriptionSectionData
            }];
        }

        NSMutableArray *infoSectionData = [NSMutableArray array];

        NSDictionary *fileAttributes = [NSFileManager.defaultManager attributesOfItemAtPath:self.isCurrentTrack
                ? self.gpx.gpxFilePath : self.doc.path error:nil];
        NSString *formattedSize = [NSByteCountFormatter stringFromByteCount:fileAttributes.fileSize
                                                                 countStyle:NSByteCountFormatterCountStyleFile];
        [infoSectionData addObject:@{
                @"title": OALocalizedString(@"res_size"),
                @"value": formattedSize,
                @"has_options": @NO,
                @"type": [OAIconTitleValueCell getCellIdentifier],
                @"key": @"size"
        }];

        if (self.doc.metadata.time > 0)
            [infoSectionData addObject:@{
                    @"title": OALocalizedString(@"res_created_on"),
                    @"value": [NSDateFormatter localizedStringFromDate:[NSDate dateWithTimeIntervalSince1970:self.doc.metadata.time]
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

        [newData addObject:@{
                @"group_name": OALocalizedString(@"shared_string_info"),
                @"cells": infoSectionData
        }];
    }
    else if (_selectedTab == EOATrackMenuHudActionsTab)
    {
        NSMutableArray *controlSectionData = [NSMutableArray array];

        [controlSectionData addObject:@{
                @"title": OALocalizedString(@"map_settings_show"),
                @"value": @(self.isShown),
                @"type": [OATitleSwitchRoundCell getCellIdentifier],
                @"key": @"control_show_on_map"
        }];

        [controlSectionData addObject:@{
                @"title": OALocalizedString(@"map_settings_appearance"),
                @"icon": @"ic_custom_appearance",
                @"type": [OATitleIconRoundCell getCellIdentifier],
                @"key": @"control_appearance"
        }];

        [controlSectionData addObject:@{
                @"title": OALocalizedString(@"routing_settings"),
                @"icon": @"ic_custom_navigation",
                @"type": [OATitleIconRoundCell getCellIdentifier],
                @"key": @"control_navigation"
        }];

        [newData addObject:@{
                @"cells": controlSectionData
        }];

        [newData addObject:@{
                @"cells": @[@{
                        @"title": OALocalizedString(@"analyze_on_map"),
                        @"icon": @"ic_custom_appearance",
                        @"type": [OATitleIconRoundCell getCellIdentifier],
                        @"key": @"analyze"
                }]
        }];

        NSMutableArray *shareSectionData = [NSMutableArray array];

        [shareSectionData addObject:@{
                @"title": OALocalizedString(@"ctx_mnu_share"),
                @"icon": @"ic_custom_export",
                @"type": [OATitleIconRoundCell getCellIdentifier],
                @"key": @"share"
        }];

        [newData addObject:@{
                @"cells": shareSectionData
        }];

        NSMutableArray *editSectionData = [NSMutableArray array];

        [editSectionData addObject:@{
                @"title": OALocalizedString(@"edit_track"),
                @"icon": @"ic_custom_trip_edit",
                @"type": [OATitleIconRoundCell getCellIdentifier],
                @"key": @"edit"
        }];

        [editSectionData addObject:@{
                @"title": OALocalizedString(@"duplicate_track"),
                @"icon": @"ic_custom_copy",
                @"type": [OATitleIconRoundCell getCellIdentifier],
                @"key": @"edit_create_duplicate"
        }];

        [newData addObject:@{
                @"cells": editSectionData
        }];

        NSMutableArray *changeSectionData = [NSMutableArray array];

        [changeSectionData addObject:@{
                @"title": OALocalizedString(@"gpx_rename_q"),
                @"icon": @"ic_custom_edit",
                @"type": [OATitleIconRoundCell getCellIdentifier],
                @"key": @"change_rename"
        }];

        [changeSectionData addObject:[self getCellDataForRow:EOATrackMenuHudActionsChangeMoveRow
                                                     section:EOATrackMenuHudActionsChangeSection]];

        [newData addObject:@{
                @"cells": changeSectionData
        }];

        [newData addObject:@{
                @"cells": @[@{
                        @"title": OALocalizedString(@"shared_string_delete"),
                        @"icon": @"ic_custom_remove_outlined",
                        @"type": [OATitleIconRoundCell getCellIdentifier],
                        @"key": @"delete"
                }]
        }];
    }

    self.tableData = newData;
}

- (NSDictionary *)getCellDataForRow:(NSInteger)row section:(NSInteger)section
{
    if (section == EOATrackMenuHudActionsChangeSection)
    {
        if (row == EOATrackMenuHudActionsChangeMoveRow)
            return @{
                    @"title": OALocalizedString(@"plan_route_change_folder"),
                    @"icon": @"ic_custom_folder_move",
                    @"desc": [[OAGPXDatabase sharedDb] getFileDir:self.gpx.gpxFilePath].capitalizedString,
                    @"type": [OATitleDescriptionIconRoundCell getCellIdentifier],
                    @"key": @"change_move"
            };
    }

    return nil;
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
                    @"icon": @"ic_small_distance@2x"
            }];
        }

        if (self.analysis.hasElevationData)
        {
            [statistics addObject:@{
                    @"title": OALocalizedString(@"gpx_ascent"),
                    @"value": [OAOsmAndFormatter getFormattedAlt:self.analysis.diffElevationUp],
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
                    @"icon": @"ic_small_altitude_range"
            }];
        }

        if ([self.analysis isSpeedSpecified])
        {
            [statistics addObject:@{
                    @"title": OALocalizedString(@"gpx_average_speed"),
                    @"value": [OAOsmAndFormatter getFormattedSpeed:self.analysis.avgSpeed],
                    @"icon": @"ic_small_speed"
            }];
            [statistics addObject:@{
                    @"title": OALocalizedString(@"gpx_max_speed"),
                    @"value": [OAOsmAndFormatter getFormattedSpeed:self.analysis.maxSpeed],
                    @"icon": @"ic_small_max_speed"
            }];
        }

        if (self.analysis.hasSpeedData)
        {
            long timeSpan = withoutGaps ? self.analysis.timeSpanWithoutGaps : self.analysis.timeSpan;
            [statistics addObject:@{
                    @"title": OALocalizedString(@"total_time"),
                    @"value": [OAOsmAndFormatter getFormattedTimeInterval:timeSpan shortFormat:YES],
                    @"icon": @"ic_small_time_interval"
            }];
        }

        if (self.analysis.isTimeMoving)
        {
            long timeMoving = withoutGaps ? self.analysis.timeMovingWithoutGaps : self.analysis.timeMoving;
            [statistics addObject:@{
                    @"title": OALocalizedString(@"moving_time"),
                    @"value": [OAOsmAndFormatter getFormattedTimeInterval:timeMoving shortFormat:YES],
                    @"icon": @"ic_small_time_moving"
            }];
        }
    }
    [_headerView setCollection:statistics];
}

- (CGFloat)initialMenuHeight
{
    CGFloat totalHeight = self.topHeaderContainerView.frame.origin.y + self.toolBarView.frame.size.height + 10.;

    if (_selectedTab == EOATrackMenuHudOverviewTab)
        totalHeight += _headerView.descriptionContainerView.hidden
                ? _headerView.descriptionContainerView.frame.origin.y
                : _headerView.collectionView.frame.origin.y;
    else if (!_headerView.descriptionContainerView.hidden)
        totalHeight += _headerView.collectionView.frame.origin.y;
    else
        totalHeight += _headerView.titleContainerView.frame.size.height;

    return totalHeight;
}

- (void)copyGPXToNewFolder:(NSString *)newFolderName
           renameToNewName:(NSString *)newFileName
        deleteOriginalFile:(BOOL)deleteOriginalFile
{
    NSString *oldPath = self.gpx.gpxFilePath;
    NSString *sourcePath = [self.app.gpxPath stringByAppendingPathComponent:oldPath];

    NSString *newFolder = [newFolderName isEqualToString:OALocalizedString(@"tracks")] ? @"" : newFolderName;
    NSString *newFolderPath = [self.app.gpxPath stringByAppendingPathComponent:newFolder];
    NSString *newName = [OAUtilities createNewFileName:newFileName];
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
        OAGPXTrackAnalysis *analysis = [gpxDoc getAnalysis:0];
        [gpxDatabase addGpxItem:[newFolder stringByAppendingPathComponent:newName]
                          title:newName
                           desc:gpxDoc.metadata.desc
                         bounds:gpxDoc.bounds
                       analysis:analysis];

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
        }]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showAlertRenameTrack
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"gpx_rename_q") message:OALocalizedString(@"gpx_enter_new_name \"%@\"", [self.gpx.gpxTitle lastPathComponent]) preferredStyle:UIAlertControllerStyleAlert];

    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:nil]];

    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
        [self renameTrack:alert.textFields[0].text];
    }]];

    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = [self.gpx.gpxTitle lastPathComponent];
    }];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showAlertWithText:(NSString *)text
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:text preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)renameTrack:(NSString *)newName
{
    if (newName.length > 0)
    {
        NSString *oldFilePath = self.gpx.gpxFilePath;
        NSString *oldPath = [self.app.gpxPath stringByAppendingPathComponent:oldFilePath];
        NSString *newFileName = [newName stringByAppendingPathExtension:@"gpx"];
        NSString *newFilePath = [[self.gpx.gpxFilePath stringByDeletingLastPathComponent] stringByAppendingPathComponent:newFileName];
        NSString *newPath = [self.app.gpxPath stringByAppendingPathComponent:newFilePath];
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

- (BOOL)isEnabled:(NSString *)key
{
    if ([key isEqualToString:@"control_show_on_map"])
        return self.isShown;

    return NO;
}

#pragma mark - OATrackMenuViewControllerDelegate

- (void)openAnalysis:(EOARouteStatisticsMode)modeType
{
    [self hide:YES duration:.2 onComplete:^{
        [self.mapPanelViewController openTargetViewWithRouteDetailsGraph:self.doc
                                                                analysis:self.analysis
                                                       trackMenuDelegate:self
                                                                modeType:modeType];
    }];
}

- (void)backToTrackMenu:(OAGPX *)gpx
{
    [self.mapPanelViewController openTargetViewWithGPX:gpx ? gpx : self.gpx
                                          trackHudMode:EOATrackMenuHudMode
                                                   tab:_selectedTab];
}

#pragma mark - UITabBarDelegate

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    _selectedTab = (EOATrackMenuHudTab) item.tag;

    [self setupTableView];
    [self setupDescription];
    [self generateData];
    [self setupHeaderView];

    switch (_selectedTab)
    {
        case EOATrackMenuHudActionsTab:
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
        [self.mapPanelViewController openTrackAppearance:self.gpx
                                       trackMenuDelegate:self];
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
        [self generateData:EOATrackMenuHudActionsChangeSection row:EOATrackMenuHudActionsChangeMoveRow];
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

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.tableData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ((NSArray *) self.tableData[section][@"cells"]).count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.tableData[section][@"group_name"];
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
            NSArray *nib = [[NSBundle mainBundle]loadNibNamed:[OATextViewSimpleCell getCellIdentifier] owner:self options:nil];
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
    else if ([item[@"type"] isEqualToString:[OATitleIconRoundCell getCellIdentifier]])
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
            cell.titleView.text = item[@"title"];
            cell.textColorNormal = [item[@"key"] isEqualToString:@"delete"]
                    ? UIColorFromRGB(color_primary_red) : UIColor.blackColor;

            UIColor *tintColor = [item[@"key"] isEqualToString:@"delete"]
                    ? UIColorFromRGB(color_primary_red) : UIColorFromRGB(color_primary_purple);
            cell.iconColorNormal = tintColor;
            cell.iconView.image = [UIImage templateImageNamed:item[@"icon"]];

            BOOL isLast = indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1;
            [cell roundCorners:(indexPath.row == 0) bottomCorners:isLast];
            cell.separatorView.hidden = isLast;
        }
        outCell = cell;
    }
    else if ([item[@"type"] isEqualToString:[OATitleDescriptionIconRoundCell getCellIdentifier]])
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
            cell.titleView.text = item[@"title"];
            cell.descrView.text = item[@"desc"];

            cell.iconView.image = [UIImage templateImageNamed:item[@"icon"]];

            BOOL isLast = indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1;
            [cell roundCorners:(indexPath.row == 0) bottomCorners:isLast];
            cell.separatorView.hidden = isLast;
        }
        outCell = cell;
    }
    else if ([item[@"type"] isEqualToString:[OATitleSwitchRoundCell getCellIdentifier]])
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
            cell.titleView.text = item[@"title"];

            BOOL isLast = indexPath.row == [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1;
            [cell roundCorners:(indexPath.row == 0) bottomCorners:isLast];
            cell.separatorView.hidden = isLast;

            cell.switchView.on = [self isEnabled:item[@"key"]];

            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(onSwitchPressed:) forControlEvents:UIControlEventValueChanged];
        }
        outCell = cell;
    }

    if ([outCell needsUpdateConstraints])
        [outCell updateConstraints];

    return outCell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)heightForRow:(NSIndexPath *)indexPath estimated:(BOOL)estimated
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OATitleSwitchRoundCell getCellIdentifier]]
            || [item[@"type"] isEqualToString:[OATitleIconRoundCell getCellIdentifier]]
            || [item[@"type"] isEqualToString:[OAIconTitleValueCell getCellIdentifier]]
            || [item[@"type"] isEqualToString:[OATextLineViewCell getCellIdentifier]])
        return 48.;
    else if ([item[@"type"] isEqualToString:[OATitleDescriptionIconRoundCell getCellIdentifier]])
        return 60.;
    else
        return estimated ? 48. : UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath estimated:NO];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (_selectedTab == EOATrackMenuHudOverviewTab)
        return 56.;
    else if (_selectedTab == EOATrackMenuHudActionsTab)
        return 20.;
    else
        return 0.01;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];

    if ([item[@"key"] isEqualToString:@"full_description"])
    {
        OATrackMenuDescriptionViewController *descriptionViewController =
                [[OATrackMenuDescriptionViewController alloc] initWithGpxDoc:self.doc gpx:self.gpx];
        [self.navigationController pushViewController:descriptionViewController animated:YES];
    }
    else if ([item[@"key"] isEqualToString:@"control_appearance"])
    {
        [self onAppearancePressed:nil];
    }
    else if ([item[@"key"] isEqualToString:@"control_navigation"])
    {
        [self onNavigationPressed:nil];
    }
    else if ([item[@"key"] isEqualToString:@"analyze"])
    {
        [self openAnalysis:EOARouteStatisticsModeBoth];
    }
    else if ([item[@"key"] isEqualToString:@"share"])
    {
        [self onExportPressed:nil];
    }
    else if ([item[@"key"] isEqualToString:@"edit"])
    {
        [self hide:YES duration:.2 onComplete:^{
            [self.mapPanelViewController targetOpenPlanRoute:self.gpx trackMenuDelegate:self];
        }];
    }
    else if ([item[@"key"] isEqualToString:@"edit_create_duplicate"])
    {
        OASaveTrackViewController *saveTrackViewController = [[OASaveTrackViewController alloc]
                initWithFileName:[self.gpx.gpxFilePath.lastPathComponent.stringByDeletingPathExtension stringByAppendingString:@"_copy"]
                        filePath:self.gpx.gpxFilePath
                       showOnMap:YES
                 simplifiedTrack:NO];

        saveTrackViewController.delegate = self;
        [self presentViewController:saveTrackViewController animated:YES completion:nil];
    }
    else if ([item[@"key"] isEqualToString:@"change_rename"])
    {
        [self showAlertRenameTrack];
    }
    else if ([item[@"key"] isEqualToString:@"change_move"])
    {
        OASelectTrackFolderViewController *selectFolderView = [[OASelectTrackFolderViewController alloc] initWithGPX:self.gpx];
        selectFolderView.delegate = self;
        [self presentViewController:selectFolderView animated:YES completion:nil];
    }
    else if ([item[@"key"] isEqualToString:@"delete"])
    {
        [self showAlertDeleteTrack];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UISwitch pressed

- (void)onSwitchPressed:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:switchView.tag & 0x3FF inSection:switchView.tag >> 10];
    NSDictionary *item = [self getItem:indexPath];

    if ([item[@"key"] isEqualToString:@"control_show_on_map"])
        [self onShowHidePressed:nil];

    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

@end
