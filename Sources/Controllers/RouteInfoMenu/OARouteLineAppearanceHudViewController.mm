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
#import "OAPreviewRouteLineLayer.h"
#import "OATableViewCustomFooterView.h"
#import "OAFoldersCollectionView.h"
#import "OAMapRendererView.h"
#import "OASlider.h"
#import "OADividerCell.h"
#import "OAIconTextDividerSwitchCell.h"
#import "OAColorsTableViewCell.h"
#import "OAImageTextViewCell.h"
#import "OAFoldersCell.h"
#import "OASegmentedControlCell.h"
#import "OASegmentSliderTableViewCell.h"
#import "OATextLineViewCell.h"
#import "OAIconTitleValueCell.h"
#import "OAAutoObserverProxy.h"
#import "OAColors.h"
#import "Localization.h"
#import "OARoutingHelper.h"
#import "OARouteStatisticsHelper.h"
#import "OADayNightHelper.h"
#import "OAMapLayers.h"
#import "OAPreviewRouteLineInfo.h"
#import "OADefaultFavorite.h"

#define kColorDayMode OALocalizedString(@"map_settings_day")
#define kColorNightMode OALocalizedString(@"map_settings_night")

#define kAppearanceLineMargin 20.

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

@interface OARouteWidthMode : NSObject

@property (nonatomic) NSString *title;
@property (nonatomic) NSString *icon;
@property (nonatomic) NSString *widthKey;

+ (OARouteWidthMode *)DEFAULT;
+ (OARouteWidthMode *)THIN;
+ (OARouteWidthMode *)MEDIUM;
+ (OARouteWidthMode *)THICK;
+ (OARouteWidthMode *)CUSTOM;

+ (NSArray<OARouteWidthMode *> *)getRouteWidthModes;

@end

static OARouteWidthMode * DEFAULT;
static OARouteWidthMode * THIN;
static OARouteWidthMode * MEDIUM;
static OARouteWidthMode * THICK;
static OARouteWidthMode * CUSTOM;

static NSArray<OARouteWidthMode *> * WIDTH_MODES = @[OARouteWidthMode.THIN, OARouteWidthMode.MEDIUM, OARouteWidthMode.THICK, OARouteWidthMode.CUSTOM];

@implementation OARouteWidthMode

- (instancetype)initWithTitle:(NSString *)title icon:(NSString *)icon widthKey:(NSString *)widthKey
{
    self = [super init];
    if (self) {
        _title = title;
        _icon = icon;
        _widthKey = widthKey;
    }
    return self;
}

+ (OARouteWidthMode *)DEFAULT
{
    if (!DEFAULT)
    {
        DEFAULT = [[OARouteWidthMode alloc] initWithTitle:@"map_settings_style"
                                                     icon:nil
                                                 widthKey:nil];
    }
    return DEFAULT;
}
+ (OARouteWidthMode *)THIN
{
    if (!THIN)
    {
        THIN = [[OARouteWidthMode alloc] initWithTitle:@"rendering_value_thin_name"
                                                  icon:@"ic_custom_track_line_thin"
                                              widthKey:@"thin"];
    }
    return THIN;
}

+ (OARouteWidthMode *)MEDIUM
{
    if (!MEDIUM)
    {
        MEDIUM = [[OARouteWidthMode alloc] initWithTitle:@"rendering_value_medium_name"
                                                    icon:@"ic_custom_track_line_medium"
                                                widthKey:@"medium"];
    }
    return MEDIUM;
}

+ (OARouteWidthMode *)THICK
{
    if (!THICK)
    {
        THICK = [[OARouteWidthMode alloc] initWithTitle:@"rendering_value_bold_name"
                                                   icon:@"ic_custom_track_line_bold"
                                               widthKey:@"bold"];
    }
    return THICK;
}

+ (OARouteWidthMode *)CUSTOM
{
    if (!CUSTOM)
    {
        CUSTOM = [[OARouteWidthMode alloc] initWithTitle:@"shared_string_custom"
                                                    icon:@"ic_custom_slider"
                                                widthKey:nil];
    }
    return CUSTOM;
}

+ (NSArray<OARouteWidthMode *> *)getRouteWidthModes
{
    return WIDTH_MODES;
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

@property (weak, nonatomic) IBOutlet UIView *contentContainer;

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

    OARouteWidthMode *_selectedWidthMode;

    OAPreviewRouteLineInfo *_oldPreviewRouteLineInfo;
    NSInteger _oldDayNightMode;

    NSInteger _sectionColors;
    NSInteger _cellColorGrid;
    
    OAAutoObserverProxy *_mapSourceUpdatedObserver;
}

@dynamic statusBarBackgroundView, contentContainer;

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
    _app.mapMode = OAMapModeFree;
    _settings = [OAAppSettings sharedManager];
    _routingHelper = [OARoutingHelper sharedInstance];
    _mapPanelViewController = [OARootViewController instance].mapPanel;
    
    _mapSourceUpdatedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                 withHandler:@selector(onMapSourceUpdated)
                                                  andObserve:[OARootViewController instance].mapPanel.mapViewController.mapSourceUpdatedObservable];

    [self setOldValues];
    [self updateAllValues];
}

- (void)setOldValues
{
    _oldPreviewRouteLineInfo = [_mapPanelViewController.mapViewController.mapLayers.routeMapLayer getPreviewRouteLineInfo];
    _oldDayNightMode = [_settings.appearanceMode get:_appMode];
}

- (void)updateAllValues
{
    _previewRouteLineInfo = [self createPreviewRouteLineInfo];

    NSMutableArray<OARouteAppearanceType *> *types = [NSMutableArray array];
    for (OAColoringType *coloringType in [OAColoringType getRouteColoringTypes])
    {
        if ([coloringType isRouteInfoAttribute])
            continue;

        NSString *topDescription = [coloringType isGradient] ? OALocalizedString(@"route_line_color_elevation_description") : @"";
        NSString *bottomDescription = [coloringType isGradient] ? OALocalizedString(@"grey_color_undefined") : @"";
        OARouteAppearanceType *type = [[OARouteAppearanceType alloc] initWithColoringType:coloringType
                                                                                    title:coloringType.title
                                                                                 attrName:nil
                                                                           topDescription:topDescription
                                                                        bottomDescription:bottomDescription
                                                                                 isActive:YES];

        if (_previewRouteLineInfo.coloringType == coloringType)
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
        OARouteAppearanceType *type = [[OARouteAppearanceType alloc] initWithColoringType:OAColoringType.ATTRIBUTE
                                                                                    title:title
                                                                                 attrName:attribute
                                                                           topDescription:topDescription
                                                                        bottomDescription:bottomDescription
                                                                                 isActive:YES];
        [types addObject:type];

        if ([_previewRouteLineInfo.coloringType isRouteInfoAttribute]
                && [_previewRouteLineInfo.routeInfoAttribute isEqualToString:attribute])
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

    _selectedWidthMode = [self findAppropriateMode:_previewRouteLineInfo.width];
}

- (OARouteWidthMode *)findAppropriateMode:(NSString *)widthKey
{
    if (widthKey)
    {
        for (OARouteWidthMode *mode in [OARouteWidthMode getRouteWidthModes])
        {
            if (mode.widthKey && [mode.widthKey isEqualToString:widthKey])
                return mode;
        }
        return OARouteWidthMode.CUSTOM;
    }
    return OARouteWidthMode.DEFAULT;
}

- (BOOL)isDefaultWidthMode
{
    return _selectedWidthMode == OARouteWidthMode.DEFAULT;
}

- (BOOL)isCustomWidthMode
{
    return _selectedWidthMode == OARouteWidthMode.CUSTOM;
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
    [_mapPanelViewController.hudViewController updateMapRulerDataWithDelay];
    [self refreshPreviewLayer];
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

        NSMutableArray *indexPaths = [NSMutableArray array];
        for (NSInteger i = 0; i < _tableData.subjects.count; i++)
        {
            OAGPXTableSectionData *sectionData = _tableData.subjects[i];
            for (NSInteger j = 0; j < sectionData.subjects.count; j++)
            {
                OAGPXTableCellData *cellData = sectionData.subjects[j];
                if ([cellData.key hasSuffix:@"_map_style"])
                    [indexPaths addObject:[NSIndexPath indexPathForRow:j inSection:i]];
            }
        }
        if (indexPaths.count > 0)
            [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self refreshPreviewLayer];
    }];
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
    [self updateHeaderTitle:0];
}

- (void)updateHeaderTitle:(NSInteger)sectionIndex
{
    NSString *headerTitle = @"";
    if (sectionIndex == 0)
        headerTitle = OALocalizedString(@"fav_color");

    OAGPXTableSectionData *sectionData = _tableData.subjects[sectionIndex];
    if (sectionData.header)
        headerTitle = sectionData.header;

    [self.titleView setText:headerTitle.upperCase];
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
        _tableData = [OAGPXTableData new];

        // color section
        OAGPXTableSectionData *colorsSectionData = [OAGPXTableSectionData withData:@{
                kTableKey: @"section_color",
                kSectionFooterHeight: @36.,
                kTableValues: @{ @"color_map_style": @(_previewRouteLineInfo.coloringType == OAColoringType.DEFAULT) }
        }];
        [colorsSectionData setData:@{
                kSectionFooter: [colorsSectionData.values[@"color_map_style"] boolValue]
                        ? [NSString stringWithFormat:OALocalizedString(@"route_line_use_map_style_color"),
                                                     [_settings.renderer get]]
                        : @""
        }];
        [_tableData.subjects addObject:colorsSectionData];

        OAGPXTableCellData *colorMapStyleCellData = [OAGPXTableCellData withData:@{
                kTableKey:@"cell_color_map_style",
                kCellType:[OAIconTextDividerSwitchCell getCellIdentifier],
                kCellTitle:OALocalizedString(@"map_settings_style")
        }];
        [colorsSectionData.subjects addObject:colorMapStyleCellData];

        // custom coloring settings
        _sectionColors = [_tableData.subjects indexOfObject:colorsSectionData];

        [self setColorCells];

        // width section
        OARouteLayer *routeLayer = _mapPanelViewController.mapViewController.mapLayers.routeMapLayer;
        OAGPXTableSectionData *widthSectionData = [OAGPXTableSectionData withData:@{
                kTableKey: @"section_width",
                kSectionHeader: OALocalizedString(@"shared_string_width"),
                kSectionFooter: [self isDefaultWidthMode]
                        ? [NSString stringWithFormat:OALocalizedString(@"route_line_use_map_style_width"),
                                                     [_settings.renderer get]]
                        : @"",
                kSectionFooterHeight: @36.,
                kTableValues: @{ @"custom_width_value": @([routeLayer getCustomRouteWidthMin]) }
        }];
        [_tableData.subjects addObject:widthSectionData];

        OAGPXTableCellData *widthMapStyleCellData = [OAGPXTableCellData withData:@{
                kTableKey:@"width_map_style",
                kCellType:[OAIconTextDividerSwitchCell getCellIdentifier],
                kCellTitle:OALocalizedString(@"map_settings_style")
        }];
        [widthSectionData.subjects addObject:widthMapStyleCellData];

        // custom width settings
        if (_previewRouteLineInfo.width && [NSCharacterSet.decimalDigitCharacterSet
                isSupersetOfSet:[NSCharacterSet characterSetWithCharactersInString:_previewRouteLineInfo.width]])
            widthSectionData.values[@"custom_width_value"] = @(_previewRouteLineInfo.width.integerValue);

        [self setWidthCells];

        // turn arrows section
        OAGPXTableSectionData *turnArrowsSectionData = [OAGPXTableSectionData withData:@{
                kTableKey: @"section_turn_arrows",
                kSectionFooter: OALocalizedString(@"turn_arrows_descr"),
                kSectionFooterHeight: @36.
        }];
        [_tableData.subjects addObject:turnArrowsSectionData];

        OAGPXTableCellData *turnArrowsCellData = [OAGPXTableCellData withData:@{
                kTableKey:@"turn_arrows",
                kCellType:[OAIconTextDividerSwitchCell getCellIdentifier],
                kCellTitle:OALocalizedString(@"turn_arrows")
        }];
        [turnArrowsSectionData.subjects addObject:turnArrowsCellData];

        // actions section
        OAGPXTableSectionData *resetSectionData = [OAGPXTableSectionData withData:@{
                kTableKey: @"section_reset",
                kSectionHeader:OALocalizedString(@"actions"),
                kSectionFooterHeight: @60.
        }];
        [_tableData.subjects addObject:resetSectionData];

        OAGPXTableCellData *resetCellData = [OAGPXTableCellData withData:@{
                kTableKey: @"reset",
                kCellType: [OAIconTitleValueCell getCellIdentifier],
                kCellTitle: OALocalizedString(@"reset_to_original"),
                kCellRightIconName: @"ic_custom_reset"
        }];
        [resetSectionData.subjects addObject:resetCellData];
    }
}

- (OAGPXTableCellData *)getCellData:(NSIndexPath *)indexPath
{
    return _tableData.subjects[indexPath.section].subjects[indexPath.row];
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

- (void)refreshPreviewLayer
{
    OAPreviewRouteLineLayer *previewLayer = _mapPanelViewController.mapViewController.mapLayers.routePreviewLayer;
    CGFloat scale = UIScreen.mainScreen.scale;
    OsmAnd::PointI topLeft, bottomRight;
    if (OAUtilities.isLandscapeIpadAware)
    {
        CGPoint tL = self.scrollableView.frame.origin;
        tL.x = CGRectGetMaxX(self.scrollableView.frame) * scale;
        tL.y = (CGRectGetMaxY(self.applyButton.frame) + kAppearanceLineMargin) * scale;
        CGPoint bR = self.view.frame.origin;
        bR.x = CGRectGetMaxX(self.view.frame) * scale;
        bR.y = (CGRectGetMaxY(self.view.frame) - OAUtilities.getBottomMargin - kAppearanceLineMargin) * scale;
        [_mapPanelViewController.mapViewController.mapView convert:tL toLocation:&topLeft];
        [_mapPanelViewController.mapViewController.mapView convert:bR toLocation:&bottomRight];
    }
    else
    {
        CGPoint tL = self.statusBarBackgroundView.frame.origin;
        tL.y = (CGRectGetMaxY(self.statusBarBackgroundView.frame) + kAppearanceLineMargin) * scale;
        tL.x = tL.x * scale;
        CGPoint bR = self.scrollableView.frame.origin;
        bR.x = CGRectGetMaxX(self.scrollableView.frame) * scale;
        bR.y = (bR.y - kAppearanceLineMargin) * scale;
        [_mapPanelViewController.mapViewController.mapView convert:tL toLocation:&topLeft];
        [_mapPanelViewController.mapViewController.mapView convert:bR toLocation:&bottomRight];
    }
    
    OsmAnd::AreaI area(topLeft, bottomRight);
    [previewLayer refreshRoute:area];
}

- (void)updateRouteLayer:(OAPreviewRouteLineInfo *)previewInfo
{
    OAPreviewRouteLineLayer *previewLayer = _mapPanelViewController.mapViewController.mapLayers.routePreviewLayer;
    OARouteLayer *routeLayer = _mapPanelViewController.mapViewController.mapLayers.routeMapLayer;
    [routeLayer setPreviewRouteLineInfo:previewInfo];
    [previewLayer setPreviewRouteLineInfo:previewInfo];
    [_mapPanelViewController.mapViewController runWithRenderSync:^{
        [routeLayer resetLayer];
        [previewLayer resetLayer];
        
        [routeLayer refreshRoute];
        [self refreshPreviewLayer];
    }];
}

- (OAGPXTableCellData *)generateColorTypesEmptySpaceCellData
{
    return [OAGPXTableCellData withData:@{
            kTableKey: @"color_types_empty_space",
            kCellType: [OADividerCell getCellIdentifier],
            kTableValues: @{ @"float_value": @10. }
    }];
}

- (OAGPXTableCellData *)generateColorTypesCellData
{
    NSMutableArray<NSDictionary *> *lineColoringTypes = [NSMutableArray array];
    for (OARouteAppearanceType *type in _coloringTypes)
    {
        [lineColoringTypes addObject:@{
                @"title": type.title,
                @"available": @(type.isActive)
        }];
    }

    return [OAGPXTableCellData withData:@{
            kTableKey: @"color_types",
            kCellType: [OAFoldersCell getCellIdentifier],
            kTableValues: @{
                    @"array_value": lineColoringTypes,
                    @"selected_integer_value": @([_coloringTypes indexOfObject:_selectedType])
            }
    }];
}

- (OAGPXTableCellData *)generateColorDayNightEmptySpaceCellData
{
    return [OAGPXTableCellData withData:@{
            kTableKey: @"color_day_night_empty_space",
            kCellType: [OADividerCell getCellIdentifier],
            kTableValues: @{ @"float_value": @8. }
    }];
}

- (OAGPXTableCellData *)generateColorDayNightCellData
{
    return [OAGPXTableCellData withData:@{
            kTableKey: @"color_day_night_value",
            kCellType: [OASegmentedControlCell getCellIdentifier],
            kTableValues: @{ @"array_value": @[kColorDayMode, kColorNightMode] },
            kCellToggle: @NO
    }];
}

- (OAGPXTableCellData *)generateColorGridCellData
{
    return [OAGPXTableCellData withData:@{
            kTableKey: @"color_grid",
            kCellType: [OAColorsTableViewCell getCellIdentifier],
            kTableValues: @{
                    @"array_value": _availableColors,
                    @"int_value": @([_previewRouteLineInfo getCustomColor:_nightMode])
            }
    }];
}

- (OAGPXTableCellData *)generateTopDescriptionCellData
{
    return [OAGPXTableCellData withData:@{
            kTableKey: @"top_description",
            kCellType: [OATextLineViewCell getCellIdentifier],
            kCellTitle: _selectedType.topDescription
    }];
}

- (OAGPXTableCellData *)generateColorGradientCellData
{
    return [OAGPXTableCellData withData:@{
            kTableKey: @"color_elevation_gradient",
            kCellType: [OAImageTextViewCell getCellIdentifier],
            kCellDesc: OALocalizedString([self isSelectedTypeAltitude] ? @"shared_string_min_height" : @""),
            kCellRightIconName: [self isSelectedTypeSlope] ? @"img_track_gradient_slope" : @"img_track_gradient_speed",
            kTableValues: @{
                    @"extra_desc": OALocalizedString([self isSelectedTypeAltitude] ? @"shared_string_max_height" : @""),
                    @"desc_font_size": @([self isSelectedTypeSlope] ? 15 : 17)
            }
    }];
}

- (OAGPXTableCellData *)generateBottomDescriptionCellData
{
    return [OAGPXTableCellData withData:@{
            kTableKey: @"bottom_description",
            kCellType: [OATextLineViewCell getCellIdentifier],
            kCellTitle: _selectedType.bottomDescription
    }];
}

- (OAGPXTableCellData *)generateWidthTypesEmptySpaceCellData
{
    return [OAGPXTableCellData withData:@{
            kTableKey: @"width_types_empty_space",
            kCellType: [OADividerCell getCellIdentifier],
            kTableValues: @{ @"float_value": @12. }
    }];
}

- (OAGPXTableCellData *)generateWidthValueCellData
{
    return [OAGPXTableCellData withData:@{
            kTableKey: @"width_value",
            kCellType: [OASegmentedControlCell getCellIdentifier],
            kTableValues: @{ @"array_value": [OARouteWidthMode getRouteWidthModes] },
            kCellToggle: @YES
    }];
}

- (OAGPXTableCellData *)generateWidthSliderEmptySpaceCellData
{
    return [OAGPXTableCellData withData:@{
            kTableKey: @"width_slider_empty_space",
            kCellType: [OADividerCell getCellIdentifier],
            kTableValues: @{ @"float_value": [self isCustomWidthMode] ? @6. : @19. }
    }];
}

- (OAGPXTableCellData *)generateWidthCustomSliderCellData
{
    OARouteLayer *routeLayer = _mapPanelViewController.mapViewController.mapLayers.routeMapLayer;
    NSMutableArray<NSString *> *customWidthValues = [NSMutableArray array];
    for (NSInteger i = [routeLayer getCustomRouteWidthMin]; i <= [routeLayer getCustomRouteWidthMax]; i++)
    {
        [customWidthValues addObject:[NSString stringWithFormat:@"%li", i]];
    }

    OAGPXTableSectionData *sectionData = [_tableData getSubject:@"section_width"];
    return [OAGPXTableCellData withData:@{
            kTableKey: @"width_custom_slider",
            kCellType: [OASegmentSliderTableViewCell getCellIdentifier],
            kTableValues: @{
                    @"custom_string_value": [NSString stringWithFormat:@"%li",
                            sectionData ? [sectionData.values[@"custom_width_value"] integerValue] : [routeLayer getCustomRouteWidthMin]],
                    @"array_value": customWidthValues
            }
    }];
}

- (void)removeCellFromSection:(OAGPXTableSectionData *)sectionData cellKey:(NSString *)cellKey
{
    if (!sectionData)
        return;

    OAGPXTableCellData *cellData = [sectionData getSubject:cellKey];
    if (cellData)
        [sectionData.subjects removeObject:cellData];
}

- (void)clearColorSection:(BOOL)withTypes
{
    OAGPXTableSectionData *sectionData = [_tableData getSubject:@"section_color"];
    if (sectionData)
    {
        if (withTypes)
        {
            [self removeCellFromSection:sectionData cellKey:@"color_types_empty_space"];
            [self removeCellFromSection:sectionData cellKey:@"color_types"];
        }

        [self removeCellFromSection:sectionData cellKey:@"color_day_night_empty_space"];
        [self removeCellFromSection:sectionData cellKey:@"color_day_night_value"];
        [self removeCellFromSection:sectionData cellKey:@"color_grid"];
        [self removeCellFromSection:sectionData cellKey:@"top_description"];
        [self removeCellFromSection:sectionData cellKey:@"color_elevation_gradient"];
        [self removeCellFromSection:sectionData cellKey:@"bottom_description"];
    }
}

- (void)clearWidthSection:(BOOL)withTypes
{
    OAGPXTableSectionData *sectionData = [_tableData getSubject:@"section_width"];
    if (sectionData)
    {
        if (withTypes)
        {
            [self removeCellFromSection:sectionData cellKey:@"width_types_empty_space"];
            [self removeCellFromSection:sectionData cellKey:@"width_value"];
            [self removeCellFromSection:sectionData cellKey:@"width_slider_empty_space"];
        }

        [self removeCellFromSection:sectionData cellKey:@"width_custom_slider"];
    }
}

- (void)setColorCells
{
    OAGPXTableSectionData *sectionData = [_tableData getSubject:@"section_color"];
    if (sectionData)
    {
        if (![sectionData.values[@"color_map_style"] boolValue])
        {
            [self clearColorSection:NO];

            OAGPXTableCellData *colorTypesCellData = [sectionData getSubject:@"color_types"];
            if (!colorTypesCellData)
            {
                [sectionData.subjects addObject:[self generateColorTypesEmptySpaceCellData]];
                [sectionData.subjects addObject:[self generateColorTypesCellData]];
            }

            if ([_selectedType.coloringType isCustomColor])
            {
                [sectionData.subjects addObject:[self generateColorDayNightEmptySpaceCellData]];
                [sectionData.subjects addObject:[self generateColorDayNightCellData]];
                [sectionData.subjects addObject:[self generateColorGridCellData]];
            }
            else if ([_selectedType.coloringType isGradient])
            {
                [sectionData.subjects addObject:[self generateTopDescriptionCellData]];
                [sectionData.subjects addObject:[self generateColorGradientCellData]];
                [sectionData.subjects addObject:[self generateBottomDescriptionCellData]];
            }
            else if ([_selectedType.coloringType isRouteInfoAttribute])
            {
                [sectionData.subjects addObject:[self generateTopDescriptionCellData]];
                [sectionData.subjects addObject:[self generateBottomDescriptionCellData]];
            }
        }
        else
        {
            [self clearColorSection:YES];
        }
        OAGPXTableCellData *colorGridCellData = [sectionData getSubject:@"color_grid"];
        if (colorGridCellData)
            _cellColorGrid = [sectionData.subjects indexOfObject:colorGridCellData];
    }
}

- (void)setWidthCells
{
    OAGPXTableSectionData *sectionData = [_tableData getSubject:@"section_width"];
    if (sectionData)
    {
        if (![self isDefaultWidthMode])
        {
            [self clearWidthSection:NO];

            OAGPXTableCellData *widthValueCellData = [sectionData getSubject:@"width_value"];
            if (!widthValueCellData)
            {
                [sectionData.subjects addObject:[self generateWidthTypesEmptySpaceCellData]];
                [sectionData.subjects addObject:[self generateWidthValueCellData]];
                [sectionData.subjects addObject:[self generateWidthSliderEmptySpaceCellData]];
            }

            OAGPXTableCellData *widthCustomSliderCellData = [sectionData getSubject:@"width_custom_slider"];
            if ([self isCustomWidthMode] && !widthCustomSliderCellData)
                [sectionData.subjects addObject:[self generateWidthCustomSliderCellData]];
        }
        else
        {
            [self clearWidthSection:YES];
        }
    }
}

- (void)onSwitch:(BOOL)toggle tableData:(OAGPXBaseTableData *)tableData
{
    if (!tableData)
        return;

    if ([tableData.key isEqualToString:@"cell_color_map_style"])
    {
        OAGPXTableSectionData *colorsSectionData = [_tableData getSubject:@"section_color"];
        if (colorsSectionData)
        {
            colorsSectionData.values[@"color_map_style"] = @(toggle);
            if (toggle)
                _selectedType = [self getRouteAppearanceType:OAColoringType.DEFAULT];
            else if (_selectedType.coloringType == OAColoringType.DEFAULT)
                _selectedType = [self getRouteAppearanceType:OAColoringType.CUSTOM_COLOR];
            else
                _selectedType = [self getRouteAppearanceType:_previewRouteLineInfo.coloringType];

            _previewRouteLineInfo.coloringType = _selectedType.coloringType;
            [self updateRouteLayer:_previewRouteLineInfo];
        }
    }
    else if ([tableData.key isEqualToString:@"width_map_style"])
    {
        _selectedWidthMode = toggle ? OARouteWidthMode.DEFAULT : [OARouteWidthMode getRouteWidthModes].firstObject;
        _previewRouteLineInfo.width = _selectedWidthMode.widthKey;
        [self updateRouteLayer:_previewRouteLineInfo];
    }
    else if ([tableData.key isEqualToString:@"turn_arrows"])
    {
        _previewRouteLineInfo.showTurnArrows = toggle;
        [self updateRouteLayer:_previewRouteLineInfo];
    }
}

- (BOOL)isOn:(OAGPXBaseTableData *)tableData
{
    if (!tableData)
        return NO;

    if ([tableData.key isEqualToString:@"cell_color_map_style"])
    {
        OAGPXTableSectionData *sectionData = [_tableData getSubject:@"section_color"];
        if (sectionData)
            return [sectionData.values[@"color_map_style"] boolValue];
    }
    else if ([tableData.key isEqualToString:@"width_map_style"])
    {
        return [self isDefaultWidthMode];
    }
    else if ([tableData.key isEqualToString:@"turn_arrows"])
    {
        return _previewRouteLineInfo.showTurnArrows;
    }

    return NO;
}

- (void)updateData:(OAGPXBaseTableData *)tableData
{
    if (!tableData)
        return;

    if ([tableData.key isEqualToString:@"cell_color_map_style"] && [_selectedType.coloringType isCustomColor])
    {
        UIColor *customColorDay = UIColorFromRGB([_previewRouteLineInfo getCustomColor:NO]);
        UIColor *customColorNight = UIColorFromRGB([_previewRouteLineInfo getCustomColor:YES]);
        UIColor *defaultColorDay = UIColorFromRGB(kDefaultRouteLineDayColor);
        UIColor *defaultColorNight = UIColorFromRGB(kDefaultRouteLineNightColor);
        if ([customColorDay isEqual:defaultColorDay] || [customColorNight isEqual:defaultColorNight])
            [_previewRouteLineInfo setCustomColor:_availableColors.firstObject.intValue nightMode:_nightMode];
    }
    else if ([tableData.key isEqualToString:@"color_types"])
    {
        tableData.values[@"selected_integer_value"] = @([_coloringTypes indexOfObject:_selectedType]);
    }
    else if ([tableData.key isEqualToString:@"color_day_night_value"])
    {
        [[OADayNightHelper instance] forceUpdate];
    }
    else if ([tableData.key isEqualToString:@"color_grid"])
    {
        tableData.values[@"array_value"] = _availableColors;
        tableData.values[@"int_value"] = @([_previewRouteLineInfo getCustomColor:_nightMode]);
    }
    else if ([tableData.key isEqualToString:@"top_description"])
    {
        [tableData setData:@{ kCellTitle: _selectedType.topDescription }];
    }
    else if ([tableData.key isEqualToString:@"bottom_description"])
    {
        [tableData setData:@{ kCellTitle: _selectedType.bottomDescription }];
    }
    else if ([tableData.key isEqualToString:@"color_elevation_gradient"])
    {
        tableData.values[@"extra_desc"] = OALocalizedString([self isSelectedTypeAltitude] ? @"shared_string_max_height" : @"");
        tableData.values[@"desc_font_size"] = @([self isSelectedTypeSlope] ? 15 : 17);
        [tableData setData:@{
                kCellDesc: OALocalizedString([self isSelectedTypeAltitude] ? @"shared_string_min_height" : @""),
                kCellRightIconName: [self isSelectedTypeSlope] ? @"img_track_gradient_slope" : @"img_track_gradient_speed"
        }];
    }
    else if ([tableData.key isEqualToString:@"width_slider_empty_space"])
    {
        tableData.values[@"float_value"] = @([self isCustomWidthMode] ? 6. : 19.);
    }
    else if ([tableData.key isEqualToString:@"width_custom_slider"])
    {
        OAGPXTableSectionData *sectionData = [_tableData getSubject:@"section_width"];
        if (sectionData)
        {
            _previewRouteLineInfo.width = [NSString stringWithFormat:@"%li", [sectionData.values[@"custom_width_value"] integerValue]];
            [self updateRouteLayer:_previewRouteLineInfo];
            tableData.values[@"custom_string_value"] = [NSString stringWithFormat:@"%li", [sectionData.values[@"custom_width_value"] integerValue]];
        }
    }
    else if ([tableData.key isEqualToString:@"width_value"])
    {
        OAGPXTableSectionData *sectionData = [_tableData getSubject:@"section_width"];
        if (sectionData)
        {
            _previewRouteLineInfo.width = [self isCustomWidthMode]
                    ? [NSString stringWithFormat:@"%li", [sectionData.values[@"custom_width_value"] integerValue]]
                    : _selectedWidthMode.widthKey;
            [self updateRouteLayer:_previewRouteLineInfo];
        }
    }
    else if ([tableData.key isEqualToString:@"section_color"])
    {
        OAGPXTableSectionData *sectionData = (OAGPXTableSectionData *) tableData;

        [self setColorCells];

        for (OAGPXTableCellData *cellData in sectionData.subjects)
        {
            [self updateData:cellData];
        }

        [sectionData setData:@{
                kSectionFooter: [sectionData.values[@"color_map_style"] boolValue]
                        ? [NSString stringWithFormat:OALocalizedString(@"route_line_use_map_style_color"),
                                                     [_settings.renderer get]]
                        : @""
        }];
    }
    else if ([tableData.key isEqualToString:@"section_width"])
    {
        OAGPXTableSectionData *sectionData = (OAGPXTableSectionData *) tableData;

        [self setWidthCells];

        for (OAGPXTableCellData *cellData in sectionData.subjects)
        {
            [self updateData:cellData];
        }

        [sectionData setData:@{
                kSectionFooter: [self isDefaultWidthMode]
                        ? [NSString stringWithFormat:OALocalizedString(@"route_line_use_map_style_width"),
                                                     [_settings.renderer get]]
                        : @""
        }];
    }
}

- (void)updateProperty:(id)value tableData:(OAGPXBaseTableData *)tableData
{
    if (!tableData)
        return;

    if ([tableData.key isEqualToString:@"color_day_night_value"])
    {
        if ([value isKindOfClass:NSNumber.class])
        {
            NSInteger index = [value integerValue];
            NSArray<NSString *> *dayNightValues = tableData.values[@"array_value"];
            _nightMode = [dayNightValues[index] isEqualToString:kColorNightMode];
            _selectedDayNightMode = _nightMode ? dayNightValues[1] : dayNightValues[0];
            [_settings.appearanceMode set:index mode:_appMode];
        }
    }
    else if ([tableData.key isEqualToString:@"width_custom_slider"])
    {
        if ([value isKindOfClass:NSNumber.class])
        {
            OAGPXTableSectionData *sectionData = [_tableData getSubject:@"section_width"];
            if (sectionData)
                sectionData.values[@"custom_width_value"] = value;
        }
    }
    else if ([tableData.key isEqualToString:@"width_value"])
    {
        if ([value isKindOfClass:NSNumber.class])
        {
            NSInteger modeIndex = ((NSNumber *) value).integerValue;
            _selectedWidthMode = [OARouteWidthMode getRouteWidthModes][modeIndex];
        }
    }
}

- (void)onButtonPressed:(OAGPXBaseTableData *)tableData
{
    if (!tableData)
        return;

    if ([tableData.key isEqualToString:@"reset"])
    {
        [self updateAllValues];
        [self updateRouteLayer:_oldPreviewRouteLineInfo];
        [self generateData];
        [UIView transitionWithView:self.tableView
                          duration:0.35f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^(void) {
                            [self.tableView reloadData];
                        }
                        completion:nil];
    }
}

- (IBAction)onBackButtonPressed:(id)sender
{
    [self hide:YES duration:.2 onComplete:^{
        [_mapSourceUpdatedObserver detach];
        [_settings.appearanceMode set:_oldDayNightMode mode:_appMode];
        [[OADayNightHelper instance] forceUpdate];

        [self updateRouteLayer:_oldPreviewRouteLineInfo];
        [_mapPanelViewController.mapViewController.mapLayers.routePreviewLayer resetLayer];

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
        
        [_mapSourceUpdatedObserver detach];
        [_settings.appearanceMode set:_oldDayNightMode mode:_appMode];
        [[OADayNightHelper instance] forceUpdate];

        [self updateRouteLayer:_previewRouteLineInfo];
        [_mapPanelViewController.mapViewController.mapLayers.routePreviewLayer resetLayer];

        if (self.delegate)
            [self.delegate onCloseAppearance];
    }];
}

#pragma mark - OADraggableViewActions

- (void)onViewStateChanged:(CGFloat)height
{
}

- (void)onViewHeightChanged:(CGFloat)height
{
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _tableData.subjects.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _tableData.subjects[section].subjects.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return _tableData.subjects[section].header;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAGPXTableCellData *cellData = [self getCellData:indexPath];
    UITableViewCell *outCell = nil;
    if ([cellData.type isEqualToString:[OADividerCell getCellIdentifier]])
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
            cell.dividerView.hidden = YES;
            [cell showIcon:NO];
        }
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + 20., 0., 0.);

            cell.switchView.on = [self isOn:cellData];
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
            cell.valueLabel.tintColor = UIColorFromRGB(color_text_footer);
        }
        if (cell)
        {
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
            _colorValuesCell.collectionView.contentInset = UIEdgeInsetsMake(0., 8. , 0., 20.);
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
            cell.descView.textColor = UIColorFromRGB(color_text_footer);
            cell.extraDescView.textColor = UIColorFromRGB(color_text_footer);
        }
        if (cell)
        {
            UIImage *image = [UIImage imageNamed:cellData.rightIconName];
            cell.iconView.image = [cell isDirectionRTL] ? image.imageFlippedForRightToLeftLayoutDirection : image;

            NSString *desc = cellData.desc;
            [cell showDesc:desc && desc.length > 0];
            cell.descView.text = desc;
            cell.descView.font = [UIFont systemFontOfSize:[cellData.values[@"desc_font_size"] intValue]];

            NSString *extraDesc = cellData.values[@"extra_desc"];
            [cell showExtraDesc:extraDesc && extraDesc.length > 0];
            cell.extraDescView.text = extraDesc;
            cell.extraDescView.font = [UIFont systemFontOfSize:[cellData.values[@"desc_font_size"] intValue]];
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
            cell.textView.textColor = UIColorFromRGB(color_text_footer);
        }
        if (cell)
        {
            [cell makeSmallMargins:indexPath.row != [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1];
            cell.textView.text = cellData.title;
            cell.textView.font = [UIFont systemFontOfSize:15];
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
            [cell.segmentedControl setTitleTextAttributes:@{
                    NSForegroundColorAttributeName : UIColorFromRGB(color_primary_purple),
                    NSFontAttributeName : [UIFont boldSystemFontOfSize:15.0f]}
                                                 forState:UIControlStateNormal];

            if (@available(iOS 13.0, *))
                cell.segmentedControl.selectedSegmentTintColor = UIColorFromRGB(color_primary_purple);
            else
                cell.segmentedControl.tintColor = UIColorFromRGB(color_primary_purple);
        }
        if (cell)
        {
            for (NSInteger i = 0; i < arrayValue.count; i++)
            {
                id value = arrayValue[i];
                if ([value isKindOfClass:OARouteWidthMode.class])
                    value = ((OARouteWidthMode *) value).icon;
                if ([value isKindOfClass:NSString.class])
                {
                    if (cellData.toggle)
                    {
                        UIImage *icon = [UIImage templateImageNamed:value];
                        if (i == cell.segmentedControl.numberOfSegments)
                            [cell.segmentedControl insertSegmentWithImage:icon atIndex:i animated:NO];
                        else
                            [cell.segmentedControl setImage:icon forSegmentAtIndex:i];
                    }
                    else
                    {
                        if (i == cell.segmentedControl.numberOfSegments)
                            [cell.segmentedControl insertSegmentWithTitle:value atIndex:i animated:NO];
                        else
                            [cell.segmentedControl setTitle:value forSegmentAtIndex:i];
                    }
                }
            }
            NSInteger selectedIndex = 0;
            if ([cellData.key isEqualToString:@"color_day_night_value"])
                selectedIndex = [arrayValue indexOfObject:_selectedDayNightMode];
            else if ([cellData.key isEqualToString:@"width_value"])
                selectedIndex = [[OARouteWidthMode getRouteWidthModes] indexOfObject:_selectedWidthMode];
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
    else if ([cellData.type isEqualToString:[OASegmentSliderTableViewCell getCellIdentifier]])
    {
        OASegmentSliderTableViewCell *cell =
                [tableView dequeueReusableCellWithIdentifier:[OASegmentSliderTableViewCell getCellIdentifier]];
        NSArray *arrayValue = cellData.values[@"array_value"];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASegmentSliderTableViewCell getCellIdentifier]
                                                         owner:self options:nil];
            cell = (OASegmentSliderTableViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.topRightLabel.textColor = UIColorFromRGB(color_primary_purple);
            cell.topRightLabel.font = [UIFont systemFontOfSize:17. weight:UIFontWeightMedium];
        }
        if (cell)
        {
            [cell showLabels:NO topRight:NO bottomLeft:YES bottomRight:YES];
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
    else if ([cellData.type isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAIconTitleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTitleValueCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier]
                                                         owner:self options:nil];
            cell = (OAIconTitleValueCell *) nib[0];
            [cell showLeftIcon:NO];
            [cell showRightIcon:YES];
            cell.separatorInset = UIEdgeInsetsMake(0., self.tableView.frame.size.width, 0., 0.);
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            cell.textView.textColor = UIColorFromRGB(color_primary_purple);
            cell.rightIconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.descriptionView.text = @"";
        }
        if (cell)
        {
            cell.textView.text = cellData.title;
            cell.rightIconView.image = [UIImage templateImageNamed:cellData.rightIconName];
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
    OAGPXTableSectionData *sectionData = _tableData.subjects[section];
    return section == 0 || !sectionData.header || sectionData.header.length == 0
            ? 0.001
            : [OAUtilities calculateTextBounds:sectionData.header
                                         width:self.scrollableView.frame.size.width - 40. - [OAUtilities getLeftMargin]
                                          font:[UIFont systemFontOfSize:13]].height;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    OAGPXTableSectionData *sectionData = _tableData.subjects[section];
    CGFloat footerHeight = sectionData.footerHeight > 0 ? sectionData.footerHeight : 0.;

    NSString *footer = sectionData.footer;
    if (!footer || footer.length == 0)
        return footerHeight > 0 ? footerHeight : 0.001;

    return [OATableViewCustomFooterView getHeight:footer width:self.tableView.bounds.size.width] + footerHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    NSString *footer = _tableData.subjects[section].footer;
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
    [self onButtonPressed:cellData];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Selectors

- (void)onSwitchPressed:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    if (switchView)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:switchView.tag & 0x3FF inSection:switchView.tag >> 10];

        OAGPXTableCellData *cellData = [self getCellData:indexPath];
        [self onSwitch:switchView.isOn tableData:cellData];

        OAGPXTableSectionData *sectionData = _tableData.subjects[indexPath.section];
        [self updateData:sectionData];

        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]
                      withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)segmentChanged:(id)sender
{
    UISegmentedControl *segment = (UISegmentedControl *) sender;
    if (segment)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:segment.tag & 0x3FF inSection:segment.tag >> 10];

        OAGPXTableCellData *cellData = [self getCellData:indexPath];
        [self updateProperty:@(segment.selectedSegmentIndex) tableData:cellData];

        OAGPXTableSectionData *sectionData = _tableData.subjects[indexPath.section];
        [self updateData:sectionData];

        [UIView setAnimationsEnabled:NO];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]
                      withRowAnimation:UITableViewRowAnimationNone];
        [UIView setAnimationsEnabled:YES];
    }
}

- (void)sliderChanged:(id)sender
{
    UISlider *slider = (UISlider *) sender;
    if (sender)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:slider.tag & 0x3FF inSection:slider.tag >> 10];

        OASegmentSliderTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        OAGPXTableCellData *cellData = [self getCellData:indexPath];
        [self updateProperty:@(cell.selectedMark + 1) tableData:cellData];
        [self updateData:cellData];

        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGPoint p = scrollView.contentOffset;
    p.y += self.topHeaderContainerView.frame.origin.y + self.topHeaderContainerView.frame.size.height;
    NSIndexPath *ip = [self.tableView indexPathForRowAtPoint:p];
    if (ip)
        [self updateHeaderTitle:ip.section];

    if ([self shouldScrollInAllModes])
        return;

    if (scrollView.contentOffset.y <= 0 || self.contentContainer.frame.origin.y != [self getStatusBarHeight])
        [scrollView setContentOffset:CGPointZero animated:NO];

    BOOL shouldShow = self.tableView.contentOffset.y > 0;
    self.topHeaderContainerView.layer.shadowOpacity = shouldShow ? 0.15 : 0.0;
}

#pragma mark - OAFoldersCellDelegate

- (void)onItemSelected:(NSInteger)index
{
    _selectedType = _coloringTypes[index];
    _previewRouteLineInfo.coloringType = _selectedType.coloringType;
    _previewRouteLineInfo.routeInfoAttribute = [_selectedType.coloringType isRouteInfoAttribute]
            ? _selectedType.attrName
            : nil;
    [self updateRouteLayer:_previewRouteLineInfo];

    OAGPXTableSectionData *sectionData = _tableData.subjects[_sectionColors];
    [self updateData:sectionData];

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

    if (_tableData.subjects.count >= 1)
    {
        OAGPXTableSectionData *sectionData = _tableData.subjects[_sectionColors];
        if (sectionData.subjects.count - 1 >= _cellColorGrid)
        {
            OAGPXTableCellData *cellData = sectionData.subjects[_cellColorGrid];
            [self updateData:cellData];

            [UIView setAnimationsEnabled:NO];
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_cellColorGrid
                                                                        inSection:_sectionColors]]
                                  withRowAnimation:UITableViewRowAnimationNone];
            [UIView setAnimationsEnabled:YES];
        }
    }
}

- (void) onMapSourceUpdated
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateRouteLayer:_previewRouteLineInfo];
    });
}

@end
