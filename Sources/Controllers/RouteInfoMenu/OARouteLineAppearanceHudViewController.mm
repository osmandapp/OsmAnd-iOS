//
//  OARouteLineAppearanceHudViewController.mm
//  OsmAnd
//
//  Created by Skalii on 20.12.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OARouteLineAppearanceHudViewController.h"
#import "OABaseTrackMenuHudViewController.h"
#import "OARootViewController.h"
#import "OAMapHudViewController.h"
#import "OATableViewCustomFooterView.h"
#import "OAFoldersCollectionView.h"
#import "OAIconTextDividerSwitchCell.h"
#import "OAColorsTableViewCell.h"
#import "OAImageTextViewCell.h"
#import "OAFoldersCell.h"
#import "OASegmentedControlCell.h"
#import "OATextLineViewCell.h"
#import "OARoutingHelper.h"
#import "OARouteStatisticsHelper.h"
#import "OADayNightHelper.h"
#import "OAPreviewRouteLineInfo.h"
#import "OADefaultFavorite.h"
#import "OAColors.h"
#import "Localization.h"
#import "OsmAndApp.h"
#import "OARouteLayer.h"
#import "OAMapLayers.h"

#define kColoringSection 0
#define kColorGridCell 3

#define kColorDayMode OALocalizedString(@"map_settings_day")
#define kColorNightMode OALocalizedString(@"map_settings_night")

@interface OARouteAppearanceType : NSObject

@property (nonatomic) OAColoringType *coloringType;
@property (nonatomic) NSString *title;
@property (nonatomic) NSString *attrName;
@property (nonatomic) NSString *topDescription;
@property (nonatomic) NSString *bottomDescription;
@property (nonatomic, assign) BOOL isActive;

- (instancetype)initWithColoringType:(OAColoringType *)coloringType
                               title:(NSString *)title
                            attrName:(NSString *)attrName
                      topDescription:(NSString *)topDescription
                   bottomDescription:(NSString *)bottomDescription
                            isActive:(BOOL)isActive;

@end

@implementation OARouteAppearanceType

- (instancetype)initWithColoringType:(OAColoringType *)coloringType
                               title:(NSString *)title
                            attrName:(NSString *)attrName
                      topDescription:(NSString *)topDescription
                   bottomDescription:(NSString *)bottomDescription
                            isActive:(BOOL)isActive
{
    self = [super init];
    if (self)
    {
        _coloringType = coloringType;
        _title = title;
        _attrName = attrName;
        _topDescription = topDescription;
        _bottomDescription = bottomDescription;
        _isActive = isActive;
    }
    return self;
}

@end

@interface OARouteLineAppearanceHudViewController() <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, OAFoldersCellDelegate, OAColorsTableViewCellDelegate>

@property (weak, nonatomic) IBOutlet UIView *statusBarBackgroundView;

@property (weak, nonatomic) IBOutlet UIView *backButtonContainerView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *backNavBarButton;

@property (weak, nonatomic) IBOutlet UIView *applyButtonContainerView;
@property (weak, nonatomic) IBOutlet UIButton *applyButton;
@property (weak, nonatomic) IBOutlet UIButton *applyNavBarButton;

@property (weak, nonatomic) IBOutlet UILabel *titleNavBarView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionNavBarView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *backButtonLeadingConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *applyButtonTrailingConstraint;

@end

@implementation OARouteLineAppearanceHudViewController
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OARoutingHelper *_routingHelper;
    OAApplicationMode *_appMode;
    OAMapPanelViewController *_mapPanelViewController;

    CGFloat _originalStatusBarHeight;
    OAPreviewRouteLineInfo *_previewRouteLineInfo;
    OAGPXTableData *_tableData;
    BOOL _nightMode;
    NSString *_selectedDayNightMode;

    OAFoldersCell *_colorValuesCell;
    OACollectionViewCellState *_scrollCellsState;
    NSArray<OARouteAppearanceType *> *_coloringTypes;
    OARouteAppearanceType *_selectedType;
    NSArray<NSNumber *> *_availableColors;

    OAPreviewRouteLineInfo *_oldPreviewRouteLineInfo;
    NSInteger _oldDayNightMode;
}

@dynamic statusBarBackgroundView;

- (instancetype)initWithAppMode:(OAApplicationMode *)appMode
{
    self = [super initWithNibName:@"OARouteLineAppearanceHudViewController"
                           bundle:nil];
    if (self)
    {
        _appMode = appMode;
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _app = [OsmAndApp instance];
    _settings = [OAAppSettings sharedManager];
    _routingHelper = [OARoutingHelper sharedInstance];
    _mapPanelViewController = [OARootViewController instance].mapPanel;
    _previewRouteLineInfo = [self createPreviewRouteLineInfo];

    OAColoringType *currentType = [OAColoringType getRouteColoringTypeByName:_previewRouteLineInfo.coloringType.name];
    NSMutableArray<OARouteAppearanceType *> *types = [NSMutableArray array];
    for (OAColoringType *coloringType in [OAColoringType getRouteColoringTypes])
    {
        if ([coloringType isRouteInfoAttribute])
            continue;

        NSString *topDescription = [coloringType isGradient] ? OALocalizedString(@"route_line_color_elevation_description") : @"";
        NSString *bottomDescription = [coloringType isGradient] ? OALocalizedString(@"grey_color_undefined") : @"";
        BOOL isAvailable = [coloringType isAvailableForDrawingRoute:[_routingHelper getRoute] attributeName:nil];
        OARouteAppearanceType *type = [[OARouteAppearanceType alloc] initWithColoringType:coloringType
                                                                                    title:coloringType.title
                                                                                 attrName:nil
                                                                           topDescription:topDescription
                                                                        bottomDescription:bottomDescription
                                                                                 isActive:isAvailable];

        if (currentType == coloringType)
            _selectedType = type;

        if (coloringType != OAColoringType.DEFAULT)
            [types addObject:type];
    }

    NSArray<NSString *> *attributes = [OARouteStatisticsHelper getRouteStatisticAttrsNames:YES];
    for (NSString *attribute in attributes)
    {
        NSString *title = OALocalizedString([NSString stringWithFormat:@"%@_name", attribute]);
        NSString *topDescription = OALocalizedString([NSString stringWithFormat:@"%@_description", attribute]);
        NSString *bottomDescription = OALocalizedString(@"white_color_undefined");
        BOOL isAvailable = [OAColoringType.ATTRIBUTE isAvailableForDrawingRoute:[_routingHelper getRoute]
                                                                  attributeName:attribute];
        OARouteAppearanceType *type = [[OARouteAppearanceType alloc] initWithColoringType:OAColoringType.ATTRIBUTE
                                                                                    title:title
                                                                                 attrName:attribute
                                                                           topDescription:topDescription
                                                                        bottomDescription:bottomDescription
                                                                                 isActive:isAvailable];
        [types addObject:type];

        if (currentType == OAColoringType.ATTRIBUTE && [_previewRouteLineInfo.coloringType.name isEqualToString:attribute])
            _selectedType = type;
    }

    _coloringTypes = types;

    _nightMode = _settings.nightMode;
    _scrollCellsState = [[OACollectionViewCellState alloc] init];
    _selectedDayNightMode = _nightMode ? kColorNightMode : kColorDayMode;

    NSArray<OAFavoriteColor *> *colors = [OADefaultFavorite builtinColors];
    NSMutableArray<NSNumber *> *lineColors = [NSMutableArray array];
    for (OAFavoriteColor *lineColor in colors)
    {
        [lineColors addObject:@([OAUtilities colorToNumber:lineColor.color])];
    }
    _availableColors = lineColors;

    [self setOldValues];
}

- (void)setOldValues
{
    _oldPreviewRouteLineInfo = [_mapPanelViewController.mapViewController.mapLayers.routeMapLayer getPreviewRouteLineInfo];
    _oldDayNightMode = [_settings.appearanceMode get];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self generateData];
    [self setupView];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:OATableViewCustomFooterView.class
forHeaderFooterViewReuseIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [_mapPanelViewController.hudViewController hideTopControls];
    [_mapPanelViewController targetSetBottomControlsVisible:YES
                                                 menuHeight:[self isLandscape]
                                                         ? 0
                                                         : [self getViewHeight] - [OAUtilities getBottomMargin] + 4
                                                   animated:YES];
    [_mapPanelViewController.hudViewController updateMapRulerData];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        BOOL landscape = [self isLandscape];
        if (!landscape)
            [self goExpanded];
        self.backButtonContainerView.hidden = !landscape;
        self.applyButtonContainerView.hidden = !landscape;
    } completion:nil];
}

- (void)hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete
{
    [super hide:YES duration:duration onComplete:^{
        [_mapPanelViewController.hudViewController resetToDefaultRulerLayout];
        [_mapPanelViewController hideScrollableHudViewController];
        if (onComplete)
            onComplete();

        [_mapPanelViewController.mapViewController.mapLayers.routeMapLayer setPreviewRouteLineInfo:nil];
    }];
}

- (void)setupView
{
    [self setupHeaderView];
    [self setupButtonsNavigationBarView];
}

- (void)setupHeaderView
{

}

- (void)setupButtonsNavigationBarView
{
    [self.statusBarBackgroundView addBlurEffect:YES cornerRadius:0. padding:0.];
    _originalStatusBarHeight = self.statusBarBackgroundView.frame.size.height;

    [self.titleNavBarView setText:OALocalizedString(@"customize_route_line")];
    [self.descriptionNavBarView setText:_appMode.name];

    BOOL isRTL = [self.statusBarBackgroundView isDirectionRTL];
    UIImage *backImage = [UIImage templateImageNamed:@"ic_custom_arrow_back"];
    [self.backButton setImage:isRTL ? backImage.imageFlippedForRightToLeftLayoutDirection : backImage
                     forState:UIControlStateNormal];
    self.backButton.imageView.tintColor = UIColorFromRGB(color_primary_purple);
    [self.backButton addBlurEffect:YES cornerRadius:12. padding:0];
    backImage = [UIImage templateImageNamed:@"ic_navbar_chevron"];

    [self.backNavBarButton setImage:isRTL ? backImage.imageFlippedForRightToLeftLayoutDirection : backImage
                           forState:UIControlStateNormal];
    self.backNavBarButton.imageView.tintColor = UIColorFromRGB(color_primary_purple);
    [self.backNavBarButton setAttributedTitle:
                    [[NSAttributedString alloc] initWithString:OALocalizedString(@"shared_string_back")
                                                    attributes:@{ NSFontAttributeName:[UIFont systemFontOfSize:17.] }]
                                     forState:UIControlStateNormal];

    [self.applyButton addBlurEffect:YES cornerRadius:12. padding:0.];
    [self.applyButton setAttributedTitle:
                    [[NSAttributedString alloc] initWithString:OALocalizedString(@"shared_string_apply")
                                                    attributes:@{ NSFontAttributeName:[UIFont boldSystemFontOfSize:17.] }]
                                forState:UIControlStateNormal];
    [self.applyNavBarButton setAttributedTitle:
                    [[NSAttributedString alloc] initWithString:OALocalizedString(@"shared_string_apply")
                                                    attributes:@{ NSFontAttributeName:[UIFont boldSystemFontOfSize:17.] }]
                                      forState:UIControlStateNormal];
}

- (OARouteAppearanceType *)getRouteAppearanceType:(OAColoringType *)coloringType
{
    if (_coloringTypes)
    {
        for (OARouteAppearanceType *routeType in _coloringTypes)
        {
            if (routeType.coloringType == coloringType)
                return routeType;
        }
    }
    return [[OARouteAppearanceType alloc] initWithColoringType:coloringType
                                                         title:coloringType.title
                                                      attrName:nil
                                                   topDescription:@""
                                             bottomDescription:@""
                                             isActive:[coloringType isAvailableForDrawingRoute:[_routingHelper getRoute]
                                                                                 attributeName:nil]];
}

- (void)generateData
{
    if (_previewRouteLineInfo)
    {
        NSMutableArray<OAGPXTableSectionData *> *tableSections = [NSMutableArray array];

        // color section
        __block BOOL colorMapStyle = _previewRouteLineInfo.coloringType == OAColoringType.DEFAULT;
        NSMutableArray<OAGPXTableCellData *> *colorsCells = [NSMutableArray array];

        OAGPXTableSectionData *colorsSectionData = [OAGPXTableSectionData withData:@{
                kSectionCells: colorsCells,
                kSectionFooter: colorMapStyle
                        ? [NSString stringWithFormat:OALocalizedString(@"route_line_use_map_style_color"),
                                [_settings.renderer get]]
                        : @""
        }];

        OAGPXTableCellData *colorMapStyleCellData = [OAGPXTableCellData withData:@{
                kCellKey:@"color_map_style",
                kCellType:[OAIconTextDividerSwitchCell getCellIdentifier],
                kCellTitle:OALocalizedString(@"map_settings_style")
        }];
        colorMapStyleCellData.isOn = ^() { return colorMapStyle; };
        colorMapStyleCellData.onSwitch = ^(BOOL toggle) {
            colorMapStyle = toggle;
            if (colorMapStyle)
                _selectedType = [self getRouteAppearanceType:OAColoringType.DEFAULT];
            else if (_selectedType.coloringType == OAColoringType.DEFAULT)
                _selectedType = [self getRouteAppearanceType:OAColoringType.CUSTOM_COLOR];
            else
                _selectedType = [self getRouteAppearanceType:_previewRouteLineInfo.coloringType];

            _previewRouteLineInfo.coloringType = _selectedType.coloringType;
            [self updateRouteLayer:_previewRouteLineInfo];
        };
        colorMapStyleCellData.updateData = ^() {
            if ([_selectedType.coloringType isCustomColor])
            {
                UIColor *customColorDay = UIColorFromRGB([_previewRouteLineInfo getCustomColor:NO]);
                UIColor *customColorNight = UIColorFromRGB([_previewRouteLineInfo getCustomColor:YES]);
                UIColor *defaultColorDay = UIColorFromRGB(kDefaultRouteLineDayColor);
                UIColor *defaultColorNight = UIColorFromRGB(kDefaultRouteLineNightColor);
                if ([customColorDay isEqual:defaultColorDay] || [customColorNight isEqual:defaultColorNight])
                    [_previewRouteLineInfo setCustomColor:_availableColors.firstObject.intValue nightMode:_nightMode];
            }
        };
        [colorsCells addObject:colorMapStyleCellData];

        // custom coloring settings

        NSMutableArray<NSDictionary *> *lineColoringTypes = [NSMutableArray array];
        for (OARouteAppearanceType *type in _coloringTypes)
        {
            [lineColoringTypes addObject:@{
                    @"title": type.title,
                    @"available": @(type.isActive)
            }];
        }

        OAGPXTableCellData *colorTypesCellData = [OAGPXTableCellData withData:@{
                kCellKey: @"color_types",
                kCellType: [OAFoldersCell getCellIdentifier],
                kTableValues: @{
                        @"array_value": lineColoringTypes,
                        @"selected_integer_value": @([_coloringTypes indexOfObject:_selectedType])
                },
                kCellTitle: OALocalizedString(@"fav_color")
        }];
        colorTypesCellData.updateData = ^() {
            [colorTypesCellData setData:@{
                    kTableValues: @{
                            @"array_value": lineColoringTypes,
                            @"selected_integer_value": @([_coloringTypes indexOfObject:_selectedType])
                    }
            }];
        };

        NSArray<NSString *> *dayNightValues = @[kColorDayMode, kColorNightMode];
        OAGPXTableCellData *colorDayNightCellData = [OAGPXTableCellData withData:@{
                kCellKey: @"color_day_night_value",
                kCellType: [OASegmentedControlCell getCellIdentifier],
                kTableValues: @{ @"array_value": dayNightValues },
                kCellToggle: @NO
        }];
        colorDayNightCellData.updateProperty = ^(id value) {
            if ([value isKindOfClass:NSNumber.class])
            {
                NSInteger index = [value integerValue];
                _nightMode = [dayNightValues[index] isEqualToString:kColorNightMode];
                _selectedDayNightMode = _nightMode ? dayNightValues[1] : dayNightValues[0];
                [_settings.appearanceMode set:index];
            }
        };
        colorDayNightCellData.updateData = ^() {
            [[OADayNightHelper instance] forceUpdate];
            [self updateRouteLayer:_previewRouteLineInfo];
        };

        OAGPXTableCellData *colorGridCellData = [OAGPXTableCellData withData:@{
                kCellKey: @"color_grid",
                kCellType: [OAColorsTableViewCell getCellIdentifier],
                kTableValues: @{
                        @"array_value": _availableColors,
                        @"int_value": @([_previewRouteLineInfo getCustomColor:_nightMode])
                }
        }];

        colorGridCellData.updateData = ^() {
            [colorGridCellData setData:@{
                    kTableValues: @{
                            @"array_value": _availableColors,
                            @"int_value": @([_previewRouteLineInfo getCustomColor:_nightMode])
                    }
            }];
        };

        OAGPXTableCellData *topDescriptionCellData = [OAGPXTableCellData withData:@{
                kCellKey: @"top_description",
                kCellType: [OATextLineViewCell getCellIdentifier],
                kCellTitle: _selectedType.topDescription
        }];
        topDescriptionCellData.updateData = ^() {
            [topDescriptionCellData setData:@{ kCellTitle: _selectedType.topDescription }];
        };

        OAGPXTableCellData *bottomDescriptionCellData = [OAGPXTableCellData withData:@{
                kCellKey: @"bottom_description",
                kCellType: [OATextLineViewCell getCellIdentifier],
                kCellTitle: _selectedType.bottomDescription
        }];
        bottomDescriptionCellData.updateData = ^() {
            [bottomDescriptionCellData setData:@{ kCellTitle: _selectedType.bottomDescription }];
        };

        OAGPXTableCellData *colorGradientCellData = [OAGPXTableCellData withData:@{
                kCellKey: @"color_elevation_gradient",
                kCellType: [OAImageTextViewCell getCellIdentifier],
                kTableValues: @{
                        @"extra_desc": OALocalizedString([self isSelectedTypeAltitude] ? @"shared_string_max_height" : @""),
                        @"desc_font_size": @([self isSelectedTypeSlope] ? 15 : 17)
                },
                kCellDesc: OALocalizedString([self isSelectedTypeAltitude] ? @"shared_string_min_height" : @""),
                kCellRightIconName: [self isSelectedTypeSlope] ? @"img_track_gradient_slope" : @"img_track_gradient_speed"
        }];
        colorGradientCellData.updateData = ^() {
            [colorGradientCellData setData:@{
                    kTableValues: @{
                            @"extra_desc": OALocalizedString([self isSelectedTypeAltitude] ? @"shared_string_max_height" : @""),
                            @"desc_font_size": @([self isSelectedTypeSlope] ? 15 : 17)
                    },
                    kCellDesc: OALocalizedString([self isSelectedTypeAltitude] ? @"shared_string_min_height" : @""),
                    kCellRightIconName: [self isSelectedTypeSlope] ? @"img_track_gradient_slope" : @"img_track_gradient_speed"
            }];
        };

        void (^clearColorSection) (BOOL) = ^(BOOL withTypes) {
            if (withTypes)
                [colorsCells removeObject:colorTypesCellData];

            [colorsCells removeObjectsInArray:@[
                    colorDayNightCellData,
                    colorGridCellData,
                    topDescriptionCellData,
                    colorGradientCellData,
                    bottomDescriptionCellData
            ]];
        };

        void (^setColorCells) () = ^() {
            if (!colorMapStyle)
            {
                clearColorSection(NO);

                if (![colorsCells containsObject:colorTypesCellData])
                    [colorsCells addObject:colorTypesCellData];

                if ([_selectedType.coloringType isCustomColor])
                    [colorsCells addObjectsFromArray:@[colorDayNightCellData, colorGridCellData]];
                else if ([_selectedType.coloringType isGradient])
                    [colorsCells addObjectsFromArray:@[topDescriptionCellData, colorGradientCellData, bottomDescriptionCellData]];
                else if ([_selectedType.coloringType isRouteInfoAttribute])
                    [colorsCells addObjectsFromArray:@[topDescriptionCellData, bottomDescriptionCellData]];
            }
            else
            {
                clearColorSection(YES);
            }
        };

        colorsSectionData.updateData = ^() {
            setColorCells();

            for (OAGPXTableCellData *cellData in colorsCells)
            {
                if (cellData.updateData)
                    cellData.updateData();
            }

            [colorsSectionData setData:@{
                    kSectionFooter: colorMapStyle
                            ? [NSString stringWithFormat:OALocalizedString(@"route_line_use_map_style_color"),
                                                         [_settings.renderer get]]
                            : @""
            }];
        };
        [tableSections addObject:colorsSectionData];

        setColorCells();
        _tableData = [OAGPXTableData withData:@{ kTableSections: tableSections }];
    }
}

- (OAGPXTableCellData *)getCellData:(NSIndexPath *)indexPath
{
    return _tableData.sections[indexPath.section].cells[indexPath.row];
}

- (BOOL)hasInitialState
{
    return NO;
}

- (CGFloat)expandedMenuHeight
{
    return DeviceScreenHeight / 2;
}

- (CGFloat)getToolbarHeight
{
    return self.currentState == EOADraggableMenuStateInitial ? [OAUtilities getBottomMargin] : 0.;
}

- (BOOL)stopChangingHeight:(UIView *)view
{
    return [view isKindOfClass:[UISlider class]]
            || [view isKindOfClass:[UISegmentedControl class]]
            || [view isKindOfClass:[UICollectionView class]];
}

- (void)setupModeViewShadowVisibility
{
    self.topHeaderContainerView.layer.shadowOpacity = 0.0;
}

- (BOOL)showStatusBarWhenFullScreen
{
    return YES;
}

- (BOOL)hasCustomStatusBar
{
    return YES;
}

- (CGFloat)getStatusBarHeight
{
    return _originalStatusBarHeight;
}

- (void)doAdditionalLayout
{
    BOOL isRTL = [self.backButtonContainerView isDirectionRTL];
    self.backButtonLeadingConstraint.constant = [self isLandscape]
            ? (isRTL ? 0. : [self getLandscapeViewWidth] - [OAUtilities getLeftMargin] + 10.)
            : [OAUtilities getLeftMargin] + 10.;
    self.backButtonContainerView.hidden = ![self isLandscape];

    self.applyButtonTrailingConstraint.constant = [self isLandscape]
            ? (isRTL ? [self getLandscapeViewWidth] - [OAUtilities getLeftMargin] + 10. : 0.)
            : [OAUtilities getLeftMargin] + 10.;
    self.applyButtonContainerView.hidden = ![self isLandscape];
}

- (void)changeMapRulerPosition:(CGFloat)height
{
    CGFloat leftMargin = [self isLandscape]
            ? [self getLandscapeViewWidth] - [OAUtilities getLeftMargin] + 20.
            : [OAUtilities getLeftMargin] + 20.;
    [_mapPanelViewController targetSetMapRulerPosition:[self isLandscape] ? 0. : -(height - [OAUtilities getBottomMargin] + 20.)
                                                  left:leftMargin];
}

- (void)changeHud:(CGFloat)height
{
    [_mapPanelViewController targetSetBottomControlsVisible:YES
                                                 menuHeight:[self isLandscape] ? 0 : height - [OAUtilities getBottomMargin]
                                                   animated:YES];
    [self changeMapRulerPosition:height];
}

- (OAPreviewRouteLineInfo *)createPreviewRouteLineInfo
{
    NSInteger colorDay = [_settings.customRouteColorDay get:_appMode];
    NSInteger colorNight = [_settings.customRouteColorNight get:_appMode];
    OAColoringType *coloringType = [_settings.routeColoringType get:_appMode];
    NSString *routeInfoAttribute = [_settings.routeInfoAttribute get:_appMode];
    NSString *widthKey = [_settings.routeLineWidth get:_appMode];
    BOOL showTurnArrows = [_settings.routeShowTurnArrows get:_appMode];

    OAPreviewRouteLineInfo *previewRouteLineInfo = [[OAPreviewRouteLineInfo alloc] initWithCustomColorDay:colorDay
                                                                                 customColorNight:colorNight
                                                                                     coloringType:coloringType
                                                                               routeInfoAttribute:routeInfoAttribute
                                                                                            width:widthKey
                                                                                   showTurnArrows:showTurnArrows];
    return previewRouteLineInfo;
}

- (BOOL)isSelectedTypeSlope
{
    return _selectedType.coloringType == OAColoringType.SLOPE;
}

- (BOOL)isSelectedTypeAltitude
{
    return _selectedType.coloringType == OAColoringType.ALTITUDE;
}

- (void)updateRouteLayer:(OAPreviewRouteLineInfo *)previewInfo
{
    OARouteLayer *routeLayer = _mapPanelViewController.mapViewController.mapLayers.routeMapLayer;
    [routeLayer setPreviewRouteLineInfo:previewInfo];
    [_mapPanelViewController.mapViewController runWithRenderSync:^{
        [routeLayer resetLayer];
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [routeLayer refreshRoute];
    });
}

- (IBAction)onBackButtonPressed:(id)sender
{
    [self hide:YES duration:.2 onComplete:^{
        [_settings.appearanceMode set:_oldDayNightMode];
        [[OADayNightHelper instance] forceUpdate];

        [self updateRouteLayer:_oldPreviewRouteLineInfo];

        if (self.delegate)
            [self.delegate onCloseAppearance];
    }];
}

- (IBAction)onApplyButtonPressed:(id)sender
{
    [self hide:YES duration:.2 onComplete:^{
        [_settings.customRouteColorDay set:[_previewRouteLineInfo getCustomColor:NO] mode:_appMode];
        [_settings.customRouteColorNight set:[_previewRouteLineInfo getCustomColor:YES] mode:_appMode];
        [_settings.routeColoringType set:_previewRouteLineInfo.coloringType mode:_appMode];
        [_settings.routeInfoAttribute set:_previewRouteLineInfo.routeInfoAttribute mode:_appMode];
        [_settings.routeLineWidth set:_previewRouteLineInfo.width mode:_appMode];
        [_settings.routeShowTurnArrows set:_previewRouteLineInfo.showTurnArrows mode:_appMode];
        [_settings.appearanceMode set:_oldDayNightMode];
        [[OADayNightHelper instance] forceUpdate];

        [self updateRouteLayer:_previewRouteLineInfo];

        if (self.delegate)
            [self.delegate onCloseAppearance];
    }];
}

#pragma mark - OADraggableViewActions

- (void)onViewStateChanged:(CGFloat)height
{
    [self changeHud:height];
}

- (void)onViewHeightChanged:(CGFloat)height
{
    [self changeHud:height];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _tableData.sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _tableData.sections[section].cells.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAGPXTableCellData *cellData = [self getCellData:indexPath];
    UITableViewCell *outCell = nil;
    if ([cellData.type isEqualToString:[OAIconTextDividerSwitchCell getCellIdentifier]])
    {
        OAIconTextDividerSwitchCell *cell =
                [tableView dequeueReusableCellWithIdentifier:[OAIconTextDividerSwitchCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextDividerSwitchCell getCellIdentifier]
                                                         owner:self options:nil];
            cell = (OAIconTextDividerSwitchCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.dividerView.hidden = YES;
            cell.iconView.image = nil;
        }
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + 20., 0., 0.);

            cell.switchView.on = cellData.isOn ? cellData.isOn() : NO;
            cell.textView.text = cellData.title;

            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(onSwitchPressed:) forControlEvents:UIControlEventValueChanged];
        }
        outCell = cell;
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
    else if ([cellData.type isEqualToString:[OAFoldersCell getCellIdentifier]])
    {
        if (_colorValuesCell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAFoldersCell getCellIdentifier] owner:self options:nil];
            _colorValuesCell = (OAFoldersCell *) nib[0];
            _colorValuesCell.selectionStyle = UITableViewCellSelectionStyleNone;
            _colorValuesCell.separatorInset = UIEdgeInsetsMake(0., DeviceScreenWidth, 0., 0.);
            _colorValuesCell.collectionView.contentInset = UIEdgeInsetsMake(0., 20. , 0., 20.);
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
            UIImage *image = [UIImage imageNamed:cellData.rightIconName];
            cell.iconView.image = [cell isDirectionRTL] ? image.imageFlippedForRightToLeftLayoutDirection : image;

            NSString *desc = cellData.desc;
            [cell showDesc:desc && desc.length > 0];
            cell.descView.text = desc;
            cell.descView.font = [UIFont systemFontOfSize:[cellData.values[@"desc_font_size"] intValue]];
            cell.descView.textColor = UIColorFromRGB(color_text_footer);

            NSString *extraDesc = cellData.values[@"extra_desc"];
            [cell showExtraDesc:extraDesc && extraDesc.length > 0];
            cell.extraDescView.text = extraDesc;
            cell.extraDescView.font = [UIFont systemFontOfSize:[cellData.values[@"desc_font_size"] intValue]];
            cell.extraDescView.textColor = UIColorFromRGB(color_text_footer);
        }

        if ([cell needsUpdateConstraints])
            [cell setNeedsUpdateConstraints];

        return cell;
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
            for (id value in arrayValue)
            {
                if ([value isKindOfClass:NSString.class])
                {
                    if (cellData.toggle)
                    {
                        UIImage *icon = [UIImage templateImageNamed:value];
                        if (i == cell.segmentedControl.numberOfSegments)
                            [cell.segmentedControl insertSegmentWithImage:icon atIndex:i++ animated:NO];
                        else
                            [cell.segmentedControl setImage:icon forSegmentAtIndex:i++];
                    }
                    else
                    {
                        if (i == cell.segmentedControl.numberOfSegments)
                            [cell.segmentedControl insertSegmentWithTitle:value atIndex:i++ animated:NO];
                        else
                            [cell.segmentedControl setTitle:value forSegmentAtIndex:i++];
                    }
                }
            }

            NSInteger selectedIndex = 0;
            if ([cellData.key isEqualToString:@"color_day_night_value"])
                selectedIndex = [arrayValue indexOfObject:_selectedDayNightMode];
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

    if ([outCell needsUpdateConstraints])
        [outCell updateConstraints];

    return outCell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return section == 0 ? 0.001 : tableView.sectionHeaderHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    OAGPXTableSectionData *sectionData = _tableData.sections[section];
    CGFloat footerHeight = sectionData.footerHeight > 0 ? sectionData.footerHeight : 0.;

    NSString *footer = sectionData.footer;
    if (!footer || footer.length == 0)
        return footerHeight > 0 ? footerHeight : 0.001;

    return [OATableViewCustomFooterView getHeight:footer width:self.tableView.bounds.size.width] + footerHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    NSString *footer = _tableData.sections[section].footer;
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

#pragma mark - UISwitch pressed

- (void)onSwitchPressed:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:switchView.tag & 0x3FF inSection:switchView.tag >> 10];
    
    OAGPXTableCellData *cellData = [self getCellData:indexPath];
    if (cellData.onSwitch)
        cellData.onSwitch(switchView.isOn);

    OAGPXTableSectionData *sectionData = _tableData.sections[indexPath.section];
    if (sectionData.updateData)
        sectionData.updateData();

    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]
                  withRowAnimation:UITableViewRowAnimationAutomatic];
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

        if (_tableData.sections[indexPath.section].updateData)
            _tableData.sections[indexPath.section].updateData();

        [UIView setAnimationsEnabled:NO];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]
                      withRowAnimation:UITableViewRowAnimationNone];
        [UIView setAnimationsEnabled:YES];
    }
}

#pragma mark - OAFoldersCellDelegate

- (void)onItemSelected:(NSInteger)index
{
    _selectedType = _coloringTypes[index];
    _previewRouteLineInfo.coloringType = _selectedType.coloringType;
    [self updateRouteLayer:_previewRouteLineInfo];

    OAGPXTableSectionData *section = _tableData.sections[kColoringSection];
    if (section.updateData)
        section.updateData();

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
    [_previewRouteLineInfo setCustomColor:_availableColors[tag].intValue nightMode:_nightMode];
    [self updateRouteLayer:_previewRouteLineInfo];

    if (_tableData.sections.count >= 1)
    {
        OAGPXTableSectionData *colorSection = _tableData.sections[kColoringSection];
        if (colorSection.cells.count - 1 >= kColorGridCell)
        {
            OAGPXTableCellData *colorGridCell = colorSection.cells[kColorGridCell];
            if (colorGridCell.updateData)
                colorGridCell.updateData();

            [UIView setAnimationsEnabled:NO];
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kColorGridCell
                                                                        inSection:kColoringSection]]
                                  withRowAnimation:UITableViewRowAnimationNone];
            [UIView setAnimationsEnabled:YES];
        }
    }
}

@end
