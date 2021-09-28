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
#import "OASliderWithValuesCell.h"
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
            @"value": @"Custom",
            @"type": [OAIconTitleValueCell getCellIdentifier],
            @"key": @"width_title"
    }];

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
            if (hasOptions)
            {
                cell.textView.textColor = UIColorFromRGB(color_primary_purple);
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
        OAFoldersCell *cell = /*[tableView dequeueReusableCellWithIdentifier:[OAFoldersCell getCellIdentifier]];*/_colorValuesCell;
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAFoldersCell getCellIdentifier] owner:self options:nil];
            cell = (OAFoldersCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsMake(0., DeviceScreenWidth, 0., 0.);
            cell.backgroundColor = UIColor.whiteColor;
            cell.collectionView.backgroundColor = UIColor.whiteColor;
            cell.delegate = self;
            cell.cellIndex = indexPath;
            cell.state = _scrollCellsState;
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

    if ([outCell needsUpdateConstraints])
        [outCell updateConstraints];

    return outCell;
}

#pragma mark - UITableViewDelegate

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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self heightForHeader:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return [self heightForFooter:section];
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
