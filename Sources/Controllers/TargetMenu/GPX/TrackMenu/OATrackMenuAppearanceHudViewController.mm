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

#define kColorsSection 1
#define kWidthSection 2

#define kColorGridOrDescriptionCell 2

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

@property (nonatomic) OAGPX *gpx;
@property (nonatomic) BOOL isShown;
@property (nonatomic) NSArray<OAGPXTableSectionData *> *tableData;

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

    OATrackMenuViewControllerState *_reopeningTrackMenuState;
}

@dynamic gpx, isShown, tableData;

- (instancetype)initWithGpx:(OAGPX *)gpx state:(OATargetMenuViewControllerState *)state
{
    self = [super initWithGpx:gpx];
    if (self)
    {
        _reopeningTrackMenuState = state;
    }
    return self;
}

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

- (void)generateData
{
    NSMutableArray<OAGPXTableSectionData *> *appearanceSections = [NSMutableArray array];

    [appearanceSections addObject:[OAGPXTableSectionData withData:@{
            kSectionCells: @[[OAGPXTableCellData withData:@{
                    kCellKey:@"direction_arrows",
                    kCellType:[OAIconTextDividerSwitchCell getCellIdentifier],
                    kCellTitle:OALocalizedString(@"gpx_dir_arrows"),
                    kCellOnSwitch: ^(BOOL toggle) { self.gpx.showArrows = toggle; },
                    kCellIsOn: ^() { return self.gpx.showArrows; }
            }]]
    }]];

    NSMutableArray<OAGPXTableCellData *> *colorsCells = [NSMutableArray array];

    OAGPXTableCellData *colorTitle = [OAGPXTableCellData withData:@{
            kCellKey: @"color_title",
            kCellType: [OAIconTitleValueCell getCellIdentifier],
            kCellValues: @{ @"string_value": _selectedColoringType.title },
            kCellTitle: OALocalizedString(@"fav_color")
    }];

    [colorTitle setData:@{
            kTableUpdateData: ^() {
                [colorTitle setData:@{ kCellValues: @{ @"string_value": _selectedColoringType.title } }];
            }
    }];
    [colorsCells addObject:colorTitle];

    NSMutableArray<NSDictionary *> *trackColoringTypes = [NSMutableArray array];
    for (OAColoringType *type in _availableColoringTypes)
    {
        [trackColoringTypes addObject:@{
                @"title": type.title,
                @"type": type.name,
                @"available": @([type isAvailableForDrawingTrack:self.doc attributeName:nil])
        }];
    }

    OAGPXTableCellData *colorValues = [OAGPXTableCellData withData:@{
            kCellKey: @"color_values",
            kCellType: [OAFoldersCell getCellIdentifier],
            kCellValues: @{ @"array_value": trackColoringTypes },
            kCellTitle: OALocalizedString(@"fav_color")
    }];

    [colorValues setData:@{
            kTableUpdateData: ^() {
                NSMutableArray<NSDictionary *> *newTrackColoringTypes = [NSMutableArray array];
                for (OAColoringType *type in _availableColoringTypes)
                {
                    [newTrackColoringTypes addObject:@{
                            @"title": type.title,
                            @"type": type.name,
                            @"available": @([type isAvailableForDrawingTrack:self.doc attributeName:nil])
                    }];
                }
                [colorValues setData:@{ kCellValues: @{ @"array_value": newTrackColoringTypes } }];
            }
    }];
    [colorsCells addObject:colorValues];

    OAGPXTableCellData * (^generateGridOrDescriptionCell) (void) = ^{
        OAGPXTableCellData *gridOrDescriptionCell;
        if ([_selectedColoringType isTrackSolid])
        {
            gridOrDescriptionCell = [OAGPXTableCellData withData:@{
                    kCellKey: @"color_grid",
                    kCellType: [OAColorsTableViewCell getCellIdentifier],
                    kCellValues: @{
                            @"int_value": @(_selectedColor.colorValue),
                            @"array_value": _availableColors
                    }
            }];

            [gridOrDescriptionCell setData:@{
                    kTableUpdateData: ^() {
                        [gridOrDescriptionCell setData:@{
                                kCellValues: @{
                                        @"int_value": @(_selectedColor.colorValue),
                                        @"array_value": _availableColors
                                }
                        }];
                    }
            }];
        }
        else if ([_selectedColoringType isGradient])
        {
            gridOrDescriptionCell = [OAGPXTableCellData withData:@{
                    kCellKey: @"color_elevation_description",
                    kCellType: [OATextLineViewCell getCellIdentifier],
                    kCellTitle: OALocalizedString(@"route_line_color_elevation_description")
            }];
        }
        return gridOrDescriptionCell;
    };
    [colorsCells addObject:generateGridOrDescriptionCell()];

    if ([_selectedColoringType isGradient])
        [colorsCells addObject:[self generateDataForColorElevationGradientCell]];

    OAGPXTableSectionData *colorsSection = [OAGPXTableSectionData withData:@{ kSectionCells: colorsCells }];
    [colorsSection setData:@{
            kTableUpdateData: ^() {
                colorsSection.cells[kColorGridOrDescriptionCell] = generateGridOrDescriptionCell();

                BOOL hasElevationGradient = [colorsSection.cells.lastObject.key isEqualToString:@"color_elevation_gradient"];
                if ([_selectedColoringType isGradient] && !hasElevationGradient)
                    [colorsSection.cells addObject:[self generateDataForColorElevationGradientCell]];
                else if (![_selectedColoringType isGradient] && hasElevationGradient)
                    [colorsSection.cells removeObject:colorsSection.cells.lastObject];

                for (OAGPXTableCellData *cell in colorsSection.cells)
                {
                    if (cell.updateData)
                        cell.updateData();
                }
            }
    }];

    [appearanceSections addObject:colorsSection];

    NSMutableArray<OAGPXTableCellData *> *widthCells = [NSMutableArray array];
    OAGPXTableCellData *widthTitle = [OAGPXTableCellData withData:@{
            kCellKey: @"width_title",
            kCellType: [OAIconTitleValueCell getCellIdentifier],
            kCellValues: @{ @"string_value": _selectedWidth.title },
            kCellTitle: OALocalizedString(@"shared_string_width")
    }];
    [widthTitle setData:@{
            kTableUpdateData: ^() {
                [widthTitle setData:@{ kCellValues: @{ @"string_value": _selectedWidth.title } }];
            }
    }];
    [widthCells addObject:widthTitle];

    OAGPXTableCellData *widthValue = [OAGPXTableCellData withData:@{
            kCellKey: @"width_value",
            kCellType: [OASegmentedControlCell getCellIdentifier],
            kCellValues: @{ @"array_value": [_appearanceCollection getAvailableWidth] },
            kCellToggle: @YES
    }];
    [widthValue setData:@{
            kTableUpdateData: ^() {
                [widthValue setData:@{ kCellValues: @{ @"array_value": [_appearanceCollection getAvailableWidth] } }];
            }
    }];
    [widthCells addObject:widthValue];

    [widthCells addObject:[OAGPXTableCellData withData:@{
            kCellKey: @"width_empty_space",
            kCellType: [OADividerCell getCellIdentifier],
            kCellValues: @{ @"float_value": @14.0 }
    }]];

    if ([_selectedWidth isCustom])
        [widthCells addObject:[self generateDataForWidthCustomSliderCell]];

    OAGPXTableSectionData *widthSection = [OAGPXTableSectionData withData:@{ kSectionCells: widthCells }];
    [widthSection setData:@{
            kTableUpdateData: ^() {
                BOOL hasCustomSlider = [widthSection.cells.lastObject.key isEqualToString:@"width_custom_slider"];
                if ([_selectedWidth isCustom] && !hasCustomSlider)
                    [widthSection.cells addObject:[self generateDataForWidthCustomSliderCell]];
                else if (![_selectedWidth isCustom] && hasCustomSlider)
                    [widthSection.cells removeObject:widthSection.cells.lastObject];
        
                for (OAGPXTableCellData *cell in widthSection.cells)
                {
                    if (cell.updateData)
                        cell.updateData();
                }
        }
    }];

    [appearanceSections addObject:widthSection];

    [appearanceSections addObject:[OAGPXTableSectionData withData:@{
            kSectionCells: @[[OAGPXTableCellData withData:@{
                    kCellKey: @"reset",
                    kCellType: [OAIconTitleValueCell getCellIdentifier],
                    kCellTitle: OALocalizedString(@"reset_to_original"),
                    kCellRightIcon:@"ic_custom_reset",
                    kCellToggle: @YES
            }]],
            kSectionHeader:OALocalizedString(@"actions")
    }]];

    self.tableData = appearanceSections;
}

- (OAGPXTableCellData *)generateDataForColorElevationGradientCell
{
    NSString * (^generateDescription) (void) = ^{
        if ([self isSelectedTypeSpeed])
            return [OAOsmAndFormatter getFormattedSpeed:0.0];
        else if ([self isSelectedTypeAltitude])
            return [OAOsmAndFormatter getFormattedAlt:self.analysis.minElevation];
        else if ([self isSelectedTypeSlope])
            return OALocalizedString(@"slope_grey_color_descr");
        return @"";
    };

    NSString * (^generateExtraDescription) (void) = ^{
        if ([self isSelectedTypeSpeed])
            return [OAOsmAndFormatter getFormattedSpeed:
                    MAX(self.analysis.maxSpeed, [[OAAppSettings sharedManager].applicationMode.get getMaxSpeed])];
        else if ([self isSelectedTypeAltitude])
            return [OAOsmAndFormatter getFormattedAlt:
                    MAX(self.analysis.maxElevation, self.analysis.minElevation + 50)];
        return @"";
    };

    OAGPXTableCellData *colorGradient = [OAGPXTableCellData withData:@{
            kCellKey: @"color_elevation_gradient",
            kCellType: [OAImageTextViewCell getCellIdentifier],
            kCellValues: @{
                    @"extra_desc": generateExtraDescription(),
                    @"desc_font_size": @([self isSelectedTypeSlope] ? 15 : 17)
            },
            kCellDesc: generateDescription(),
            kCellLeftIcon: [self isSelectedTypeSlope] ? @"img_track_gradient_slope" : @"img_track_gradient_speed"
    }];
    [colorGradient setData:@{
            kTableUpdateData: ^() {
                [colorGradient setData:@{
                        kCellValues: @{
                                @"extra_desc": generateExtraDescription(),
                                @"desc_font_size": @([self isSelectedTypeSlope] ? 15 : 17)
                        },
                        kCellDesc: generateDescription(),
                        kCellLeftIcon: [self isSelectedTypeSlope] ? @"img_track_gradient_slope" : @"img_track_gradient_speed"
                }];
            }
    }];

    return colorGradient;
}

- (OAGPXTableCellData *)generateDataForWidthCustomSliderCell
{
    OAGPXTableCellData *customSliderCell = [OAGPXTableCellData withData:@{
            kCellKey: @"width_custom_slider",
            kCellType: [OASegmentSliderTableViewCell getCellIdentifier],
            kCellValues: @{
                    @"int_value": _selectedWidth.customValue,
                    @"array_value": _customWidthValues,
                    @"has_top_labels": @NO,
                    @"has_bottom_labels": @YES,
            }
    }];
    [customSliderCell setData:@{
            kTableUpdateData: ^() {
                [customSliderCell setData:@{
                        kCellValues: @{
                                @"int_value": _selectedWidth.customValue,
                                @"array_value": _customWidthValues,
                                @"has_top_labels": @NO,
                                @"has_bottom_labels": @YES,
                        }
                }];
            }
    }];

    return customSliderCell;
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

- (IBAction)onBackButtonPressed:(id)sender
{
    [self hide:YES duration:.2 onComplete:^{
        if (_reopeningTrackMenuState)
        {
            self.gpx.color = _oldColor;
            self.gpx.showArrows = _oldShowArrows;
            self.gpx.width = _oldWidth;
            self.gpx.coloringType = _oldColoringType;
            [self.mapPanelViewController openTargetViewWithGPX:self.gpx
                                                  trackHudMode:EOATrackMenuHudMode
                                                         state:_reopeningTrackMenuState];
        }

        [[self.app updateGpxTracksOnMapObservable] notifyEvent];
    }];
}

- (IBAction)onDoneButtonPressed:(id)sender
{
    [self hide:YES duration:.2 onComplete:^{
        [[OAGPXDatabase sharedDb] save];
        if (_reopeningTrackMenuState)
            [self.mapPanelViewController openTargetViewWithGPX:self.gpx
                                                  trackHudMode:EOATrackMenuHudMode
                                                         state:_reopeningTrackMenuState];
    }];
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
    UITableViewCell *outCell = nil;
    if ([cellData.type isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
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
            cell.descriptionView.text = cellData.values[@"string_value"];
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
    else if ([cellData.type isEqualToString:[OAIconTextDividerSwitchCell getCellIdentifier]])
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
            cell.switchView.on = cellData.isOn ? cellData.isOn() : NO;
            cell.textView.text = cellData.title;

            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(onSwitchPressed:) forControlEvents:UIControlEventValueChanged];
        }
        outCell = cell;
    }
    else if ([cellData.type isEqualToString:[OAImageTextViewCell getCellIdentifier]])
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
            NSString *extraDesc = cellData.values[@"extra_desc"];
            [cell showExtraDesc:extraDesc && extraDesc.length > 0];

            cell.iconView.image = [UIImage imageNamed:cellData.leftIcon];

            cell.descView.text = cellData.desc;
            cell.descView.font = [UIFont systemFontOfSize:[cellData.values[@"desc_font_size"] intValue]];
            cell.descView.textColor = UIColorFromRGB(color_text_footer);

            cell.extraDescView.text = extraDesc;
            cell.extraDescView.font = [UIFont systemFontOfSize:[cellData.values[@"desc_font_size"] intValue]];
            cell.extraDescView.textColor = UIColorFromRGB(color_text_footer);
        }

        if ([cell needsUpdateConstraints])
            [cell setNeedsUpdateConstraints];

        return cell;
    }
    else if ([cellData.type isEqualToString:[OAFoldersCell getCellIdentifier]])
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
            [cell setValues:cellData.values[@"array_value"] withSelectedIndex:[_availableColoringTypes indexOfObject:_selectedColoringType]];
        }
        outCell = _colorValuesCell = cell;
    }
    else if ([cellData.type isEqualToString:[OAColorsTableViewCell getCellIdentifier]])
    {
        NSArray *arrayValue = cellData.values[@"array_value"];
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
            cell.currentColor = [arrayValue indexOfObject:cellData.values[@"int_value"]];

            [cell.collectionView reloadData];
            [cell layoutIfNeeded];
        }
        outCell = cell;
    }
    else if ([cellData.type isEqualToString:[OATextLineViewCell getCellIdentifier]])
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
    else if ([cellData.type isEqualToString:[OASegmentedControlCell getCellIdentifier]])
    {
        NSArray *arrayValue = cellData.values[@"array_value"];
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
    else if ([cellData.type isEqualToString:[OADividerCell getCellIdentifier]])
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
    else if ([cellData.type isEqualToString:[OASegmentSliderTableViewCell getCellIdentifier]])
    {
        OASegmentSliderTableViewCell *cell =
                [tableView dequeueReusableCellWithIdentifier:[OASegmentSliderTableViewCell getCellIdentifier]];
        BOOL hasTopLabels = [cellData.values[@"has_top_labels"] boolValue];
        BOOL hasBottomLabels = [cellData.values[@"has_bottom_labels"] boolValue];
        NSArray *arrayValue = cellData.values[@"array_value"];
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
            cell.topRightLabel.text = [NSString stringWithFormat:@"%li", (long) [cellData.values[@"int_value"] intValue]];
            cell.bottomLeftLabel.text = [NSString stringWithFormat:@"%li", (long) [arrayValue.firstObject intValue]];
            cell.bottomRightLabel.text = [NSString stringWithFormat:@"%li", (long) [arrayValue.lastObject intValue]];
            cell.numberOfMarks = arrayValue.count;
            cell.selectedMark = [cellData.values[@"int_value"] intValue];

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
    OAGPXTableCellData *cellData = [self getCellData:indexPath];
    if ([cellData.type isEqualToString:[OADividerCell getCellIdentifier]])
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
    OAGPXTableCellData *cellData = [self getCellData:indexPath];

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
    OAGPXTableCellData *cellData = [self getCellData:indexPath];

    if (cellData.onSwitch)
        cellData.onSwitch(switchView.isOn);

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
        OAGPXTableCellData *cellData = [self getCellData:indexPath];

        if ([cellData.key isEqualToString:@"width_value"])
        {
            _selectedWidth = [_appearanceCollection getAvailableWidth][segment.selectedSegmentIndex];
            self.gpx.width = [_selectedWidth isCustom] ? _selectedWidth.customValue : _selectedWidth.key;

            [[self.app updateGpxTracksOnMapObservable] notifyEvent];

            self.tableData[indexPath.section].updateData();
            [UIView setAnimationsEnabled:NO];
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kWidthSection]
                          withRowAnimation:UITableViewRowAnimationNone];
            [UIView setAnimationsEnabled:YES];
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
        OAGPXTableCellData *cellData = [self getCellData:indexPath];

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
    }
}

#pragma mark - OAFoldersCellDelegate

- (void)onItemSelected:(NSInteger)index type:(NSString *)type
{
    _selectedColoringType = _availableColoringTypes[index];
    self.gpx.coloringType = _selectedColoringType.name;

    [[self.app updateGpxTracksOnMapObservable] notifyEvent];

    self.tableData[kColorsSection].updateData();
    [UIView transitionWithView:self.tableView
                      duration:0.35f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^(void)
                    {
                        [self.tableView reloadData];
                    }
                    completion:nil];
}

#pragma mark - OAColorsTableViewCellDelegate

- (void)colorChanged:(NSInteger)tag
{
    _selectedColor = [_appearanceCollection getColorForValue:_availableColors[tag].intValue];
    self.gpx.color = _selectedColor.colorValue;

    [[self.app updateGpxTracksOnMapObservable] notifyEvent];

    self.tableData[kColorsSection].cells[kColorGridOrDescriptionCell].updateData();
    [UIView setAnimationsEnabled:NO];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kColorGridOrDescriptionCell inSection:kColorsSection]]
                          withRowAnimation:UITableViewRowAnimationNone];
    [UIView setAnimationsEnabled:YES];
}

@end
