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
#import "OAImageTextViewCell.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAOsmAndFormatter.h"
#import "OAGPXDatabase.h"
#import "OAGPXTrackAnalysis.h"
#import "OAGPXAppearanceCollection.h"
#import "OAColoringType.h"

typedef NS_ENUM(NSUInteger, EOATrackAppearanceHudSection)
{
    EOATrackAppearanceHudIconsSection = 0,
    EOATrackAppearanceHudColorsSection,
    EOATrackAppearanceHudWidthSection,
    EOATrackAppearanceHudActionsSection
};

typedef NS_ENUM(NSUInteger, EOATrackAppearanceHudIconsRow)
{
    EOATrackAppearanceHudIconsArrowsRow = 0
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

@property (nonatomic) OAMapPanelViewController *mapPanelViewController;
@property (nonatomic) OAMapViewController *mapViewController;

@property (nonatomic) OsmAndAppInstance app;
@property (nonatomic) OAAppSettings *settings;

@property (nonatomic) OAGPX *gpx;
@property (nonatomic) OAGPXDocument *doc;
@property (nonatomic) OAGPXTrackAnalysis *analysis;
@property (nonatomic) BOOL isShown;

@property (nonatomic) NSArray<NSDictionary *> *data;

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
        [trackColors addObject:@((int) trackColor.colorValue)];
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
    [self.tableView registerClass:OATableViewCustomFooterView.class
        forHeaderFooterViewReuseIdentifier:[OATableViewCustomFooterView getCellIdentifier]];

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

    self.data = @[
            @{ @"cells": [self getCellsDataForSection:EOATrackAppearanceHudIconsSection] },
            @{ @"cells": [self getCellsDataForSection:EOATrackAppearanceHudColorsSection] },
            @{ @"cells": [self getCellsDataForSection:EOATrackAppearanceHudWidthSection] },
            @{
                    @"header": OALocalizedString(@"actions"),
                    @"cells": [self getCellsDataForSection:EOATrackAppearanceHudActionsSection]
            }];
}

- (NSArray<NSDictionary *> *)getCellsDataForSection:(NSInteger)section
{
    switch (section)
    {
        case EOATrackAppearanceHudIconsSection:
            return @[
                    [self getCellDataForRow:EOATrackAppearanceHudIconsArrowsRow section:section]
            ];

        case EOATrackAppearanceHudColorsSection:
        {
            NSMutableArray *sectionData = [NSMutableArray array];

            [sectionData addObject:[self getCellDataForRow:EOATrackAppearanceHudColorTitleRow section:section]];
            [sectionData addObject:[self getCellDataForRow:EOATrackAppearanceHudColorValuesRow section:section]];
            [sectionData addObject:[self getCellDataForRow:EOATrackAppearanceHudColorGridOrElevationDescRow section:section]];

            if ([_selectedColoringType isGradient])
                [sectionData addObject:[self getCellDataForRow:EOATrackAppearanceHudColorGradientAndDescRow section:section]];

            return sectionData;
        }

        case EOATrackAppearanceHudWidthSection:
        {
            NSMutableArray *sectionData = [NSMutableArray array];

            [sectionData addObject:[self getCellDataForRow:EOATrackAppearanceHudWidthTitleRow section:section]];
            [sectionData addObject:[self getCellDataForRow:EOATrackAppearanceHudWidthValuesRow section:section]];
            [sectionData addObject:[self getCellDataForRow:EOATrackAppearanceHudWidthEmptySpaceRow section:section]];

            if ([_selectedWidth isCustom])
                [sectionData addObject:[self getCellDataForRow:EOATrackAppearanceHudWidthCustomSliderRow section:section]];

            return sectionData;
        }

        case EOATrackAppearanceHudActionsSection:
            return @[[self getCellDataForRow:0 section:section] ];

        default:
            return nil;
    }
}

- (NSDictionary *)getCellDataForRow:(NSInteger)row section:(NSInteger)section
{
    switch (section)
    {
        case EOATrackAppearanceHudIconsSection:
        {
            switch (row)
            {
                case EOATrackAppearanceHudIconsArrowsRow:
                    return @{
                            @"title": OALocalizedString(@"gpx_dir_arrows"),
                            @"value": @NO,
                            @"type": [OAIconTextDividerSwitchCell getCellIdentifier],
                            @"key": @"direction_arrows"
                    };

                default:
                    return nil;
            }
        }

        case EOATrackAppearanceHudColorsSection:
        {
            switch (row)
            {
                case EOATrackAppearanceHudColorTitleRow:
                    return @{
                            @"title": OALocalizedString(@"fav_color"),
                            @"value": _selectedColoringType.title,
                            @"type": [OAIconTitleValueCell getCellIdentifier],
                            @"key": @"color_title"
                    };

                case EOATrackAppearanceHudColorValuesRow:
                {
                    NSMutableArray<NSDictionary *> *trackColoringTypes = [NSMutableArray array];
                    for (OAColoringType *type in _availableColoringTypes)
                    {
                        [trackColoringTypes addObject:@{
                                @"title": type.title,
                                @"type": type.name,
                                @"available": @([type isAvailableForDrawingTrack:self.doc attributeName:nil])
                        }];
                    }
                    return @{
                            @"values": trackColoringTypes,
                            @"type": [OAFoldersCell getCellIdentifier],
                            @"key": @"color_values"
                    };
                }

                case EOATrackAppearanceHudColorGridOrElevationDescRow:
                {
                    if ([_selectedColoringType isTrackSolid])
                        return @{
                                @"value": @(_selectedColor.colorValue),
                                @"type": [OAColorsTableViewCell getCellIdentifier],
                                @"values": _availableColors,
                                @"key": @"color_grid"
                        };
                    else if ([_selectedColoringType isGradient])
                        return @{
                                @"title": OALocalizedString(@"route_line_color_elevation_description"),
                                @"type": [OATextLineViewCell getCellIdentifier],
                                @"key": @"color_elevation_description"
                        };
                }

                case EOATrackAppearanceHudColorGradientAndDescRow:
                {
                    NSString *description;
                    NSString *extraDescription = @"";
                    if ([_selectedColoringType isSpeed])
                    {
                        description = [OAOsmAndFormatter getFormattedSpeed:0.0];
                        extraDescription = [OAOsmAndFormatter getFormattedSpeed:
                                MAX(self.analysis.maxSpeed, [[OAAppSettings sharedManager].applicationMode.get getMaxSpeed])];
                    }
                    else if ([_selectedColoringType isAltitude])
                    {
                        description = [OAOsmAndFormatter getFormattedAlt:self.analysis.minElevation];
                        extraDescription = [OAOsmAndFormatter getFormattedAlt:
                                MAX(self.analysis.maxElevation, self.analysis.minElevation + 50)];
                    }
                    else if ([_selectedColoringType isSlope])
                    {
                        description = OALocalizedString(@"slope_grey_color_descr");
                    }
                    else
                    {
                        return nil;
                    }

                    return @{
                            @"icon": [_selectedColoringType isSlope] ? @"img_track_gradient_slope" : @"img_track_gradient_speed",
                            @"desc": description,
                            @"extra_desc": extraDescription,
                            @"desc_font_size": @([_selectedColoringType isSlope] ? 15 : 17),
                            @"type": [OAImageTextViewCell getCellIdentifier],
                            @"key": @"color_elevation_slider"
                    };
                }

                default:
                    return nil;
            }
        }

        case EOATrackAppearanceHudWidthSection:
        {
            switch (row)
            {
                case EOATrackAppearanceHudWidthTitleRow:
                    return @{
                            @"title": OALocalizedString(@"shared_string_width"),
                            @"value": _selectedWidth.title,
                            @"type": [OAIconTitleValueCell getCellIdentifier],
                            @"key": @"width_title"
                    };

                case EOATrackAppearanceHudWidthValuesRow:
                    return @{
                            @"values": [_appearanceCollection getAvailableWidth],
                            @"with_images": @YES,
                            @"type": [OASegmentedControlCell getCellIdentifier],
                            @"key": @"width_value"
                    };

                case EOATrackAppearanceHudWidthEmptySpaceRow:
                    return @{
                            @"value": @14,
                            @"type": [OADividerCell getCellIdentifier],
                            @"key": @"width_empty_space"
                    };

                case EOATrackAppearanceHudWidthCustomSliderRow:
                {
                    if ([_selectedWidth isCustom])
                        return @{
                                @"selected_value": _selectedWidth.customValue,
                                @"values": _customWidthValues,
                                @"has_top_labels": @NO,
                                @"has_bottom_labels": @YES,
                                @"type": [OASegmentSliderTableViewCell getCellIdentifier],
                                @"key": @"width_custom_slider"
                        };
                }

                default:
                    return nil;
            }
        }

        case EOATrackAppearanceHudActionsSection:
        {
            switch (row)
            {
                case 0:
                    return @{
                            @"title": OALocalizedString(@"reset_to_original"),
                            @"right_icon": @"ic_custom_reset",
                            @"has_options": @YES,
                            @"type": [OAIconTitleValueCell getCellIdentifier],
                            @"key": @"reset"
                    };

                default:
                    return nil;
            }
        }

        default:
            return nil;
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

    return NO;
}

- (CGFloat)heightForHeader:(NSInteger)section
{
    if (section == 0)
        return 0.001;

    NSString *sectionHeader = [self.data[section][@"header"] upperCase];
    if (!sectionHeader || sectionHeader.length == 0)
        return 36.;

    CGFloat textWidth = self.tableView.bounds.size.width - 40 - [OAUtilities getLeftMargin] * 2;
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
        if (self.trackMenuDelegate && [self.trackMenuDelegate respondsToSelector:@selector(backToTrackMenu)])
            [self.trackMenuDelegate backToTrackMenu];

        [[self.app updateGpxTracksOnMapObservable] notifyEvent];
    }];}

- (IBAction)onDoneButtonPressed:(id)sender
{
    [self dismiss:^{
        [[OAGPXDatabase sharedDb] save:self.gpx];
        if (self.trackMenuDelegate && [self.trackMenuDelegate respondsToSelector:@selector(backToTrackMenu)])
            [self.trackMenuDelegate backToTrackMenu];
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
    NSArray *values = item[@"values"];
    BOOL isOn = [self isEnabled:item[@"key"]];
    BOOL hasOptions = [item[@"has_options"] boolValue];

    UITableViewCell *outCell = nil;
    if ([item[@"type"] isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
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
            cell.textView.text = item[@"title"];

            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(onSwitchPressed:) forControlEvents:UIControlEventValueChanged];
        }
        outCell = cell;
    }
    else if ([item[@"type"] isEqualToString:[OAImageTextViewCell getCellIdentifier]])
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
            NSString *extraDesc = item[@"extra_desc"];
            [cell showExtraDesc:extraDesc && extraDesc.length > 0];

            cell.iconView.image = [UIImage imageNamed:item[@"icon"]];

            cell.descView.text = item[@"desc"];
            cell.descView.font = [UIFont systemFontOfSize:[item[@"desc_font_size"] intValue]];
            cell.descView.textColor = UIColorFromRGB(color_text_footer);

            cell.extraDescView.text = extraDesc;
            cell.extraDescView.font = [UIFont systemFontOfSize:[item[@"desc_font_size"] intValue]];
            cell.extraDescView.textColor = UIColorFromRGB(color_text_footer);
        }

        if ([cell needsUpdateConstraints])
            [cell setNeedsUpdateConstraints];

        return cell;
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
            [cell setValues:values withSelectedIndex:[_availableColoringTypes indexOfObject:_selectedColoringType]];
        }
        outCell = _colorValuesCell = cell;
    }
    else if ([item[@"type"] isEqualToString:[OAColorsTableViewCell getCellIdentifier]])
    {
        OAColorsTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAColorsTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAColorsTableViewCell getCellIdentifier]
                                                         owner:self options:nil];
            cell = (OAColorsTableViewCell *) nib[0];
            cell.dataArray = values;
            cell.delegate = self;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell showLabels:NO];
        }
        if (cell)
        {
            cell.valueLabel.tintColor = UIColorFromRGB(color_text_footer);
            cell.currentColor = [values indexOfObject:item[@"value"]];

            [cell.collectionView reloadData];
            [cell layoutIfNeeded];
        }
        outCell = cell;
    }
    else if ([item[@"type"] isEqualToString:[OATextLineViewCell getCellIdentifier]])
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
            cell.textView.text = item[@"title"];
            cell.textView.font = [UIFont systemFontOfSize:15];
            cell.textView.textColor = UIColorFromRGB(color_text_footer);
        }
        outCell = cell;
    }
    else if ([item[@"type"] isEqualToString:[OASegmentedControlCell getCellIdentifier]])
    {
        OASegmentedControlCell *cell;
        if ([item[@"key"] isEqualToString:@"width_value"])
            cell = _widthValuesCell;
        else
            cell = [tableView dequeueReusableCellWithIdentifier:[OASegmentedControlCell getCellIdentifier]];
        BOOL withImages = [item[@"with_images"] boolValue];
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
            for (OAGPXTrackAppearance *value in values)
            {
                if (withImages && [value isKindOfClass:OAGPXTrackWidth.class])
                {
                    UIImage *icon = [UIImage templateImageNamed:((OAGPXTrackWidth *) value).icon];
                    if (i == cell.segmentedControl.numberOfSegments)
                        [cell.segmentedControl insertSegmentWithImage:icon atIndex:i++ animated:NO];
                    else
                        [cell.segmentedControl setImage:icon forSegmentAtIndex:i++];
                }
            }

            NSInteger selectedIndex = 0;
            if ([item[@"key"] isEqualToString:@"width_value"])
                selectedIndex = [values indexOfObject:_selectedWidth];
            [cell.segmentedControl setSelectedSegmentIndex:selectedIndex];

            cell.segmentedControl.tag = indexPath.section << 10 | indexPath.row;
            [cell.segmentedControl removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.segmentedControl addTarget:self
                                      action:@selector(segmentChanged:)
                            forControlEvents:UIControlEventValueChanged];
        }

        if ([item[@"key"] isEqualToString:@"width_value"])
            outCell = _widthValuesCell = cell;
        else
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
        OASegmentSliderTableViewCell *cell =
                [tableView dequeueReusableCellWithIdentifier:[OASegmentSliderTableViewCell getCellIdentifier]];
        BOOL hasTopLabels = [item[@"has_top_labels"] boolValue];
        BOOL hasBottomLabels = [item[@"has_bottom_labels"] boolValue];
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
            cell.topLeftLabel.text = item[@"title"];
            cell.topRightLabel.text = [NSString stringWithFormat:@"%li", (long) [item[@"selected_value"] intValue]];
            cell.bottomLeftLabel.text = [NSString stringWithFormat:@"%li", (long) [values.firstObject intValue]];
            cell.bottomRightLabel.text = [NSString stringWithFormat:@"%li", (long) [values.lastObject intValue]];
            cell.numberOfMarks = values.count;
            cell.selectedMark = [item[@"selected_value"] intValue];

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

    OATableViewCustomFooterView *vw =
            [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
    UIFont *textFont = [UIFont systemFontOfSize:13];
    NSMutableAttributedString *textStr = [[NSMutableAttributedString alloc] initWithString:sectionFooter attributes:@{
            NSFontAttributeName: textFont,
            NSForegroundColorAttributeName: UIColorFromRGB(color_text_footer)
    }];
    vw.label.attributedText = textStr;
    return vw;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];

    if ([item[@"key"] isEqualToString:@"reset"])
    {
        [[OAGPXDatabase sharedDb] reloadGPXFile:[_app.gpxPath stringByAppendingPathComponent:self.gpx.gpxFilePath] onComplete:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                self.gpx = [[OAGPXDatabase sharedDb] getGPXItem:self.gpx.gpxFilePath];
                [self commonInit];
                [self.settings showGpx:@[self.gpx.gpxFilePath] update:YES];
                [[self.app updateGpxTracksOnMapObservable] notifyEvent];
                [self setupView];
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
    NSDictionary *item = [self getItem:indexPath];

    if ([item[@"key"] isEqualToString:@"direction_arrows"])
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
        NSDictionary *item = [self getItem:indexPath];

        if ([item[@"key"] isEqualToString:@"width_value"])
        {
            _selectedWidth = [_appearanceCollection getAvailableWidth][segment.selectedSegmentIndex];
            self.gpx.width = [_selectedWidth isCustom] ? _selectedWidth.customValue : _selectedWidth.key;

            [[self.app updateGpxTracksOnMapObservable] notifyEvent];
        }

        [self generateData:indexPath.section];
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

        if ([item[@"key"] isEqualToString:@"width_custom_slider"])
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

        [self generateData:indexPath.section row:indexPath.row];
    }
}

#pragma mark - OAFoldersCellDelegate

- (void)onItemSelected:(NSInteger)index type:(NSString *)type
{
    _selectedColoringType = _availableColoringTypes[index];
    self.gpx.coloringType = _selectedColoringType.name;

    [[self.app updateGpxTracksOnMapObservable] notifyEvent];
    [self generateData:EOATrackAppearanceHudColorsSection];
}

- (void)generateData:(NSInteger)section
{
    if (section != EOATrackAppearanceHudColorsSection)
    {
        [super generateData:section];
    }
    else
    {
        NSInteger oldCellsCount = ((NSArray *) self.data[section][@"cells"]).count;
        [self generateData:section row:EOATrackAppearanceHudColorValuesRow];
        [self generateData:section row:EOATrackAppearanceHudColorGridOrElevationDescRow];

        NSDictionary *newCellData = [self getCellDataForRow:EOATrackAppearanceHudColorGradientAndDescRow
                section:section];
        NSDictionary *sectionData = ((NSMutableArray *) self.data)[section];

        if (sectionData)
        {
            NSMutableDictionary *newSectionData = [sectionData mutableCopy];
            NSMutableArray *newRowsData = [newSectionData[@"cells"] mutableCopy];
            if (!newCellData && oldCellsCount - 1 == EOATrackAppearanceHudColorGradientAndDescRow)
                [newRowsData removeObjectAtIndex:EOATrackAppearanceHudColorGradientAndDescRow];
            else
                newRowsData[EOATrackAppearanceHudColorGradientAndDescRow] = newCellData;
            newSectionData[@"cells"] = newRowsData;
            NSMutableArray *newData = [self.data mutableCopy];
            newData[section] = newSectionData;
            self.data = newData;

            if (newCellData)
            {
                [UIView setAnimationsEnabled:NO];
                if (oldCellsCount - 1 == EOATrackAppearanceHudColorGradientAndDescRow)
                {
                    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:EOATrackAppearanceHudColorGradientAndDescRow
                                                                                inSection:section]]
                                          withRowAnimation:UITableViewRowAnimationNone];
                }
                else if (oldCellsCount - 1 == EOATrackAppearanceHudColorGridOrElevationDescRow)
                {
                    [self.tableView beginUpdates];
                    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:EOATrackAppearanceHudColorGradientAndDescRow
                                                                                inSection:section]]
                                          withRowAnimation:UITableViewRowAnimationBottom];
                    [self.tableView endUpdates];
                }
                [UIView setAnimationsEnabled:YES];
            }
            else
            {
                [UIView setAnimationsEnabled:NO];
                [self.tableView beginUpdates];
                [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:EOATrackAppearanceHudColorGradientAndDescRow
                                                                            inSection:section]]
                                      withRowAnimation:UITableViewRowAnimationFade];
                [self.tableView endUpdates];
                [UIView setAnimationsEnabled:YES];
            }
        }
    }
}

#pragma mark - OAColorsTableViewCellDelegate

- (void)colorChanged:(NSInteger)tag
{
    _selectedColor = [_appearanceCollection getColorForValue:_availableColors[tag].intValue];
    self.gpx.color = _selectedColor.colorValue;

    [[self.app updateGpxTracksOnMapObservable] notifyEvent];
    [self generateData:EOATrackAppearanceHudColorsSection
                   row:EOATrackAppearanceHudColorGridOrElevationDescRow];
}

@end
