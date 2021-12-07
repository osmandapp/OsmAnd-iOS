//
//  OATrackMenuAppearanceHudViewController.mm
//  OsmAnd
//
//  Created by Skalii on 25.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OATrackMenuAppearanceHudViewController.h"
#import "OATableViewCustomFooterView.h"
#import "OAFoldersCollectionView.h"
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
#import "OARouteStatisticsHelper.h"

#define kColorsSection 1

#define kColorGridOrDescriptionCell 2

@interface OATrackAppearanceItem : NSObject

@property (nonatomic) OAColoringType *coloringType;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *attrName;
@property (nonatomic, assign) BOOL isActive;

- (instancetype)initWithColoringType:(OAColoringType *)coloringType
                               title:(NSString *)title
                            attrName:(NSString *)attrName
                            isActive:(BOOL)isActive;

@end

@implementation OATrackAppearanceItem

- (instancetype)initWithColoringType:(OAColoringType *)coloringType
                               title:(NSString *)title
                            attrName:(NSString *)attrName
                            isActive:(BOOL)isActive
{
    self = [super init];
    if (self)
    {
        _coloringType = coloringType;
        _title = title;
        _attrName = attrName;
        _isActive = isActive;
    }
    return self;
}

@end

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

@end

@implementation OATrackMenuAppearanceHudViewController
{
    OAGPXAppearanceCollection *_appearanceCollection;
    NSArray<OAGPXTableSectionData *> *_tableData;

    OAFoldersCell *_colorValuesCell;
    OACollectionViewCellState *_scrollCellsState;
    OATrackAppearanceItem *_selectedItem;
    NSArray<OATrackAppearanceItem *> *_availableColoringTypes;

    OAGPXTrackColor *_selectedColor;
    NSArray<NSNumber *> *_availableColors;

    OAGPXTrackWidth *_selectedWidth;
    NSArray<NSString *> *_customWidthValues;

    OAGPXTrackSplitInterval *_selectedSplit;

    NSInteger _oldColor;
    BOOL _oldShowStartFinish;
    BOOL _oldJoinSegments;
    BOOL _oldShowArrows;
    NSString *_oldWidth;
    NSString *_oldColoringType;
    EOAGpxSplitType _oldSplitType;
    double _oldSplitInterval;

    OATrackMenuViewControllerState *_reopeningTrackMenuState;
    
    OsmAndAppInstance _app;
}

@dynamic gpx, isShown;

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
    _app = [OsmAndApp instance];
    [self updateAllValues];
}

- (void)updateAllValues
{
    _oldColor = self.gpx.color;
    _oldShowStartFinish = self.gpx.showStartFinish;
    _oldJoinSegments = self.gpx.joinSegments;
    _oldShowArrows = self.gpx.showArrows;
    _oldWidth = self.gpx.width;
    _oldColoringType = self.gpx.coloringType;
    _oldSplitType = self.gpx.splitType;
    _oldSplitInterval = self.gpx.splitInterval;

    _appearanceCollection = [[OAGPXAppearanceCollection alloc] init];
    _selectedColor = [_appearanceCollection getColorForValue:self.gpx.color];
    _selectedWidth = [_appearanceCollection getWidthForValue:self.gpx.width];
    if (!_selectedWidth)
        _selectedWidth = [OAGPXTrackWidth getDefault];
    _selectedSplit = [_appearanceCollection getSplitIntervalForType:self.gpx.splitType];
    if (self.gpx.splitInterval > 0 && self.gpx.splitType != EOAGpxSplitTypeNone)
        _selectedSplit.customValue = _selectedSplit.titles[[_selectedSplit.values indexOfObject:@(self.gpx.splitInterval)]];

    _scrollCellsState = [[OACollectionViewCellState alloc] init];
    OAColoringType *currentType = [OAColoringType getNonNullTrackColoringTypeByName:self.gpx.coloringType];

    NSMutableArray<OATrackAppearanceItem *> *items = [NSMutableArray array];
    for (OAColoringType *coloringType in [OAColoringType getTrackColoringTypes])
    {
        if ([coloringType isRouteInfoAttribute])
            continue;

        OATrackAppearanceItem *item = [[OATrackAppearanceItem alloc] initWithColoringType:coloringType title:coloringType.title attrName:nil isActive:[coloringType isAvailableForDrawingTrack:self.doc attributeName:nil]];
        [items addObject:item];

        if (currentType == coloringType)
            _selectedItem = item;
    }

    NSArray<NSString *> *attributes = [OARouteStatisticsHelper getRouteStatisticAttrsNames:YES];

    for (NSString *attribute in attributes)
    {
        BOOL isAvailable = [OAColoringType.ATTRIBUTE isAvailableForDrawingTrack:self.doc attributeName:attribute];
        OATrackAppearanceItem *item = [[OATrackAppearanceItem alloc] initWithColoringType:OAColoringType.ATTRIBUTE title:OALocalizedString([NSString stringWithFormat:@"%@_name", attribute]) attrName:attribute isActive:isAvailable];
        [items addObject:item];

        if (currentType == OAColoringType.ATTRIBUTE && [self.gpx.coloringType isEqualToString:attribute])
            _selectedItem = item;
    }

    _availableColoringTypes = items;

    NSMutableArray<NSNumber *> *trackColors = [NSMutableArray array];
    for (OAGPXTrackColor *trackColor in [_appearanceCollection getAvailableColors])
    {
        [trackColors addObject:@(trackColor.colorValue)];
    }
    _availableColors = trackColors;

    NSMutableArray *customWidthValues = [NSMutableArray array];
    for (NSInteger i = [OAGPXTrackWidth getCustomTrackWidthMin]; i <= [OAGPXTrackWidth getCustomTrackWidthMax]; i++)
    {
        [customWidthValues addObject:[NSString stringWithFormat:@"%li", i]];
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

    if (!self.isShown)
    {
        [self.settings showGpx:@[self.gpx.gpxFilePath] update:YES];
        self.isShown = YES;
    }
}

- (void)applyLocalization
{
    [self.titleView setText:OALocalizedString(@"map_settings_appearance")];
}

- (void)setupView
{
    self.titleIconView.image = [UIImage templateImageNamed:@"ic_custom_appearance"];
    self.titleIconView.tintColor = UIColorFromRGB(color_footer_icon_gray);

    [self.doneButton addBlurEffect:YES cornerRadius:12. padding:0.];
    [self.doneButton setAttributedTitle:
                    [[NSAttributedString alloc] initWithString:OALocalizedString(@"shared_string_done")
                                                    attributes:@{ NSFontAttributeName:[UIFont boldSystemFontOfSize:17.] }]
                               forState:UIControlStateNormal];

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
            kSectionCells: @[
                    [OAGPXTableCellData withData:@{
                        kCellKey:@"direction_arrows",
                        kCellType:[OAIconTextDividerSwitchCell getCellIdentifier],
                        kCellTitle:OALocalizedString(@"gpx_dir_arrows"),
                        kCellOnSwitch: ^(BOOL toggle) {
                                self.gpx.showArrows = toggle;
                                [[_app updateGpxTracksOnMapObservable] notifyEvent];
                        },
                        kCellIsOn: ^() { return self.gpx.showArrows; }
                    }],
                    [OAGPXTableCellData withData:@{
                        kCellKey:@"start_finish_icons",
                        kCellType:[OAIconTextDividerSwitchCell getCellIdentifier],
                        kCellTitle:OALocalizedString(@"track_show_start_finish_icons"),
                        kCellOnSwitch: ^(BOOL toggle) {
                                self.gpx.showStartFinish = toggle;
                                [[_app updateGpxTracksOnMapObservable] notifyEvent];
                        },
                        kCellIsOn: ^() { return self.gpx.showStartFinish; }
                    }]
            ]
    }]];

    NSMutableArray<OAGPXTableCellData *> *colorsCells = [NSMutableArray array];

    OAGPXTableCellData *colorTitle = [OAGPXTableCellData withData:@{
            kCellKey: @"color_title",
            kCellType: [OAIconTitleValueCell getCellIdentifier],
            kTableValues: @{ @"string_value": _selectedItem.title },
            kCellTitle: OALocalizedString(@"fav_color")
    }];

    [colorTitle setData:@{
            kTableUpdateData: ^() {
                [colorTitle setData:@{ kTableValues: @{@"string_value": _selectedItem.title } }];
            }
    }];
    [colorsCells addObject:colorTitle];

    NSMutableArray<NSDictionary *> *trackColoringTypes = [NSMutableArray array];
    for (OATrackAppearanceItem *item in _availableColoringTypes)
    {
        [trackColoringTypes addObject:@{
            @"title": item.title,
            @"type": item.coloringType == OAColoringType.ATTRIBUTE ? item.attrName : item.coloringType.name,
            @"available": @(item.isActive)
        }];
    }

    OAGPXTableCellData *colorValues = [OAGPXTableCellData withData:@{
            kCellKey: @"color_values",
            kCellType: [OAFoldersCell getCellIdentifier],
            kTableValues: @{
                @"array_value": trackColoringTypes,
                @"selected_integer_value": @([_availableColoringTypes indexOfObject:_selectedItem])
            },
            kCellTitle: OALocalizedString(@"fav_color")
    }];

    [colorValues setData:@{
        kTableUpdateData: ^() {
            NSMutableArray<NSDictionary *> *newTrackColoringTypes = [NSMutableArray array];
            for (OATrackAppearanceItem *item in _availableColoringTypes)
            {
                [newTrackColoringTypes addObject:@{
                        @"title": item.title,
                        @"type": item.coloringType == OAColoringType.ATTRIBUTE ? item.attrName : item.coloringType.name,
                        @"available": @(item.isActive)
                }];
            }
            [colorValues setData:@{
                kTableValues: @{
                    @"array_value": newTrackColoringTypes,
                    @"selected_integer_value": @([_availableColoringTypes indexOfObject:_selectedItem])
                }
            }];
        }
    }];
    [colorsCells addObject:colorValues];

    OAGPXTableCellData * (^generateDescriptionCell) (NSString *, NSString *) = ^ (NSString *key, NSString *description) {
        return [OAGPXTableCellData withData:@{
                kCellKey: key,
                kCellType: [OATextLineViewCell getCellIdentifier],
                kCellTitle: description
        }];
    };

    OAGPXTableCellData * (^generateGridOrDescriptionCell) (void) = ^{
        OAGPXTableCellData *gridOrDescriptionCell;
        if ([_selectedItem.coloringType isTrackSolid])
        {
            gridOrDescriptionCell = [OAGPXTableCellData withData:@{
                kCellKey: @"color_grid",
                kCellType: [OAColorsTableViewCell getCellIdentifier],
                kTableValues: @{
                    @"int_value": @(_selectedColor.colorValue),
                    @"array_value": _availableColors
                }
            }];

            [gridOrDescriptionCell setData:@{
                kTableUpdateData: ^() {
                [gridOrDescriptionCell setData:@{
                    kTableValues: @{
                        @"int_value": @(_selectedColor.colorValue),
                        @"array_value": _availableColors
                    }
                }];
            }
            }];
        }
        else if ([_selectedItem.coloringType isGradient])
        {
            gridOrDescriptionCell = generateDescriptionCell(@"color_elevation_description",
                    OALocalizedString(@"route_line_color_elevation_description"));
        }
        else if ([_selectedItem.coloringType isRouteInfoAttribute])
        {
            gridOrDescriptionCell = generateDescriptionCell(@"color_attribute_description",
                    OALocalizedString(@"white_color_undefined"));
        }
        return gridOrDescriptionCell;
    };
    __block OAGPXTableCellData *gridOrDescriptionCell = generateGridOrDescriptionCell();
    [colorsCells addObject:gridOrDescriptionCell];

    if ([_selectedItem.coloringType isGradient])
    {
        [colorsCells addObject:[self generateDataForColorElevationGradientCell]];

        if ([self isSelectedTypeSpeed] || [self isSelectedTypeAltitude])
        {
            [colorsCells addObject:generateDescriptionCell(@"color_extra_description",
                    OALocalizedString(@"grey_color_undefined"))];
        }
    }

    OAGPXTableSectionData *colorsSection = [OAGPXTableSectionData withData:@{ kSectionCells: colorsCells }];
    [colorsSection setData:@{
        kTableUpdateData: ^() {
            NSInteger index = [colorsCells indexOfObject:gridOrDescriptionCell];
            if (index != NSNotFound)
            {
                gridOrDescriptionCell = generateGridOrDescriptionCell();
                colorsSection.cells[index] = gridOrDescriptionCell;

                OAGPXTableCellData *lastCell = colorsSection.cells.lastObject;
                if ([lastCell.key isEqualToString:@"color_extra_description"])
                    [colorsSection.cells removeObject:lastCell];

                BOOL hasElevationGradient = [colorsSection.cells.lastObject.key isEqualToString:@"color_elevation_gradient"];
                if ([_selectedItem.coloringType isGradient] && !hasElevationGradient)
                    [colorsSection.cells addObject:[self generateDataForColorElevationGradientCell]];
                else if (![_selectedItem.coloringType isGradient] && hasElevationGradient)
                    [colorsSection.cells removeObject:colorsSection.cells.lastObject];

                if ([self isSelectedTypeSpeed] || [self isSelectedTypeAltitude])
                    [colorsSection.cells addObject:generateDescriptionCell(@"color_extra_description",
                            OALocalizedString(@"grey_color_undefined"))];
            }
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
            kTableValues: @{ @"string_value": _selectedWidth.title },
            kCellTitle: OALocalizedString(@"shared_string_width")
    }];
    [widthTitle setData:@{
            kTableUpdateData: ^() {
                [widthTitle setData:@{ kTableValues: @{ @"string_value": _selectedWidth.title } }];
            }
    }];
    [widthCells addObject:widthTitle];

    OAGPXTableCellData *widthValue = [OAGPXTableCellData withData:@{
            kCellKey: @"width_value",
            kCellType: [OASegmentedControlCell getCellIdentifier],
            kTableValues: @{ @"array_value": [_appearanceCollection getAvailableWidth] },
            kCellToggle: @YES
    }];
    [widthCells addObject:widthValue];
    [widthCells addObject:[OAGPXTableCellData withData:@{
            kCellKey: @"width_empty_space",
            kCellType: [OADividerCell getCellIdentifier],
            kTableValues: @{ @"float_value": @14.0 }
    }]];

    if ([_selectedWidth isCustom])
        [widthCells addObject:[self generateDataForWidthCustomSliderCell]];

    OAGPXTableSectionData *widthSection = [OAGPXTableSectionData withData:@{ kSectionCells: widthCells }];

    [widthValue setData:@{
            kTableUpdateData: ^() {
                [widthValue setData:@{ kTableValues: @{ @"array_value": [_appearanceCollection getAvailableWidth] } }];
        
                if ([_selectedWidth isCustom] && widthSection.cells.lastObject.updateProperty)
                    widthSection.cells.lastObject.updateProperty(@([_selectedWidth.customValue intValue] - 1));
            },
            kTableUpdateProperty: ^(id value) {
                if ([value isKindOfClass:NSNumber.class])
                {
                    _selectedWidth = [_appearanceCollection getAvailableWidth][[value intValue]];
                    self.gpx.width = [_selectedWidth isCustom] ? _selectedWidth.customValue : _selectedWidth.key;

                    [[_app updateGpxTracksOnMapObservable] notifyEvent];
                }
            }
    }];

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

    NSMutableArray<OAGPXTableCellData *> *splitCells = [NSMutableArray array];
    OAGPXTableCellData *splitTitle = [OAGPXTableCellData withData:@{
            kCellKey: @"split_title",
            kCellType: [OAIconTitleValueCell getCellIdentifier],
            kTableValues: @{ @"string_value": _selectedSplit.title },
            kCellTitle: OALocalizedString(@"gpx_split_interval")
    }];
    [splitTitle setData:@{
            kTableUpdateData: ^() {
                [splitTitle setData:@{ kTableValues: @{ @"string_value": _selectedSplit.title } }];
            }
    }];
    [splitCells addObject:splitTitle];

    __block OAGPXTableCellData *sliderOrDescriptionCell = [self generateDataForSplitCustomSliderCell];

    OAGPXTableCellData *splitValue = [OAGPXTableCellData withData:@{
            kCellKey: @"split_value",
            kCellType: [OASegmentedControlCell getCellIdentifier],
            kTableValues: @{ @"array_value": [_appearanceCollection getAvailableSplitIntervals] },
            kCellToggle: @NO
    }];
    [splitValue setData:@{
            kTableUpdateData: ^() {
                [splitValue setData:@{ kTableValues: @{ @"array_value": [_appearanceCollection getAvailableSplitIntervals] } }];
            },
            kTableUpdateProperty: ^(id value) {
                if ([value isKindOfClass:NSNumber.class])
                {
                    NSArray<OAGPXTrackSplitInterval *> *availableSplitIntervals = [_appearanceCollection getAvailableSplitIntervals];
                    NSInteger index = [value integerValue];
                    if (availableSplitIntervals.count > index)
                    {
                        _selectedSplit = availableSplitIntervals[index];
                        CGFloat splitInterval = 0.;
                        if ([_selectedSplit isCustom])
                        {
                            NSInteger indexOfCustomValue = 0;
                            if ([sliderOrDescriptionCell.values.allKeys containsObject:@"array_value"]
                                    && [sliderOrDescriptionCell.values.allKeys containsObject:@"custom_string_value"])
                            {
                                indexOfCustomValue = [sliderOrDescriptionCell.values[@"array_value"]
                                        indexOfObject:sliderOrDescriptionCell.values[@"custom_string_value"]];
                            }
                            if (indexOfCustomValue != NSNotFound)
                                splitInterval = [_selectedSplit.values[indexOfCustomValue] doubleValue];
                        }

                        self.gpx.splitType = _selectedSplit.type;
                        self.gpx.splitInterval = splitInterval;
                        if (self.gpx.splitInterval > 0 && self.gpx.splitType != EOAGpxSplitTypeNone)
                        {
                            NSInteger indexOfValue = [_selectedSplit.values indexOfObject:@(self.gpx.splitInterval)];
                            if (indexOfValue != NSNotFound)
                                _selectedSplit.customValue = _selectedSplit.titles[indexOfValue];
                        }

                        [[_app updateGpxTracksOnMapObservable] notifyEvent];
                    }
                }
            }
    }];
    [splitCells addObject:splitValue];

    [splitCells addObject:sliderOrDescriptionCell];

    OAGPXTableSectionData *splitSection = [OAGPXTableSectionData withData:@{
            kSectionCells: splitCells,
            kSectionFooter: OALocalizedString(@"gpx_split_interval_descr")
    }];
    [splitSection setData:@{
            kTableUpdateData: ^() {
                NSInteger index = [splitCells indexOfObject:sliderOrDescriptionCell];
                if (index != NSNotFound)
                {
                    sliderOrDescriptionCell = [self generateDataForSplitCustomSliderCell];
                    splitSection.cells[index] = sliderOrDescriptionCell;
                }
                for (OAGPXTableCellData *cell in splitSection.cells)
                {
                    if (cell.updateData)
                        cell.updateData();
                }
            }
    }];
    [appearanceSections addObject:splitSection];

    [appearanceSections addObject:[OAGPXTableSectionData withData:@{
            kSectionCells: @[[OAGPXTableCellData withData:@{
                    kCellKey:@"join_gaps",
                    kCellType:[OAIconTextDividerSwitchCell getCellIdentifier],
                    kCellTitle:OALocalizedString(@"gpx_join_gaps"),
                    kCellOnSwitch: ^(BOOL toggle) {
                            self.gpx.joinSegments = toggle;
                            [[_app updateGpxTracksOnMapObservable] notifyEvent];
                    },
                    kCellIsOn: ^() { return self.gpx.joinSegments; }
            }]],
            kSectionFooter: OALocalizedString(@"gpx_join_gaps_descr")
    }]];

    [appearanceSections addObject:[OAGPXTableSectionData withData:@{
            kSectionCells: @[[OAGPXTableCellData withData:@{
                    kCellKey: @"reset",
                    kCellType: [OAIconTitleValueCell getCellIdentifier],
                    kCellTitle: OALocalizedString(@"reset_to_original"),
                    kCellRightIconName: @"ic_custom_reset",
                    kCellToggle: @YES,
                    kCellButtonPressed: ^() {
                        [[OAGPXDatabase sharedDb] reloadGPXFile:[_app.gpxPath stringByAppendingPathComponent:self.gpx.gpxFilePath]
                                                     onComplete:^{
                            dispatch_async(dispatch_get_main_queue(), ^{
                                self.gpx = [[OAGPXDatabase sharedDb] getGPXItem:self.gpx.gpxFilePath];
                                [self updateGpxData];
                                [self updateAllValues];
                                [self.settings showGpx:@[self.gpx.gpxFilePath] update:YES];
                                [[_app updateGpxTracksOnMapObservable] notifyEvent];
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
            }]],
            kSectionHeader:OALocalizedString(@"actions")
    }]];

    _tableData = appearanceSections;
}

- (BOOL)adjustCentering
{
    return YES;
}

- (BOOL)stopChangingHeight:(UIView *)view
{
    return [view isKindOfClass:[UISlider class]]
            || [view isKindOfClass:[UISegmentedControl class]]
            || [view isKindOfClass:[UICollectionView class]];
}

- (OAGPXTableCellData *)generateDataForColorElevationGradientCell
{
    NSString * (^generateDescription) (void) = ^{
        if ([self isSelectedTypeSpeed])
            return [OAOsmAndFormatter getFormattedSpeed:0.0];
        else if ([self isSelectedTypeAltitude])
            return [OAOsmAndFormatter getFormattedAlt:self.analysis.minElevation];
        else if ([self isSelectedTypeSlope])
            return OALocalizedString(@"grey_color_undefined");
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
            kTableValues: @{
                    @"extra_desc": generateExtraDescription(),
                    @"desc_font_size": @([self isSelectedTypeSlope] ? 15 : 17)
            },
            kCellDesc: generateDescription(),
            kCellRightIconName: [self isSelectedTypeSlope] ? @"img_track_gradient_slope" : @"img_track_gradient_speed"
    }];
    [colorGradient setData:@{
            kTableUpdateData: ^() {
                [colorGradient setData:@{
                        kTableValues: @{
                                @"extra_desc": generateExtraDescription(),
                                @"desc_font_size": @([self isSelectedTypeSlope] ? 15 : 17)
                        },
                        kCellDesc: generateDescription(),
                        kCellRightIconName: [self isSelectedTypeSlope] ? @"img_track_gradient_slope" : @"img_track_gradient_speed"
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
            kTableValues: @{
                    @"custom_string_value": _selectedWidth.customValue,
                    @"array_value": _customWidthValues,
                    @"has_top_labels": @NO,
                    @"has_bottom_labels": @YES,
            }
    }];
    [customSliderCell setData:@{
            kTableUpdateData: ^() {
                [customSliderCell setData:@{
                        kTableValues: @{
                                @"custom_string_value": _selectedWidth.customValue,
                                @"array_value": _customWidthValues,
                                @"has_top_labels": @NO,
                                @"has_bottom_labels": @YES,
                        }
                }];
            },
            kTableUpdateProperty: ^(id value) {
                if ([value isKindOfClass:NSNumber.class])
                {
                    NSString *selectedValue = _customWidthValues[[value intValue]];
                    if (![_selectedWidth.customValue isEqualToString:selectedValue])
                        self.gpx.width = _selectedWidth.customValue = selectedValue;

                    [[_app updateGpxTracksOnMapObservable] notifyEvent];
                }
            }
    }];

    return customSliderCell;
}

- (OAGPXTableCellData *)generateDataForSplitCustomSliderCell
{
    OAGPXTableCellData *sliderOrDescriptionCell;
    if (_selectedSplit.isCustom)
    {
        sliderOrDescriptionCell = [OAGPXTableCellData withData:@{
                kCellKey: @"split_custom_slider",
                kCellType: [OASegmentSliderTableViewCell getCellIdentifier],
                kCellTitle: OALocalizedString(@"shared_string_interval"),
                kTableValues: @{
                        @"custom_string_value": _selectedSplit.customValue,
                        @"array_value": _selectedSplit.titles,
                        @"has_top_labels": @YES,
                        @"has_bottom_labels": @YES,
                }
        }];
        [sliderOrDescriptionCell setData:@{
                kTableUpdateData: ^() {
                    [sliderOrDescriptionCell setData:@{
                            kTableValues: @{
                                    @"custom_string_value": _selectedSplit.customValue,
                                    @"array_value": _selectedSplit.titles,
                                    @"has_top_labels": @YES,
                                    @"has_bottom_labels": @YES,
                            }
                    }];
                },
                kTableUpdateProperty: ^(id value) {
                    if ([value isKindOfClass:NSNumber.class])
                    {
                        NSString *customValue = _selectedSplit.titles[[value intValue]];
                        if (![_selectedSplit.customValue isEqualToString:customValue])
                        {
                            _selectedSplit.customValue = customValue;
                            self.gpx.splitInterval = _selectedSplit.values[[value intValue]].doubleValue;
                        }
                        [[_app updateGpxTracksOnMapObservable] notifyEvent];
                    }
                }
        }];
    }
    else
    {
        sliderOrDescriptionCell = [OAGPXTableCellData withData:@{
                kCellKey: @"split_none_descr",
                kCellType: [OATextLineViewCell getCellIdentifier],
                kCellTitle: OALocalizedString(@"gpx_split_interval_none_descr")
        }];
    }

    return sliderOrDescriptionCell;
}

- (OAGPXTableCellData *)getCellData:(NSIndexPath *)indexPath
{
    return _tableData[indexPath.section].cells[indexPath.row];
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
    return _selectedItem.coloringType == OAColoringType.SLOPE;
}

- (BOOL)isSelectedTypeSpeed
{
    return _selectedItem.coloringType == OAColoringType.SPEED;
}

- (BOOL)isSelectedTypeAltitude
{
    return _selectedItem.coloringType == OAColoringType.ALTITUDE;
}

- (IBAction)onBackButtonPressed:(id)sender
{
    [self hide:YES duration:.2 onComplete:^{
        if (_reopeningTrackMenuState)
        {
            self.gpx.color = _oldColor;
            self.gpx.showStartFinish = _oldShowStartFinish;
            self.gpx.joinSegments = _oldJoinSegments;
            self.gpx.showArrows = _oldShowArrows;
            self.gpx.width = _oldWidth;
            self.gpx.coloringType = _oldColoringType;
            self.gpx.splitType = _oldSplitType;
            self.gpx.splitInterval = _oldSplitInterval;
            [self.mapPanelViewController openTargetViewWithGPX:self.gpx
                                                  trackHudMode:EOATrackMenuHudMode
                                                         state:_reopeningTrackMenuState];
        }

        [[_app updateGpxTracksOnMapObservable] notifyEvent];
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
    return _tableData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _tableData[section].cells.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return _tableData[section].header;
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
                cell.rightIconView.image = [UIImage templateImageNamed:cellData.rightIconName];
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
            cell.separatorInset = UIEdgeInsetsMake(0., DeviceScreenWidth, 0., 0.);
        }
        if (cell)
        {
            NSString *extraDesc = cellData.values[@"extra_desc"];
            [cell showExtraDesc:extraDesc && extraDesc.length > 0];

            cell.iconView.image = [UIImage imageNamed:cellData.rightIconName];

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
        if (_colorValuesCell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAFoldersCell getCellIdentifier] owner:self options:nil];
            _colorValuesCell = (OAFoldersCell *) nib[0];
            _colorValuesCell.selectionStyle = UITableViewCellSelectionStyleNone;
            _colorValuesCell.separatorInset = UIEdgeInsetsMake(0., DeviceScreenWidth, 0., 0.);
            _colorValuesCell.backgroundColor = UIColor.whiteColor;
            _colorValuesCell.collectionView.backgroundColor = UIColor.whiteColor;
            _colorValuesCell.collectionView.cellIndex = indexPath;
            _colorValuesCell.collectionView.state = _scrollCellsState;
            _colorValuesCell.collectionView.foldersDelegate = self;
        }
        if (_colorValuesCell)
        {
            NSInteger selectedIndex = [cellData.values[@"selected_integer_value"] integerValue];
            [_colorValuesCell.collectionView setValues:cellData.values[@"array_value"]
                      withSelectedIndex:selectedIndex != NSNotFound ? selectedIndex : 0];
            [_colorValuesCell.collectionView reloadData];
        }
        outCell = _colorValuesCell;
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
            [cell makeSmallMargins:indexPath.row != [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1];
            cell.textView.text = cellData.title;
            cell.textView.font = [UIFont systemFontOfSize:15];
            cell.textView.textColor = UIColorFromRGB(color_text_footer);
        }
        outCell = cell;
    }
    else if ([cellData.type isEqualToString:[OASegmentedControlCell getCellIdentifier]])
    {
        NSArray *arrayValue = cellData.values[@"array_value"];
        OASegmentedControlCell *cell = cellData.values[@"cell_value"];
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
            [cell.segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName : UIColorFromRGB(color_primary_purple),
                                                                       NSFontAttributeName : [UIFont boldSystemFontOfSize:15.0f]}
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
                else if (!cellData.toggle && [value isKindOfClass:OAGPXTrackSplitInterval.class])
                {
                    if (i == cell.segmentedControl.numberOfSegments)
                        [cell.segmentedControl insertSegmentWithTitle:value.title atIndex:i++ animated:NO];
                    else
                        [cell.segmentedControl setTitle:value.title forSegmentAtIndex:i++];
                }
            }

            NSInteger selectedIndex = 0;
            if ([cellData.key isEqualToString:@"width_value"])
                selectedIndex = [arrayValue indexOfObject:_selectedWidth];
            else if ([cellData.key isEqualToString:@"split_value"])
                selectedIndex = [arrayValue indexOfObject:_selectedSplit];
            [cell.segmentedControl setSelectedSegmentIndex:selectedIndex];

            cell.segmentedControl.tag = indexPath.section << 10 | indexPath.row;
            [cell.segmentedControl removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.segmentedControl addTarget:self
                                      action:@selector(segmentChanged:)
                            forControlEvents:UIControlEventValueChanged];

            NSMutableDictionary *values = [cellData.values mutableCopy];
            values[@"cell_value"] = cell;
            [cellData setData:values];
        }
        outCell = cell;
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
            cell.topLeftLabel.text = cellData.title;
            cell.topRightLabel.text = cellData.values[@"custom_string_value"];
            cell.topRightLabel.textColor = UIColorFromRGB(color_primary_purple);
            cell.topRightLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
            cell.bottomLeftLabel.text = arrayValue.firstObject;
            cell.bottomRightLabel.text = arrayValue.lastObject;
            cell.numberOfMarks = arrayValue.count;
            cell.selectedMark = [arrayValue indexOfObject:cellData.values[@"custom_string_value"]];

            cell.sliderView.tag = indexPath.section << 10 | indexPath.row;
            [cell.sliderView removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
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

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    NSString *footer = _tableData[section].footer;
    if (!footer || footer.length == 0)
        return 0.001;

    return [OATableViewCustomFooterView getHeight:footer width:self.tableView.bounds.size.width];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    NSString *footer = _tableData[section].footer;
    if (!footer || footer.length == 0)
        return nil;

    OATableViewCustomFooterView *vw =
            [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
    UIFont *textFont = [UIFont systemFontOfSize:13];
    NSMutableAttributedString *textStr = [[NSMutableAttributedString alloc] initWithString:footer attributes:@{
            NSFontAttributeName: textFont,
            NSForegroundColorAttributeName: UIColorFromRGB(color_text_footer)
    }];
    vw.label.attributedText = textStr;
    return vw;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAGPXTableCellData *cellData = [self getCellData:indexPath];

    if (cellData.onButtonPressed)
        cellData.onButtonPressed();

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

        if (cellData.updateProperty)
            cellData.updateProperty(@(segment.selectedSegmentIndex));

        if (_tableData[indexPath.section].updateData)
            _tableData[indexPath.section].updateData();

        [UIView setAnimationsEnabled:NO];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]
                      withRowAnimation:UITableViewRowAnimationNone];
        [UIView setAnimationsEnabled:YES];
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

        if (cellData.updateProperty)
            cellData.updateProperty(@(cell.selectedMark));

        if (cellData.updateData)
            cellData.updateData();

        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark - OAFoldersCellDelegate

- (void)onItemSelected:(NSInteger)index type:(NSString *)type
{
    _selectedItem = _availableColoringTypes[index];
    self.gpx.coloringType = _selectedItem.coloringType == OAColoringType.ATTRIBUTE ? _selectedItem.attrName : _selectedItem.coloringType.name;

    [[_app updateGpxTracksOnMapObservable] notifyEvent];

    _tableData[kColorsSection].updateData();
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

    [[_app updateGpxTracksOnMapObservable] notifyEvent];

    _tableData[kColorsSection].cells[kColorGridOrDescriptionCell].updateData();
    [UIView setAnimationsEnabled:NO];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kColorGridOrDescriptionCell inSection:kColorsSection]]
                          withRowAnimation:UITableViewRowAnimationNone];
    [UIView setAnimationsEnabled:YES];
}

@end
