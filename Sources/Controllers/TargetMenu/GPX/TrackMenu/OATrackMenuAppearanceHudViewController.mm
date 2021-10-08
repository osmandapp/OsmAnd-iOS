//
//  OATrackMenuAppearanceHudViewController.mm
//  OsmAnd
//
//  Created by Skalii on 25.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OATrackMenuAppearanceHudViewController.h"
#import "OATableViewCustomFooterView.h"
#import "OAIconTextDividerSwitchCell.h"
#import "OAIconTitleValueCell.h"
#import "OAColorsTableViewCell.h"
#import "OATextLineViewCell.h"
#import "OASegmentSliderTableViewCell.h"
#import "OASegmentedControlCell.h"
#import "OADividerCell.h"
#import "OAFoldersCell.h"
#import "OAImageTextViewCell.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAOsmAndFormatter.h"
#import "OAGPXDatabase.h"
#import "OAGPXTrackAnalysis.h"
#import "OAGPXAppearanceCollection.h"
#import "OAColoringType.h"

#define kIconsSection @"icons_section"
#define kColorsSection @"colors_section"
#define kWidthSection @"width_section"
#define kActionsSection @"actions_section"

typedef NS_ENUM(NSUInteger, EOATrackAppearanceHudSection)
{
    EOATrackAppearanceHudIconsSection = 0,
    EOATrackAppearanceHudColorsSection,
    EOATrackAppearanceHudWidthSection,
    EOATrackAppearanceHudActionsSection
};

typedef NS_ENUM(NSUInteger, EOATrackAppearanceHudColorRow)
{
    EOATrackAppearanceHudColorTitleRow = 0,
    EOATrackAppearanceHudColorValuesRow,
    EOATrackAppearanceHudColorGridOrElevationDescRow,
    EOATrackAppearanceHudColorGradientAndDescRow
};

typedef NS_ENUM(NSUInteger, EOATrackAppearanceHudWidthRow)
{
    EOATrackAppearanceHudWidthTitleRow = 0,
    EOATrackAppearanceHudWidthValuesRow,
    EOATrackAppearanceHudWidthEmptySpaceRow,
    EOATrackAppearanceHudWidthCustomSliderRow
};

static const NSInteger kCustomTrackWidthMin = 1;
static const NSInteger kCustomTrackWidthMax = 24;

@interface OATrackMenuAppearanceHudViewController() <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, OAFoldersCellDelegate, OAColorsTableViewCellDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIImageView *titleIconView;

@property (weak, nonatomic) IBOutlet UIView *doneButtonContainerView;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *doneButtonTrailingConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomSeparatorHeight;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomSeparatorTopConstraint;

@property (nonatomic) NSArray<NSDictionary *> *tableData;
@property (nonatomic) OAGPX *gpx;
@property (nonatomic) BOOL isShown;
@property (nonatomic) OATableData *menuTableData;

@end

@implementation OATrackMenuAppearanceHudViewController
{
    OAGPXAppearanceCollection *_appearanceCollection;

    OAFoldersCell *_colorValuesCell;
    OACollectionViewCellState *_scrollCellsState;
    OAColoringType *_selectedColoringType;
    NSArray<OAColoringType *> *_availableColoringTypes;

    OAGPXTrackColor *_selectedColor;
    NSArray<NSNumber *> *_availableColors;

    OASegmentedControlCell *_widthValuesCell;
    OAGPXTrackWidth *_selectedWidth;
    NSArray<NSNumber *> *_customWidthValues;

    NSInteger _oldColor;
    BOOL _oldShowArrows;
    NSString *_oldWidth;
    NSString *_oldColoringType;
}

@dynamic tableData, gpx, isShown, menuTableData;

- (NSString *)getNibName
{
    return @"OATrackMenuAppearanceHudViewController";
}

- (void)commonInit
{
    _oldColor = self.gpx.color;
    _oldShowArrows = self.gpx.showArrows;
    _oldWidth = self.gpx.width;
    _oldColoringType = self.gpx.coloringType;

    _appearanceCollection = [[OAGPXAppearanceCollection alloc] init];
    _selectedColor = [_appearanceCollection getColorForValue:self.gpx.color];
    _selectedWidth = [_appearanceCollection getWidthForValue:self.gpx.width];
    if (!_selectedWidth)
        _selectedWidth = [OAGPXTrackWidth getDefault];

    _scrollCellsState = [[OACollectionViewCellState alloc] init];
    _selectedColoringType = [OAColoringType getNonNullTrackColoringTypeByName:self.gpx.coloringType];

    NSMutableArray<OAColoringType *> *coloringTypes = [NSMutableArray array];
    for (OAColoringType *coloringType in [OAColoringType getTrackColoringTypes])
    {
        [coloringTypes addObject:coloringType];
    }
    _availableColoringTypes = coloringTypes;

    NSMutableArray<NSNumber *> *trackColors = [NSMutableArray array];
    for (OAGPXTrackColor *trackColor in [_appearanceCollection getAvailableColors])
    {
        [trackColors addObject:@(trackColor.colorValue)];
    }
    _availableColors = trackColors;

    NSMutableArray *customWidthValues = [NSMutableArray array];
    for (NSInteger i = kCustomTrackWidthMin; i <= kCustomTrackWidthMax; i++)
    {
        [customWidthValues addObject:@(i)];
    }
    _customWidthValues = customWidthValues;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.sectionHeaderHeight = 36.;
    self.tableView.sectionFooterHeight = 0.001;
    [self.tableView registerClass:OATableViewCustomFooterView.class
        forHeaderFooterViewReuseIdentifier:[OATableViewCustomFooterView getCellIdentifier]];

    self.bottomSeparatorHeight.constant = 0.5;
    self.bottomSeparatorTopConstraint.constant = -0.5;

    if (!self.isShown)
    {
        [self.settings showGpx:@[self.gpx.gpxFilePath] update:YES];
        self.isShown = YES;
    }
}

- (void)applyLocalization
{
    [self.titleView setText:OALocalizedString(@"map_settings_appearance")];
    [self.doneButton.titleLabel setText:OALocalizedString(@"shared_string_done")];
}

- (void)setupView
{
    self.titleIconView.image = [UIImage templateImageNamed:@"ic_custom_appearance"];
    self.titleIconView.tintColor = UIColorFromRGB(color_footer_icon_gray);

    [self.doneButton addBlurEffect:YES cornerRadius:12. padding:0.];

    CGRect toolBarFrame = self.toolBarView.frame;
    toolBarFrame.origin.y = self.scrollableView.frame.size.height;
    toolBarFrame.size.height = 0.;
    self.toolBarView.frame = toolBarFrame;
}

- (void)setupHeaderView
{
}

- (NSArray<OATableCellData *> *)generateDataForColorsSection
{
    NSMutableArray<OATableCellData *> *colorsCells = [NSMutableArray array];
    [colorsCells addObject:[OATableCellData withKey:@"color_title"
                                           cellType:[OAIconTitleValueCell getCellIdentifier]
                                             values:@{ @"string_value": _selectedColoringType.title }
                                              title:OALocalizedString(@"fav_color")
    ]];

    NSMutableArray<NSDictionary *> *trackColoringTypes = [NSMutableArray array];
    for (OAColoringType *type in _availableColoringTypes)
    {
        [trackColoringTypes addObject:@{
                @"title": type.title,
                @"type": type.name,
                @"available": @([type isAvailableForDrawingTrack:self.doc attributeName:nil])
        }];
    }

    [colorsCells addObject:[OATableCellData withKey:@"color_values"
                                           cellType:[OAFoldersCell getCellIdentifier]
                                             values:@{ @"array_value": trackColoringTypes }
                                              title:OALocalizedString(@"fav_color")
    ]];

    if ([_selectedColoringType isTrackSolid])
        [colorsCells addObject:[OATableCellData withKey:@"color_grid"
                                               cellType:[OAColorsTableViewCell getCellIdentifier]
                                                 values:@{
                                                         @"int_value": @(_selectedColor.colorValue),
                                                         @"array_value": _availableColors
                                                 }
        ]];
    else if ([_selectedColoringType isGradient])
        [colorsCells addObject:[OATableCellData withKey:@"color_elevation_description"
                                               cellType:[OATextLineViewCell getCellIdentifier]
                                                  title:OALocalizedString(@"route_line_color_elevation_description")
        ]];

    if ([_selectedColoringType isGradient])
    {
        NSString *description;
        NSString *extraDescription = @"";
        if ([self isSelectedTypeSpeed])
        {
            description = [OAOsmAndFormatter getFormattedSpeed:0.0];
            extraDescription = [OAOsmAndFormatter getFormattedSpeed:
                    MAX(self.analysis.maxSpeed, [[OAAppSettings sharedManager].applicationMode.get getMaxSpeed])];
        }
        else if ([self isSelectedTypeAltitude])
        {
            description = [OAOsmAndFormatter getFormattedAlt:self.analysis.minElevation];
            extraDescription = [OAOsmAndFormatter getFormattedAlt:
                    MAX(self.analysis.maxElevation, self.analysis.minElevation + 50)];
        }
        else if ([self isSelectedTypeSlope])
        {
            description = OALocalizedString(@"slope_grey_color_descr");
        }

        [colorsCells addObject:[OATableCellData withKey:@"color_elevation_slider"
                                               cellType:[OAImageTextViewCell getCellIdentifier]
                                                 values:@{
                                                         @"extra_desc": extraDescription,
                                                         @"desc_font_size": @([self isSelectedTypeSlope] ? 15 : 17)
                                                 }
                                                   desc:description
                                               leftIcon:
                                                       [self isSelectedTypeSlope] ? @"img_track_gradient_slope" : @"img_track_gradient_speed"
        ]];
    }

    return colorsCells;
}

- (void)generateData
{
    NSMutableArray<OATableSectionData *> *appearanceSections = [NSMutableArray array];

    NSMutableArray<OATableCellData *> *iconsCells = [NSMutableArray array];
    [iconsCells addObject:[OATableCellData withKey:@"direction_arrows"
                                          cellType:[OAIconTextDividerSwitchCell getCellIdentifier]
                                             title:OALocalizedString(@"gpx_dir_arrows")
    ]];

    OATableSectionData *iconsSection = [OATableSectionData withKey:kIconsSection
                                                             cells:iconsCells];
    [appearanceSections addObject:iconsSection];

    OATableSectionData *colorsSection = [OATableSectionData withKey:kColorsSection
                                                              cells:[self generateDataForColorsSection]];
    [appearanceSections addObject:colorsSection];

    NSMutableArray<OATableCellData *> *widthCells = [NSMutableArray array];
    [widthCells addObject:[OATableCellData withKey:@"width_title"
                                          cellType:[OAIconTitleValueCell getCellIdentifier]
                                            values:@{ @"string_value": _selectedWidth.title }
                                             title:OALocalizedString(@"shared_string_width")
    ]];

    [widthCells addObject:[OATableCellData withKey:@"width_value"
                                          cellType:[OASegmentedControlCell getCellIdentifier]
                                            values:@{ @"array_value": [_appearanceCollection getAvailableWidth] }
                                            toggle:YES
    ]];

    [widthCells addObject:[OATableCellData withKey:@"width_empty_space"
                                          cellType:[OADividerCell getCellIdentifier]
                                            values:@{ @"float_value": @14.0 }
    ]];

    if ([_selectedWidth isCustom])
        [widthCells addObject:[OATableCellData withKey:@"width_custom_slider"
                                              cellType:[OASegmentSliderTableViewCell getCellIdentifier]
                                                values:@{
                                                         @"int_value": _selectedWidth.customValue,
                                                         @"array_value": _customWidthValues,
                                                         @"has_top_labels": @NO,
                                                         @"has_bottom_labels": @YES,
                                                 }
        ]];

    OATableSectionData *widthSection = [OATableSectionData withKey:kWidthSection
                                                             cells:widthCells];
    [appearanceSections addObject:widthSection];

    NSMutableArray<OATableCellData *> *actionsCells = [NSMutableArray array];
    [actionsCells addObject:[OATableCellData withKey:@"reset"
                                            cellType:[OAIconTitleValueCell getCellIdentifier]
                                               title:OALocalizedString(@"reset_to_original")
                                           rightIcon:@"ic_custom_reset"
                                              toggle:YES
    ]];
    OATableSectionData *actionsSection = [OATableSectionData withKey:kActionsSection
                                                               cells:actionsCells
                                                              header:OALocalizedString(@"actions")];
    [appearanceSections addObject:actionsSection];

    self.menuTableData = [OATableData withSections:appearanceSections];
}

- (void)updateWidthSlider:(NSIndexPath *)indexPath
{
    [self.menuTableData setCell:[OATableCellData withKey:@"width_custom_slider"
                                                cellType:[OASegmentSliderTableViewCell getCellIdentifier]
                                                  values:@{
                                                          @"int_value": _selectedWidth.customValue,
                                                          @"array_value": _customWidthValues,
                                                          @"has_top_labels": @NO,
                                                          @"has_bottom_labels": @YES,
                                                  }
    ] inSection:kWidthSection];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
}


- (void)updateColorsSection
{
    NSInteger sectionIndex = [self.menuTableData getSectionPosition:kColorsSection];
    BOOL didHasElevationSlider = NO;
    OATableSectionData *section;
    if (sectionIndex != -1)
        section = self.menuTableData.sections[sectionIndex];
    didHasElevationSlider = section && [section containsCell:@"color_elevation_slider"];

    [self.menuTableData setCells:[self generateDataForColorsSection] inSection:kColorsSection];
    sectionIndex = [self.menuTableData getSectionPosition:kColorsSection];
    section = self.menuTableData.sections[sectionIndex];

    [UIView setAnimationsEnabled:NO];
    if (didHasElevationSlider && [section containsCell:@"color_elevation_slider"])
    {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                      withRowAnimation:UITableViewRowAnimationNone];
    }
    else if (!didHasElevationSlider && [section containsCell:@"color_elevation_slider"])
    {
        [self.tableView beginUpdates];
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:section.cells.count
                                                                    inSection:sectionIndex]]
                              withRowAnimation:UITableViewRowAnimationBottom];
        [self.tableView endUpdates];
    }
    else if (didHasElevationSlider && [section containsCell:@"color_elevation_slider"])
    {
        [self.tableView beginUpdates];
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:section.cells.count - 1
                                                                    inSection:sectionIndex]]
                              withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    }
    [UIView setAnimationsEnabled:YES];
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

- (BOOL)isSelectedTypeSlope
{
    return _selectedColoringType == OAColoringType.SLOPE;
}

- (BOOL)isSelectedTypeSpeed
{
    return _selectedColoringType == OAColoringType.SPEED;
}

- (BOOL)isSelectedTypeAltitude
{
    return _selectedColoringType == OAColoringType.ALTITUDE;
}

- (BOOL)isEnabled:(NSString *)key
{
    if ([key isEqualToString:@"direction_arrows"])
        return self.gpx.showArrows;

    return NO;
}

- (IBAction)onBackButtonPressed:(id)sender
{
    [self hide:YES duration:.2 onComplete:^{
        if (self.trackMenuDelegate && [self.trackMenuDelegate respondsToSelector:@selector(backToTrackMenu:)])
        {
            self.gpx.color = _oldColor;
            self.gpx.showArrows = _oldShowArrows;
            self.gpx.width = _oldWidth;
            self.gpx.coloringType = _oldColoringType;
            [self.trackMenuDelegate backToTrackMenu:self.gpx];
        }

        [[self.app updateGpxTracksOnMapObservable] notifyEvent];
    }];
}

- (IBAction)onDoneButtonPressed:(id)sender
{
    [self hide:YES duration:.2 onComplete:^{
        [[OAGPXDatabase sharedDb] save];
        if (self.trackMenuDelegate && [self.trackMenuDelegate respondsToSelector:@selector(backToTrackMenu:)])
            [self.trackMenuDelegate backToTrackMenu:self.gpx];
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.menuTableData.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.menuTableData.sections[section].cells.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return self.menuTableData.sections[section].header;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATableCellData *cellData = [self getCellData:indexPath];
    NSDictionary *values = cellData.values;
    BOOL isOn = [self isEnabled:cellData.key];

    UITableViewCell *outCell = nil;
    if ([cellData.cellType isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAIconTitleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTitleValueCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier]
                                                         owner:self options:nil];
            cell = (OAIconTitleValueCell *) nib[0];
            [cell showLeftIcon:NO];
            cell.separatorInset = UIEdgeInsetsMake(0., self.tableView.frame.size.width, 0., 0.);
        }
        if (cell)
        {
            cell.selectionStyle = cellData.toggle ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
            cell.textView.text = cellData.title;
            cell.descriptionView.text = values[@"string_value"];
            cell.textView.textColor = cellData.toggle ? UIColorFromRGB(color_primary_purple) : UIColor.blackColor;
            if (cellData.toggle)
            {
                cell.rightIconView.image = [UIImage templateImageNamed:cellData.rightIcon];
                cell.rightIconView.tintColor = UIColorFromRGB(color_primary_purple);
            }
            [cell showRightIcon:cellData.toggle];
        }
        outCell = cell;
    }
    else if ([cellData.cellType isEqualToString:[OAIconTextDividerSwitchCell getCellIdentifier]])
    {
        OAIconTextDividerSwitchCell *cell =
                [tableView dequeueReusableCellWithIdentifier:[OAIconTextDividerSwitchCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextDividerSwitchCell getCellIdentifier]
                                                         owner:self options:nil];
            cell = (OAIconTextDividerSwitchCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsMake(0., 20., 0., 0.);
            cell.dividerView.hidden = YES;
            cell.iconView.image = nil;
        }
        if (cell)
        {
            cell.switchView.on = isOn;
            cell.textView.text = cellData.title;

            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(onSwitchPressed:) forControlEvents:UIControlEventValueChanged];
        }
        outCell = cell;
    }
    else if ([cellData.cellType isEqualToString:[OAImageTextViewCell getCellIdentifier]])
    {
        OAImageTextViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAImageTextViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAImageTextViewCell getCellIdentifier]
                                                         owner:self options:nil];
            cell = (OAImageTextViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            NSString *extraDesc = values[@"extra_desc"];
            [cell showExtraDesc:extraDesc && extraDesc.length > 0];

            cell.iconView.image = [UIImage imageNamed:cellData.leftIcon];

            cell.descView.text = cellData.desc;
            cell.descView.font = [UIFont systemFontOfSize:[values[@"desc_font_size"] intValue]];
            cell.descView.textColor = UIColorFromRGB(color_text_footer);

            cell.extraDescView.text = extraDesc;
            cell.extraDescView.font = [UIFont systemFontOfSize:[values[@"desc_font_size"] intValue]];
            cell.extraDescView.textColor = UIColorFromRGB(color_text_footer);
        }

        if ([cell needsUpdateConstraints])
            [cell setNeedsUpdateConstraints];

        return cell;
    }
    else if ([cellData.cellType isEqualToString:[OAFoldersCell getCellIdentifier]])
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
            [cell setValues:values[@"array_value"] withSelectedIndex:[_availableColoringTypes indexOfObject:_selectedColoringType]];
        }
        outCell = _colorValuesCell = cell;
    }
    else if ([cellData.cellType isEqualToString:[OAColorsTableViewCell getCellIdentifier]])
    {
        NSArray *arrayValue = values[@"array_value"];
        OAColorsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAColorsTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAColorsTableViewCell getCellIdentifier]
                                                         owner:self options:nil];
            cell = (OAColorsTableViewCell *) nib[0];
            cell.dataArray = arrayValue;
            cell.delegate = self;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell showLabels:NO];
        }
        if (cell)
        {
            cell.valueLabel.tintColor = UIColorFromRGB(color_text_footer);
            cell.currentColor = [arrayValue indexOfObject:values[@"int_value"]];

            [cell.collectionView reloadData];
            [cell layoutIfNeeded];
        }
        outCell = cell;
    }
    else if ([cellData.cellType isEqualToString:[OATextLineViewCell getCellIdentifier]])
    {
        OATextLineViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OATextLineViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextLineViewCell getCellIdentifier]
                                                         owner:self options:nil];
            cell = (OATextLineViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsMake(0., self.tableView.frame.size.width, 0., 0.);
        }
        if (cell)
        {
            cell.textView.text = cellData.title;
            cell.textView.font = [UIFont systemFontOfSize:15];
            cell.textView.textColor = UIColorFromRGB(color_text_footer);
        }
        outCell = cell;
    }
    else if ([cellData.cellType isEqualToString:[OASegmentedControlCell getCellIdentifier]])
    {
        NSArray *arrayValue = values[@"array_value"];
        OASegmentedControlCell *cell = _widthValuesCell;
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASegmentedControlCell getCellIdentifier]
                                                         owner:self options:nil];
            cell = (OASegmentedControlCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsMake(0., self.tableView.frame.size.width, 0., 0.);
            cell.backgroundColor = UIColor.whiteColor;
            cell.segmentedControl.backgroundColor = [UIColorFromRGB(color_primary_purple) colorWithAlphaComponent:.1];
            [cell changeHeight:YES];

            [cell.segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName : UIColor.whiteColor}
                                                 forState:UIControlStateSelected];
            [cell.segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName : UIColorFromRGB(color_primary_purple)}
                                                 forState:UIControlStateNormal];

            if (@available(iOS 13.0, *))
                cell.segmentedControl.selectedSegmentTintColor = UIColorFromRGB(color_primary_purple);
            else
                cell.segmentedControl.tintColor = UIColorFromRGB(color_primary_purple);
        }
        if (cell)
        {
            int i = 0;
            for (OAGPXTrackAppearance *value in arrayValue)
            {
                if (cellData.toggle && [value isKindOfClass:OAGPXTrackWidth.class])
                {
                    UIImage *icon = [UIImage templateImageNamed:((OAGPXTrackWidth *) value).icon];
                    if (i == cell.segmentedControl.numberOfSegments)
                        [cell.segmentedControl insertSegmentWithImage:icon atIndex:i++ animated:NO];
                    else
                        [cell.segmentedControl setImage:icon forSegmentAtIndex:i++];
                }
            }

            [cell.segmentedControl setSelectedSegmentIndex:[arrayValue indexOfObject:_selectedWidth]];

            cell.segmentedControl.tag = indexPath.section << 10 | indexPath.row;
            [cell.segmentedControl removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.segmentedControl addTarget:self
                                      action:@selector(segmentChanged:)
                            forControlEvents:UIControlEventValueChanged];
        }

        outCell = _widthValuesCell = cell;
    }
    else if ([cellData.cellType isEqualToString:[OADividerCell getCellIdentifier]])
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
    else if ([cellData.cellType isEqualToString:[OASegmentSliderTableViewCell getCellIdentifier]])
    {
        OASegmentSliderTableViewCell *cell =
                [tableView dequeueReusableCellWithIdentifier:[OASegmentSliderTableViewCell getCellIdentifier]];
        BOOL hasTopLabels = [values[@"has_top_labels"] boolValue];
        BOOL hasBottomLabels = [values[@"has_bottom_labels"] boolValue];
        NSArray *arrayValue = values[@"array_value"];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASegmentSliderTableViewCell getCellIdentifier]
                                                         owner:self options:nil];
            cell = (OASegmentSliderTableViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            [cell showLabels:hasTopLabels topRight:hasTopLabels bottomLeft:hasBottomLabels bottomRight:hasBottomLabels];
            [cell.sliderView removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
            cell.topLeftLabel.text = cellData.title;
            cell.topRightLabel.text = [NSString stringWithFormat:@"%li", (long) [values[@"int_value"] intValue]];
            cell.bottomLeftLabel.text = [NSString stringWithFormat:@"%li", (long) [arrayValue.firstObject intValue]];
            cell.bottomRightLabel.text = [NSString stringWithFormat:@"%li", (long) [arrayValue.lastObject intValue]];
            cell.numberOfMarks = arrayValue.count;
            cell.selectedMark = [values[@"int_value"] intValue];

            cell.sliderView.tag = indexPath.section << 10 | indexPath.row;
            [cell.sliderView removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside];
            [cell.sliderView addTarget:self
                                action:@selector(sliderChanged:)
                      forControlEvents:UIControlEventTouchUpInside];
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
    OATableCellData *cellData = [self getCellData:indexPath];
    if ([cellData.cellType isEqualToString:[OADividerCell getCellIdentifier]])
        return [cellData.values[@"float_value"] floatValue];

    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return 0.001;

    return 36.;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATableCellData *cellData = [self getCellData:indexPath];

    if ([cellData.key isEqualToString:@"reset"])
    {
        [[OAGPXDatabase sharedDb] reloadGPXFile:[self.app.gpxPath stringByAppendingPathComponent:self.gpx.gpxFilePath] onComplete:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                self.gpx = [[OAGPXDatabase sharedDb] getGPXItem:self.gpx.gpxFilePath];
                [self updateGpxData];
                [self commonInit];
                [self.settings showGpx:@[self.gpx.gpxFilePath] update:YES];
                [[self.app updateGpxTracksOnMapObservable] notifyEvent];
                [self generateData];
                [self setupHeaderView];
                [UIView transitionWithView:self.tableView
                                  duration:0.35f
                                   options:UIViewAnimationOptionTransitionCrossDissolve
                                animations:^(void)
                                {
                                    [self.tableView reloadData];
                                }
                                completion:nil];
            });
        }];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UISwitch pressed

- (void)onSwitchPressed:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:switchView.tag & 0x3FF inSection:switchView.tag >> 10];
    OATableCellData *cellData = [self getCellData:indexPath];

    if ([cellData.key isEqualToString:@"direction_arrows"])
        self.gpx.showArrows = switchView.isOn;

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
        OATableCellData *cellData = [self getCellData:indexPath];

        if ([cellData.key isEqualToString:@"width_value"])
        {
            _selectedWidth = [_appearanceCollection getAvailableWidth][segment.selectedSegmentIndex];
            self.gpx.width = [_selectedWidth isCustom] ? _selectedWidth.customValue : _selectedWidth.key;

            [[self.app updateGpxTracksOnMapObservable] notifyEvent];
        }

        [self generateData/*:indexPath.section*/];
        [self.tableView reloadData];
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
        OATableCellData *cellData = [self getCellData:indexPath];

        if ([cellData.key isEqualToString:@"width_custom_slider"])
        {
            NSInteger index = cell.selectedMark;
            NSInteger selectedValue = _customWidthValues[index].intValue;
            if (_selectedWidth.customValue.intValue != selectedValue)
            {
                _selectedWidth.customValue = [NSString stringWithFormat:@"%li", selectedValue];
                self.gpx.width = _selectedWidth.customValue;

                [[self.app updateGpxTracksOnMapObservable] notifyEvent];
            }
        }

        [self updateWidthSlider:indexPath];
    }
}

#pragma mark - OAFoldersCellDelegate

- (void)onItemSelected:(NSInteger)index type:(NSString *)type
{
    _selectedColoringType = _availableColoringTypes[index];
    self.gpx.coloringType = _selectedColoringType.name;

    [[self.app updateGpxTracksOnMapObservable] notifyEvent];
    [self updateColorsSection];
}

#pragma mark - OAColorsTableViewCellDelegate

- (void)colorChanged:(NSInteger)tag
{
    _selectedColor = [_appearanceCollection getColorForValue:_availableColors[tag].intValue];
    self.gpx.color = _selectedColor.colorValue;

    [[self.app updateGpxTracksOnMapObservable] notifyEvent];
    [self updateColorsSection];
}

@end
