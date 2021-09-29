//
//  OATrackMenuAppearanceHudViewController.mm
//  OsmAnd
//
//  Created by Skalii on 25.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OATrackMenuAppearanceHudViewController.h"
#import "OAMapPanelViewController.h"
#import "OATableViewCustomFooterView.h"
#import "OAIconTextDividerSwitchCell.h"
#import "OAIconTitleValueCell.h"
#import "OAColorsTableViewCell.h"
#import "OATextLineViewCell.h"
#import "OASegmentSliderTableViewCell.h"
#import "OASegmentedControlCell.h"
#import "OADividerCell.h"
#import "OAFoldersCell.h"
#import "Localization.h"
#import "OAColors.h"
#import "OASavingTrackHelper.h"
#import "OAGPXDatabase.h"
#import "OAGPXTrackColorCollection.h"
#import "OAColoringType.h"

typedef NS_ENUM(NSUInteger, EOATrackAppearanceHudSection)
{
    EOATrackAppearanceHudIconsSection = 0,
    EOATrackAppearanceHudColorsSection,
    EOATrackAppearanceHudWidthSection,
    EOATrackAppearanceHudSplitIntervalSection,
    EOATrackAppearanceHudJoinGapsSection,
    EOATrackAppearanceHudResetSection
};

typedef NS_ENUM(NSUInteger, EOATrackAppearanceHudColorRow)
{
    EOATrackAppearanceHudColorTitleRow = 0,
    EOATrackAppearanceHudColorValuesRow,
    EOATrackAppearanceHudColorGridOrElevationDescriptionRow,
    EOATrackAppearanceHudColorElevationSliderRow,
    EOATrackAppearanceHudColorSlopeDescriptionRow
};

typedef NS_ENUM(NSUInteger, EOATrackAppearanceHudWidthRow)
{
    EOATrackAppearanceHudWidthTitleRow = 0,
    EOATrackAppearanceHudWidthValuesRow,
    EOATrackAppearanceHudWidthEmptySpaceRow,
    EOATrackAppearanceHudWidthCustomIntervalRow
};

@interface OATrackMenuAppearanceHudViewController() <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, OAFoldersCellDelegate, OAColorsTableViewCellDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIImageView *titleIconView;

@property (weak, nonatomic) IBOutlet UIView *doneButtonContainerView;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *doneButtonTrailingConstraint;

@property (nonatomic) OAMapPanelViewController *mapPanelViewController;
@property (nonatomic) OAMapViewController *mapViewController;

@property (nonatomic) OsmAndAppInstance app;
@property (nonatomic) OAAppSettings *settings;
@property (nonatomic) OASavingTrackHelper *savingHelper;

@property (nonatomic) OAGPX *gpx;
@property (nonatomic) OAGPXDocument *doc;
@property (nonatomic) BOOL isCurrentTrack;
@property (nonatomic) BOOL isShown;

@property (nonatomic) NSArray<NSDictionary *> *data;

@end

@implementation OATrackMenuAppearanceHudViewController
{
    OAFoldersCell *_colorValuesCell;
    OACollectionViewCellState *_scrollCellsState;
    OAColoringType *_selectedColoringType;
    NSArray<OAColoringType *> *_availableColoringTypes;
    NSArray<NSNumber *> *_availableTrackColors;

    NSArray<NSString *> *_widthTypes;
    NSString *_selectedWidthType;
    NSArray<NSNumber *> *_widthValues;
    NSInteger _selectedWidthValue;
}

- (instancetype)initWithGpx:(OAGPX *)gpx
{
    self = [super initWithNibName:@"OATrackMenuAppearanceHudViewController" bundle:nil];
    if (self)
    {
        self.gpx = gpx;
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    [super commonInit];

    _scrollCellsState = [[OACollectionViewCellState alloc] init];
    _selectedColoringType = [OAColoringType getNonNullTrackColoringTypeByName:self.gpx.coloringType];

    NSMutableArray<OAColoringType *> *coloringTypes = [NSMutableArray array];
    for (OAColoringType *coloringType in [OAColoringType getTrackColoringTypes])
    {
        if ([coloringType isAvailableForDrawingTrack:self.doc attributeName:nil])
            [coloringTypes addObject:coloringType];
    }
    _availableColoringTypes = coloringTypes;

    OAGPXTrackColorCollection *colorCollection = [[OAGPXTrackColorCollection alloc] initWithMapViewController:_mapViewController];
    NSMutableArray<NSNumber *> *trackColors = [NSMutableArray array];
    for (OAGPXTrackColor *trackColor in [colorCollection getAvailableGPXColors])
    {
        [trackColors addObject:@((int) trackColor.colorValue)];
    }
    _availableTrackColors = trackColors;

    _widthTypes = @[@"Thin", @"Medium", @"Bold", @"Custom"];
    _selectedWidthType = _widthTypes.firstObject;
    _widthValues = @[@1, @2, @3, @4, @5, @6, @7, @8, @9, @10];
    _selectedWidthValue = [_widthValues.firstObject intValue];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:OATableViewCustomFooterView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomFooterView getCellIdentifier]];

    if (!self.isShown)
        [self.settings showGpx:@[self.gpx.gpxFilePath] update:YES];
}

- (void)applyLocalization
{
    [self.titleView setText:OALocalizedString(@"map_settings_appearance")];
    [self.doneButton.titleLabel setText:OALocalizedString(@"shared_string_done")];
}

- (void)setupView
{
    [super setupView];

    self.titleIconView.image = [UIImage templateImageNamed:@"ic_custom_appearance"];
    self.titleIconView.tintColor = UIColorFromRGB(color_footer_icon_gray);

    [self.doneButton addBlurEffect:YES cornerRadius:12. padding:0];

    CGRect toolBarFrame = self.toolBarView.frame;
    toolBarFrame.origin.y = self.scrollableView.frame.size.height;
    toolBarFrame.size.height = 0;
    self.toolBarView.frame = toolBarFrame;
}

- (void)setupHeaderView
{
    [super setupHeaderView];
}

- (void)generateData
{
    [super generateData];

    NSMutableArray *data = [NSMutableArray array];

    [data addObject:@{
            @"cells": @[@{
                    @"title": OALocalizedString(@"gpx_dir_arrows"),
                    @"value": @NO,
                    @"type": [OAIconTextDividerSwitchCell getCellIdentifier],
                    @"key": @"direction_arrows"
            }, @{
                    @"title": OALocalizedString(@"track_show_start_finish_icons"),
                    @"value": @NO,
                    @"type": [OAIconTextDividerSwitchCell getCellIdentifier],
                    @"key": @"start_finish_icons"
            }]
    }];

    NSMutableArray *colorSectionData = [NSMutableArray array];

    [colorSectionData addObject:@{
            @"title": OALocalizedString(@"fav_color"),
            @"value": _selectedColoringType.title,
            @"type": [OAIconTitleValueCell getCellIdentifier],
            @"key": @"color_title"
    }];

    NSMutableArray<NSDictionary *> *trackColoringTypes = [NSMutableArray array];
    for (OAColoringType *type in _availableColoringTypes)
    {
        [trackColoringTypes addObject:@{
                @"title": type.title,
                @"type": type.name
        }];
    }

    [colorSectionData addObject:@{
            @"values": trackColoringTypes,
            @"type": [OAFoldersCell getCellIdentifier],
            @"key": @"color_values"
    }];

    if (_selectedColoringType.isTrackSolid)
    {
        [colorSectionData addObject:@{
                @"type": [OAColorsTableViewCell getCellIdentifier],
                @"key": @"color_grid"
        }];
    }
    else if (_selectedColoringType.isGradient)
    {
        [colorSectionData addObject:@{
                @"title": OALocalizedString(@"route_line_color_elevation_description"),
                @"type": [OATextLineViewCell getCellIdentifier],
                @"key": @"color_elevation_description"
        }];
    }

    [data addObject:@{
            @"cells": colorSectionData
    }];

    NSMutableArray *widthSectionData = [NSMutableArray array];

    [widthSectionData addObject:@{
            @"title": OALocalizedString(@"shared_string_width"),
            @"value": _selectedWidthType,
            @"type": [OAIconTitleValueCell getCellIdentifier],
            @"key": @"width_title"
    }];

//    for (NSString *widthType in _widthTypes)
    [widthSectionData addObject:@{
            @"selected_index": @([_widthTypes indexOfObject:_selectedWidthType]),
            @"values": @[@{
                    @"value": @"Thin",
                    @"icon": @"ic_custom_track_line_thin"
            }, @{
                    @"value": @"Medium",
                    @"icon": @"ic_custom_track_line_medium"
            }, @{
                    @"value": @"Bold",
                    @"icon": @"ic_custom_track_line_bold"
            }, @{
                    @"value": @"Custom",
                    @"icon": @"ic_custom_slider"
            }],
            @"with_images": @YES,
            @"type": [OASegmentedControlCell getCellIdentifier],
            @"key": @"width_value"
    }];

    [widthSectionData addObject:@{
            @"value": @14,
            @"type": [OADividerCell getCellIdentifier],
            @"key": @"width_empty_space"
    }];


    if ([_selectedWidthType isEqualToString:@"Custom"])
    {
        [widthSectionData addObject:@{
                @"selected_index": @(_selectedWidthValue),
                @"values": _widthValues,
                @"type": [OASegmentSliderTableViewCell getCellIdentifier],
                @"key": @"width_custom_interval"
        }];
    }

    [data addObject:@{
            @"cells": widthSectionData
    }];

    NSMutableArray *splitSectionData = [NSMutableArray array];

    [splitSectionData addObject:@{
            @"title": OALocalizedString(@"gpx_split_interval"),
            @"value": @"None",
            @"type": [OAIconTitleValueCell getCellIdentifier],
            @"key": @"split_title"
    }];

    //    OASliderWithValuesCell

    [data addObject:@{
            @"cells": splitSectionData,
            @"footer": OALocalizedString(@"gpx_split_interval_descr")
    }];

    [data addObject:@{
            @"cells": @[@{
                    @"title": OALocalizedString(@"gpx_join_gaps"),
                    @"value": @NO,
                    @"type": [OAIconTextDividerSwitchCell getCellIdentifier],
                    @"key": @"join_gaps"
            }],
            @"footer": OALocalizedString(@"gpx_join_gaps_descr")
    }];

    [data addObject:@{
            @"header": OALocalizedString(@"actions"),
            @"cells": @[@{
                    @"title": OALocalizedString(@"reset_to_original"),
                    @"right_icon": @"ic_custom_reset",
                    @"has_options": @YES,
                    @"type": [OAIconTitleValueCell getCellIdentifier],
                    @"key": @"reset"
            }]
    }];

    self.data = data;
}

- (void)generateData:(EOATrackAppearanceHudSection)section
{
    NSDictionary *sectionData = ((NSMutableArray *) self.data)[section];
    if (sectionData)
    {
        NSMutableArray *cells = sectionData[@"cells"];
        if (cells && cells.count > 0)
        {
            if (section == EOATrackAppearanceHudColorsSection)
            {
                NSMutableDictionary *titleRow = [cells[EOATrackAppearanceHudColorTitleRow] mutableCopy];
                if (titleRow)
                {
                    titleRow[@"value"] = _selectedColoringType.title;
                    cells[EOATrackAppearanceHudColorTitleRow] = titleRow;

                    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:EOATrackAppearanceHudColorTitleRow
                                                                                inSection:section]]
                                          withRowAnimation:UITableViewRowAnimationNone];
                }

                NSMutableDictionary *gridOrElevationDescriptionRow =
                        [cells[EOATrackAppearanceHudColorGridOrElevationDescriptionRow] mutableCopy];
                if (gridOrElevationDescriptionRow)
                {
                    if ([_selectedColoringType isTrackSolid])
                    {
                        gridOrElevationDescriptionRow[@"type"] = [OAColorsTableViewCell getCellIdentifier];
                        gridOrElevationDescriptionRow[@"key"] = @"color_grid";
                    }
                    else if ([_selectedColoringType isGradient])
                    {
                        gridOrElevationDescriptionRow[@"title"] = OALocalizedString(@"route_line_color_elevation_description");
                        gridOrElevationDescriptionRow[@"type"] = [OATextLineViewCell getCellIdentifier];
                        gridOrElevationDescriptionRow[@"key"] = @"color_elevation_description";

                        if ([_selectedColoringType isSlope])
                        {

                        }
                    }
                    cells[EOATrackAppearanceHudColorGridOrElevationDescriptionRow] = gridOrElevationDescriptionRow;

                    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:EOATrackAppearanceHudColorGridOrElevationDescriptionRow
                                                                                inSection:section]]
                                          withRowAnimation:UITableViewRowAnimationNone];
                }
            }
            else if (section == EOATrackAppearanceHudWidthSection)
            {
                NSMutableDictionary *titleRow = [cells[EOATrackAppearanceHudWidthTitleRow] mutableCopy];
                if (titleRow)
                {
                    titleRow[@"value"] = _selectedWidthType;
                    cells[EOATrackAppearanceHudWidthTitleRow] = titleRow;

                    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:EOATrackAppearanceHudWidthTitleRow
                                                                                inSection:section]]
                                          withRowAnimation:UITableViewRowAnimationNone];
                }

                if (cells.count == EOATrackAppearanceHudWidthCustomIntervalRow + 1 && ![_selectedWidthType isEqualToString:@"Custom"])
                {
                    [cells removeObjectAtIndex:EOATrackAppearanceHudWidthCustomIntervalRow];

                    [self.tableView beginUpdates];
                    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:EOATrackAppearanceHudWidthCustomIntervalRow
                                                                                inSection:section]]
                                          withRowAnimation:UITableViewRowAnimationAutomatic];
                    [self.tableView endUpdates];
                }
                else if (cells.count == EOATrackAppearanceHudWidthEmptySpaceRow + 1 && [_selectedWidthType isEqualToString:@"Custom"])
                {
                    [cells addObject:@{
                            @"selected_index": @(_selectedWidthValue),
                            @"values": _widthValues,
                            @"type": [OASegmentSliderTableViewCell getCellIdentifier],
                            @"key": @"width_custom_interval"
                    }];

                    [self.tableView beginUpdates];
                    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:EOATrackAppearanceHudWidthCustomIntervalRow
                                                                                inSection:section]]
                                          withRowAnimation:UITableViewRowAnimationAutomatic];
                    [self.tableView endUpdates];
                }
            }
        }
    }
}

- (void)doAdditionalLayout
{
    [super doAdditionalLayout];

    self.doneButtonContainerView.hidden = ![self isLandscape] && self.currentState == EOADraggableMenuStateFullScreen;
}

- (CGFloat)getToolbarHeight
{
    return 0;
}

- (BOOL)isEnabled:(NSString *)key
{
    if ([key isEqualToString:@"direction_arrows"])
        return self.gpx.showArrows;
    else if ([key isEqualToString:@"start_finish_icons"])
        return self.gpx.showStartFinish;
    else if ([key isEqualToString:@"join_gaps"])
        return self.gpx.joinSegments;

    return NO;
}

- (CGFloat)heightForHeader:(NSInteger)section
{
    if (section == 0)
        return 0.001;

    NSString *sectionHeader = [self.data[section][@"header"] upperCase];
    if (!sectionHeader || sectionHeader.length == 0)
        return 36.;

    CGFloat textWidth = self.tableView.bounds.size.width - 40 - OAUtilities.getLeftMargin * 2;
    CGFloat labelHeight = [OAUtilities heightForHeaderViewText:sectionHeader
                                                         width:textWidth
                                                          font:[UIFont systemFontOfSize:13]
                                                   lineSpacing:6.];

    return labelHeight + 36.;
}

- (CGFloat)heightForFooter:(NSInteger)section
{
    NSString *sectionDescription = self.data[section][@"footer"];
    if (!sectionDescription || sectionDescription.length == 0)
        return 0.001;

    return [OATableViewCustomFooterView getHeight:sectionDescription width:self.tableView.bounds.size.width];
}

- (IBAction)onBackButtonPressed:(id)sender
{
    [self dismiss:^{
        [self.mapPanelViewController openTargetViewWithGPX:self.gpx trackHudMode:EOATrackMenuHudMode];
    }];}

- (IBAction)onDoneButtonPressed:(id)sender
{
    [self dismiss:^{
        [self.mapPanelViewController openTargetViewWithGPX:self.gpx trackHudMode:EOATrackMenuHudMode];
    }];}

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
    return self.data[section][@"header"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    BOOL isOn = [self isEnabled:item[@"key"]];
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
            cell.separatorInset = UIEdgeInsetsMake(0., self.tableView.frame.size.width, 0., 0.);
        }
        if (cell)
        {
            cell.selectionStyle = hasOptions ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
            cell.textView.text = item[@"title"];
            cell.descriptionView.text = item[@"value"];
            cell.textView.textColor = hasOptions ? UIColorFromRGB(color_primary_purple) : UIColor.blackColor;
            if (hasOptions)
            {
                cell.rightIconView.image = [UIImage templateImageNamed:item[@"right_icon"]];
                cell.rightIconView.tintColor = UIColorFromRGB(color_primary_purple);
            }
            [cell showRightIcon:hasOptions];
        }
        outCell = cell;
    }
    else if ([item[@"type"] isEqualToString:[OAIconTextDividerSwitchCell getCellIdentifier]])
    {
        OAIconTextDividerSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTextDividerSwitchCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextDividerSwitchCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTextDividerSwitchCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsMake(0., 20., 0., 0.);
            cell.dividerView.hidden = YES;
            cell.iconView.image = nil;
        }
        if (cell)
        {
            cell.switchView.on = isOn;
            cell.textView.text = item[@"title"];

            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(onSwitchPressed:) forControlEvents:UIControlEventValueChanged];
        }
        outCell = cell;
    }
    else if ([item[@"type"] isEqualToString:[OAFoldersCell getCellIdentifier]])
    {
        OAFoldersCell *cell = _colorValuesCell;
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAFoldersCell getCellIdentifier] owner:self options:nil];
            cell = (OAFoldersCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsMake(0., DeviceScreenWidth, 0., 0.);
            cell.backgroundColor = UIColor.whiteColor;
            cell.collectionView.backgroundColor = UIColor.whiteColor;
            cell.cellIndex = indexPath;
            cell.state = _scrollCellsState;
            cell.delegate = self;
        }
        if (cell)
        {
            [cell setValues:item[@"values"] withSelectedIndex:[_availableColoringTypes indexOfObject:_selectedColoringType]];
        }
        outCell = _colorValuesCell = cell;
    }
    else if ([item[@"type"] isEqualToString:[OAColorsTableViewCell getCellIdentifier]])
    {
        OAColorsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAColorsTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAColorsTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAColorsTableViewCell *) nib[0];
            cell.dataArray = _availableTrackColors;
            cell.delegate = self;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.titleLabel.text = @"title";
            cell.valueLabel.text = @"value";
            cell.valueLabel.tintColor = UIColorFromRGB(color_text_footer);
            cell.currentColor = [_availableTrackColors indexOfObject:@((int) self.gpx.color)];

            [cell.collectionView reloadData];
            [cell layoutIfNeeded];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OATextLineViewCell getCellIdentifier]])
    {
        OATextLineViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OATextLineViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextLineViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATextLineViewCell *) nib[0];
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            cell.textView.font = [UIFont systemFontOfSize:15];
            cell.textView.textColor = UIColorFromRGB(color_text_footer);
        }
        outCell = cell;
    }
    else if ([item[@"type"] isEqualToString:[OASegmentedControlCell getCellIdentifier]])
    {
        OASegmentedControlCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASegmentedControlCell getCellIdentifier]];
        NSArray<NSDictionary *> *values = item[@"values"];
        BOOL withImages = [item[@"with_images"] boolValue];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASegmentedControlCell getCellIdentifier] owner:self options:nil];
            cell = (OASegmentedControlCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsMake(0., self.tableView.frame.size.width, 0., 0.);
            cell.backgroundColor = UIColor.whiteColor;
            cell.segmentedControl.backgroundColor = [UIColorFromRGB(color_primary_purple) colorWithAlphaComponent:.1];
            [cell changeHeight:YES];

            [cell.segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName : UIColor.whiteColor} forState:UIControlStateSelected];
            [cell.segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName : UIColorFromRGB(color_primary_purple)} forState:UIControlStateNormal];

            if (@available(iOS 13.0, *))
                cell.segmentedControl.selectedSegmentTintColor = UIColorFromRGB(color_primary_purple);
            else
                cell.segmentedControl.tintColor = UIColorFromRGB(color_primary_purple);
        }
        if (cell)
        {
            int i = 0;
            for (NSDictionary *value in values)
            {
                if (withImages)
                {
                    UIImage *icon = [UIImage templateImageNamed:value[@"icon"]];
                    if (i == cell.segmentedControl.numberOfSegments)
                        [cell.segmentedControl insertSegmentWithImage:icon atIndex:i++ animated:NO];
                    else
                        [cell.segmentedControl setImage:icon forSegmentAtIndex:i++];
                }
                else
                {
                    NSString *title = value[@"title"];
                    if (i == cell.segmentedControl.numberOfSegments)
                        [cell.segmentedControl insertSegmentWithTitle:title atIndex:i++ animated:NO];
                    else
                        [cell.segmentedControl setTitle:title forSegmentAtIndex:i++];
                }
            }
            [cell.segmentedControl setSelectedSegmentIndex:[item[@"selected_index"] intValue]];

            cell.segmentedControl.tag = indexPath.section << 10 | indexPath.row;
            [cell.segmentedControl removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.segmentedControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
        }
        outCell = cell;
    }
    else if ([item[@"type"] isEqualToString:[OADividerCell getCellIdentifier]])
    {
        OADividerCell *cell = [tableView dequeueReusableCellWithIdentifier:[OADividerCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADividerCell getCellIdentifier] owner:self options:nil];
            cell = (OADividerCell *) nib[0];
            cell.backgroundColor = UIColor.whiteColor;
            cell.dividerColor = UIColor.whiteColor;
            cell.dividerInsets = UIEdgeInsetsZero;
            cell.separatorInset = UIEdgeInsetsMake(0., self.tableView.frame.size.width, 0., 0.);
            cell.dividerHight = 0.;
        }
        outCell = cell;
    }
    else if ([item[@"type"] isEqualToString:[OASegmentSliderTableViewCell getCellIdentifier]])
    {
        OASegmentSliderTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASegmentSliderTableViewCell getCellIdentifier]];
        NSArray<NSNumber *> *values = item[@"values"];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASegmentSliderTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASegmentSliderTableViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            [cell.sliderView removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
            cell.titleLabel.text = [NSString stringWithFormat:@"%li", (long) [values.firstObject intValue]];
            cell.valueLabel.text = [NSString stringWithFormat:@"%li", (long) [values.lastObject intValue]];
            cell.numberOfMarks = values.count;
            cell.selectedMark = [item[@"selected_index"] intValue];

            cell.sliderView.tag = indexPath.section << 10 | indexPath.row;
            [cell.sliderView removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
            [cell.sliderView addTarget:self action:@selector(sliderChanged:) forControlEvents:UIControlEventTouchUpInside];
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
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OADividerCell getCellIdentifier]])
        return [item[@"value"] floatValue];

    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self heightForHeader:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return [self heightForFooter:section];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    NSString *sectionFooter = self.data[section][@"footer"];
    if (!sectionFooter || sectionFooter.length == 0)
        return nil;

    OATableViewCustomFooterView *vw = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
    UIFont *textFont = [UIFont systemFontOfSize:13];
    NSMutableAttributedString *textStr = [[NSMutableAttributedString alloc]
            initWithString:sectionFooter
            attributes:@{NSFontAttributeName: textFont,
                    NSForegroundColorAttributeName: UIColorFromRGB(color_text_footer)}];
    vw.label.attributedText = textStr;
    return vw;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];

    if ([item[@"key"] isEqualToString:@"reset"])
    {

    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UISwitch pressed

- (void)onSwitchPressed:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:switchView.tag & 0x3FF inSection:switchView.tag >> 10];
    NSDictionary *item = [self getItem:indexPath];

    if ([item[@"key"] isEqualToString:@"direction_arrows"])
        self.gpx.showArrows = switchView.isOn;
    else if ([item[@"key"] isEqualToString:@"start_finish_icons"])
        self.gpx.showStartFinish = switchView.isOn;
    else if ([item[@"key"] isEqualToString:@"join_gaps"])
        self.gpx.joinSegments = switchView.isOn;

    [[OAGPXDatabase sharedDb] save];

    [[self.app updateGpxTracksOnMapObservable] notifyEvent];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - UISegmentedControl pressed

- (void)segmentChanged:(id)sender
{
    UISegmentedControl *segment = (UISegmentedControl *) sender;
    if (segment)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:segment.tag & 0x3FF inSection:segment.tag >> 10];
        NSDictionary *item = [self getItem:indexPath];

        if ([item[@"key"] isEqualToString:@"width_value"])
        {
            _selectedWidthType = _widthTypes[segment.selectedSegmentIndex];
//        [[self.app updateGpxTracksOnMapObservable] notifyEvent];
            [self generateData:EOATrackAppearanceHudWidthSection];
        }
    }
}

#pragma mark - UISlider pressed

- (void)sliderChanged:(id)sender
{
    UISlider *slider = (UISlider *) sender;
    if (sender)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:slider.tag & 0x3FF inSection:slider.tag >> 10];
        OASegmentSliderTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        NSDictionary *item = [self getItem:indexPath];

        if ([item[@"key"] isEqualToString:@"width_custom_interval"])
        {
            NSInteger index = cell.selectedMark;
            NSInteger selectedValue = [_widthValues[index] intValue];
            if (_selectedWidthValue != selectedValue)
            {
                _selectedWidthValue = selectedValue;

//            [[self.app updateGpxTracksOnMapObservable] notifyEvent];
                [self generateData:EOATrackAppearanceHudWidthSection];
            }
        }
    }
}

#pragma mark - OAFoldersCellDelegate

- (void)onItemSelected:(NSInteger)index type:(NSString *)type
{
    _selectedColoringType = _availableColoringTypes[index];
    self.gpx.coloringType = _selectedColoringType.name;
    [[OAGPXDatabase sharedDb] save];

    [[self.app updateGpxTracksOnMapObservable] notifyEvent];
    [self generateData:EOATrackAppearanceHudColorsSection];
}

#pragma mark - OAColorsTableViewCellDelegate

- (void)colorChanged:(NSInteger)tag
{
    self.gpx.color = [_availableTrackColors[tag] intValue];
    [[OAGPXDatabase sharedDb] save];

    [[self.app updateGpxTracksOnMapObservable] notifyEvent];
    [self generateData:EOATrackAppearanceHudColorsSection];
}

@end
