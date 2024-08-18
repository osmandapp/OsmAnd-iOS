//
//  OARouteLineAppearanceHudViewController.mm
//  OsmAnd
//
//  Created by Skalii on 20.12.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OARouteLineAppearanceHudViewController.h"
#import "OABaseTrackMenuHudViewController.h"
#import "OAPluginPopupViewController.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapHudViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMainSettingsViewController.h"
#import "OAConfigureProfileViewController.h"
#import "OAProfileNavigationSettingsViewController.h"
#import "OAColorCollectionViewController.h"
#import "OAPreviewRouteLineLayer.h"
#import "OATableViewCustomFooterView.h"
#import "OAFoldersCollectionView.h"
#import "OAMapRendererView.h"
#import "OASlider.h"
#import "OADividerCell.h"
#import "OASwitchTableViewCell.h"
#import "OAColorsTableViewCell.h"
#import "OAFoldersCell.h"
#import "OASegmentedControlCell.h"
#import "OASegmentSliderTableViewCell.h"
#import "OATextLineViewCell.h"
#import "OARightIconTableViewCell.h"
#import "OACollectionSingleLineTableViewCell.h"
#import "OALineChartCell.h"
#import "OAAutoObserverProxy.h"
#import "OAColors.h"
#import "Localization.h"
#import "OARoutingHelper.h"
#import "OADayNightHelper.h"
#import "OAMapLayers.h"
#import "OAPreviewRouteLineInfo.h"
#import "OADefaultFavorite.h"
#import "OARouteStatisticsHelper.h"
#import "OAProducts.h"
#import "OAConcurrentCollections.h"
#import "OASizes.h"
#import "OAColoringType.h"
#import "OAApplicationMode.h"
#import "GeneratedAssetSymbols.h"
#import "OsmAnd_Maps-Swift.h"
#import <Charts/Charts-Swift.h>

#define kColorDayMode OALocalizedString(@"day")
#define kColorNightMode OALocalizedString(@"daynight_mode_night")

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

@interface OARouteLineAppearanceHudViewController() <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, OAFoldersCellDelegate, OAColorsTableViewCellDelegate, OACollectionCellDelegate, OAColorCollectionDelegate>

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

@property (nonatomic) OAGPXTableData *tableData;
@property (nonatomic) NSInteger sectionColors;
@property (nonatomic) OAAppSettings *settings;
@property (nonatomic) OAApplicationMode *appMode;
@property (nonatomic) NSInteger oldDayNightMode;
@property (nonatomic) OAPreviewRouteLineInfo *oldPreviewRouteLineInfo;
@property (nonatomic) OAAutoObserverProxy *mapSourceUpdatedObserver;
@property (nonatomic) OAMapPanelViewController *mapPanelViewController;
@property (nonatomic) EOARouteLineAppearancePrevScreen prevScreen;
@property (nonatomic) OAPreviewRouteLineInfo *previewRouteLineInfo;
@property (nonatomic) OAConcurrentArray<PaletteColor *> *sortedPaletteColorItems;
@property (nonatomic) BOOL isDefaultColorRestored;
@property (nonatomic) GradientColorsCollection *gradientColorsCollection;
@property (nonatomic) PaletteColor *selectedPaletteColorItem;
@property (nonatomic) NSInteger cellPaletteLegendIndex;
@property (nonatomic) NSInteger cellPaletteNameIndex;
@property (nonatomic) NSInteger cellColorGridIndex;

@end

@implementation OARouteLineAppearanceHudViewController
{
    OsmAndAppInstance _app;
    OARoutingHelper *_routingHelper;
    NSObject *_dataLock;

    CGFloat _originalStatusBarHeight;
    BOOL _nightMode;
    NSString *_selectedDayNightMode;

    OAFoldersCell *_colorValuesCell;
    OACollectionViewCellState *_scrollCellsState;
    NSArray<OARouteAppearanceType *> *_coloringTypes;
    OARouteAppearanceType *_selectedType;
    NSArray<NSNumber *> *_availableColors;

    OARouteWidthMode *_selectedWidthMode;
}

@dynamic statusBarBackgroundView, contentContainer;

- (instancetype)initWithAppMode:(OAApplicationMode *)appMode prevScreen:(EOARouteLineAppearancePrevScreen)prevScreen
{
    self = [super initWithNibName:@"OARouteLineAppearanceHudViewController"
                           bundle:nil];
    if (self)
    {
        _appMode = appMode;
        _prevScreen = prevScreen;
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _app = [OsmAndApp instance];
    _dataLock = [[NSObject alloc] init];
    _sortedPaletteColorItems = [[OAConcurrentArray alloc] init];
    _mapPanelViewController = [OARootViewController instance].mapPanel;
    [_mapPanelViewController.mapViewController.mapView setAzimuth:0.0];
    [_mapPanelViewController.mapViewController.mapView cancelAllAnimations];
    
    _app.mapMode = OAMapModeFree;
    _settings = [OAAppSettings sharedManager];
    _routingHelper = [OARoutingHelper sharedInstance];

    OAColoringType *type = [_settings.routeColoringType get:_appMode];
    _gradientColorsCollection = [[GradientColorsCollection alloc] initWithColorizationType:(ColorizationType) [type toColorizationType]];
    
    _mapSourceUpdatedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                 withHandler:@selector(onMapSourceUpdated)
                                                  andObserve:[OARootViewController instance].mapPanel.mapViewController.mapSourceUpdatedObservable];

    [self updateAllValues];
    [self setOldValues];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onCollectionDeleted:)
                                                 name:ColorsCollection.collectionDeletedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onCollectionCreated:)
                                                 name:ColorsCollection.collectionCreatedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onCollectionUpdated:)
                                                 name:ColorsCollection.collectionUpdatedNotification
                                               object:nil];
}

- (void)setOldValues
{
    _oldPreviewRouteLineInfo = [_mapPanelViewController.mapViewController.mapLayers.routeMapLayer getPreviewRouteLineInfo] ?: _previewRouteLineInfo;
    _oldDayNightMode = [_settings.appearanceMode get:_appMode];
}

- (void)updateAllValues
{
    _previewRouteLineInfo = [self createPreviewRouteLineInfo];

    [_sortedPaletteColorItems replaceAllWithObjectsSync:[_gradientColorsCollection getPaletteColors]];
    _selectedPaletteColorItem = [_gradientColorsCollection getPaletteColorByName:_previewRouteLineInfo.gradientPalette];
    if (!_selectedPaletteColorItem)
        _selectedPaletteColorItem = [_gradientColorsCollection getDefaultGradientPalette];

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
        [lineColors addObject:@([lineColor.color toRGBNumber])];
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
    [self.tableView registerNib:[UINib nibWithNibName:[OACollectionSingleLineTableViewCell getCellIdentifier] bundle:nil]
         forCellReuseIdentifier:[OACollectionSingleLineTableViewCell getCellIdentifier]];

    [self.tableView registerNib:[UINib nibWithNibName:OALineChartCell.reuseIdentifier bundle:nil] forCellReuseIdentifier:OALineChartCell.reuseIdentifier];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [_mapPanelViewController.hudViewController updateControlsLayout:YES];
    [_mapPanelViewController.hudViewController updateMapRulerDataWithDelay];
    __weak __typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf refreshPreviewLayer];
    });
    
    [self checkColoringAvailability];
    BOOL isAvailable = [_selectedType.coloringType isAvailableInSubscription];
    if (!isAvailable && _colorValuesCell)
    {
        [_colorValuesCell.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForRow:[_colorValuesCell.collectionView getSelectedIndex] inSection:0]
                                                atScrollPosition:UICollectionViewScrollPositionLeft
                                                        animated:YES];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    __weak __typeof(self) weakSelf = self;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        BOOL landscape = [weakSelf isLandscape];
        if (!landscape)
            [weakSelf goExpanded];
        weakSelf.backButtonContainerView.hidden = !landscape;
        weakSelf.applyButtonContainerView.hidden = !landscape;

        NSMutableArray *indexPaths = [NSMutableArray array];
        for (NSInteger i = 0; i < weakSelf.tableData.subjects.count; i++)
        {
            OAGPXTableSectionData *sectionData = weakSelf.tableData.subjects[i];
            for (NSInteger j = 0; j < sectionData.subjects.count; j++)
            {
                OAGPXTableCellData *cellData = sectionData.subjects[j];
                if ([cellData.key hasSuffix:@"_map_style"])
                    [indexPaths addObject:[NSIndexPath indexPathForRow:j inSection:i]];
            }
        }
        if (indexPaths.count > 0)
            [weakSelf.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [weakSelf refreshPreviewLayer];
    }];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection])
    {
        BOOL isLightTheme = [ThemeManager shared].isLightTheme;
        [self.statusBarBackgroundView addBlurEffect:isLightTheme cornerRadius:0. padding:0.];
        [self.backButton addBlurEffect:isLightTheme cornerRadius:12. padding:0];
        [self.applyButton addBlurEffect:isLightTheme cornerRadius:12. padding:0.];
    }
}

- (void)hide
{
    __weak __typeof(self) weakSelf = self;
    [self hide:YES duration:.2 onComplete:^{
        if (weakSelf.isDefaultColorRestored)
            [weakSelf.settings.routeGradientPalette set:weakSelf.previewRouteLineInfo.gradientPalette mode:weakSelf.appMode];

        if (weakSelf.mapSourceUpdatedObserver)
        {
            [weakSelf.mapSourceUpdatedObserver detach];
            weakSelf.mapSourceUpdatedObserver = nil;
        }
        [weakSelf.settings.appearanceMode set:weakSelf.oldDayNightMode mode:weakSelf.appMode];
        [[OADayNightHelper instance] forceUpdate];

        [weakSelf updateRouteLayer:weakSelf.oldPreviewRouteLineInfo];
        [weakSelf.mapPanelViewController.mapViewController.mapLayers.routePreviewLayer resetLayer];

        if (weakSelf.delegate)
            [weakSelf.delegate onCloseAppearance];
    }];
}

- (void)hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete
{
    __weak __typeof(self) weakSelf = self;
    [super hide:YES duration:duration onComplete:^{
        [weakSelf.mapPanelViewController.hudViewController resetToDefaultRulerLayout];
        [weakSelf.mapPanelViewController hideScrollableHudViewController];
        if (onComplete)
            onComplete();

        [weakSelf.mapPanelViewController.mapViewController.mapLayers.routeMapLayer setPreviewRouteLineInfo:nil];

        if (weakSelf.prevScreen == EOARouteLineAppearancePrevScreenSettings)
        {
            UINavigationController *navigationController = [OARootViewController instance].navigationController;
            [navigationController pushViewController:[[OAMainSettingsViewController alloc] init] animated:NO];
            [navigationController pushViewController:[[OAConfigureProfileViewController alloc] initWithAppMode:weakSelf.appMode targetScreenKey:nil] animated:NO];
            [navigationController pushViewController:[[OAProfileNavigationSettingsViewController alloc] initWithAppMode:weakSelf.appMode] animated:YES];
        }
        else if (weakSelf.prevScreen == EOARouteLineAppearancePrevScreenNavigation)
        {
            [weakSelf.mapPanelViewController showRouteInfo];
            [weakSelf.mapPanelViewController showRoutePreferences];
        }
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
        headerTitle = OALocalizedString(@"shared_string_color");

    OAGPXTableSectionData *sectionData = _tableData.subjects[sectionIndex];
    if (sectionData.header)
        headerTitle = sectionData.header;

    [self.titleView setText:headerTitle.upperCase];
}

- (void)setupButtonsNavigationBarView
{
    [self.statusBarBackgroundView addBlurEffect:[ThemeManager shared].isLightTheme cornerRadius:0. padding:0.];
    _originalStatusBarHeight = self.statusBarBackgroundView.frame.size.height;

    [self.titleNavBarView setText:OALocalizedString(@"customize_route_line")];
    [self.descriptionNavBarView setText:_appMode.name];

    BOOL isRTL = [self.statusBarBackgroundView isDirectionRTL];
    UIImage *backImage = [UIImage templateImageNamed:@"ic_custom_arrow_back"];
    [self.backButton setImage:isRTL ? backImage.imageFlippedForRightToLeftLayoutDirection : backImage
                     forState:UIControlStateNormal];
    self.backButton.imageView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
    [self.backButton addBlurEffect:[ThemeManager shared].isLightTheme cornerRadius:12. padding:0];
    self.backButton.accessibilityLabel = localizedString(@"shared_string_dismiss");
    backImage = [UIImage templateImageNamed:@"ic_navbar_chevron"];

    [self.backNavBarButton setImage:isRTL ? backImage.imageFlippedForRightToLeftLayoutDirection : backImage
                           forState:UIControlStateNormal];
    self.backNavBarButton.imageView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
    [self.backNavBarButton setAttributedTitle:
                    [[NSAttributedString alloc] initWithString:OALocalizedString(@"shared_string_back")
                                                    attributes:@{ NSFontAttributeName:[UIFont preferredFontForTextStyle:UIFontTextStyleBody] }]
                                     forState:UIControlStateNormal];
    self.backNavBarButton.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
            [self.backNavBarButton.titleLabel.leadingAnchor constraintEqualToAnchor:self.backNavBarButton.leadingAnchor constant:20.],
            [self.backNavBarButton.titleLabel.trailingAnchor constraintEqualToAnchor:self.backNavBarButton.trailingAnchor],
            [self.backNavBarButton.titleLabel.topAnchor constraintEqualToAnchor:self.backNavBarButton.topAnchor],
            [self.backNavBarButton.titleLabel.bottomAnchor constraintEqualToAnchor:self.backNavBarButton.bottomAnchor]
    ]];

    [self.applyButton addBlurEffect:[ThemeManager shared].isLightTheme cornerRadius:12. padding:0.];
    [self.applyButton setAttributedTitle:
                    [[NSAttributedString alloc] initWithString:OALocalizedString(@"shared_string_apply")
                                                    attributes:@{ NSFontAttributeName:[UIFont scaledBoldSystemFontOfSize:17.] }]
                                forState:UIControlStateNormal];
    [self.applyNavBarButton setAttributedTitle:
                    [[NSAttributedString alloc] initWithString:OALocalizedString(@"shared_string_apply")
                                                    attributes:@{ NSFontAttributeName:[UIFont scaledBoldSystemFontOfSize:17.] }]
                                      forState:UIControlStateNormal];

    self.applyNavBarButton.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
            [self.applyNavBarButton.titleLabel.leadingAnchor constraintEqualToAnchor:self.applyNavBarButton.leadingAnchor],
            [self.applyNavBarButton.titleLabel.trailingAnchor constraintEqualToAnchor:self.applyNavBarButton.trailingAnchor],
            [self.applyNavBarButton.titleLabel.topAnchor constraintEqualToAnchor:self.applyNavBarButton.topAnchor],
            [self.applyNavBarButton.titleLabel.bottomAnchor constraintEqualToAnchor:self.applyNavBarButton.bottomAnchor]
    ]];
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
                kCellType:[OASwitchTableViewCell getCellIdentifier],
                kCellTitle:OALocalizedString(@"map_widget_renderer")
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
                kCellType:[OASwitchTableViewCell getCellIdentifier],
                kCellTitle:OALocalizedString(@"map_widget_renderer")
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
                kCellType:[OASwitchTableViewCell getCellIdentifier],
                kCellTitle:OALocalizedString(@"turn_arrows")
        }];
        [turnArrowsSectionData.subjects addObject:turnArrowsCellData];

        // actions section
        OAGPXTableSectionData *resetSectionData = [OAGPXTableSectionData withData:@{
                kTableKey: @"section_reset",
                kSectionHeader:OALocalizedString(@"shared_string_actions"),
                kSectionFooterHeight: @60.
        }];
        [_tableData.subjects addObject:resetSectionData];

        OAGPXTableCellData *resetCellData = [OAGPXTableCellData withData:@{
                kTableKey: @"reset",
                kCellType: [OARightIconTableViewCell getCellIdentifier],
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
    return [OAUtilities isIPad] ?  [OAUtilities getStatusBarHeight] : _originalStatusBarHeight;
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
    NSString *gradientPaletteName = [_settings.routeGradientPalette get:_appMode];
    BOOL showTurnArrows = [_settings.routeShowTurnArrows get:_appMode];

    OAPreviewRouteLineInfo *previewRouteLineInfo = [[OAPreviewRouteLineInfo alloc] initWithCustomColorDay:colorDay
                                                                                         customColorNight:colorNight
                                                                                             coloringType:coloringType
                                                                                       routeInfoAttribute:routeInfoAttribute
                                                                                                    width:widthKey
                                                                                          gradientPalette:gradientPaletteName
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
    __weak __typeof(self) weakSelf = self;
    [_mapPanelViewController.mapViewController runWithRenderSync:^{
        [routeLayer resetLayer];
        [previewLayer resetLayer];
        
        [routeLayer refreshRoute];
        [weakSelf refreshPreviewLayer];
    }];
}

- (void)checkColoringAvailability
{
    BOOL isAvailable = [_selectedType.coloringType isAvailableInSubscription];
    if (!isAvailable)
        [OAPluginPopupViewController askForPlugin:kInAppId_Addon_Advanced_Widgets];
    self.applyButton.userInteractionEnabled = isAvailable;
    [self.applyButton setTitleColor:isAvailable ? [UIColor colorNamed:ACColorNameIconColorActive] : [UIColor colorNamed:ACColorNameTextColorSecondary]
                           forState:UIControlStateNormal];
    self.applyNavBarButton.userInteractionEnabled = isAvailable;
    [self.applyNavBarButton setTitleColor:isAvailable ? [UIColor colorNamed:ACColorNameIconColorActive] : [UIColor colorNamed:ACColorNameTextColorSecondary]
                           forState:UIControlStateNormal];
}

- (OAGPXTableCellData *)generateTopDescriptionCellData
{
    return [OAGPXTableCellData withData:@{
            kTableKey: @"top_description",
            kCellType: [OATextLineViewCell getCellIdentifier],
            kCellTitle: _selectedType.topDescription
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

- (OAGPXTableCellData *)generatePaletteLegendCellData
{
    return [OAGPXTableCellData withData:@{
        kTableKey: @"gradientLegend",
        kCellType: [OALineChartCell getCellIdentifier]
    }];
}

- (OAGPXTableCellData *)generatePaletteNameCellData
{
    return [OAGPXTableCellData withData:@{
        kTableKey: @"paletteName",
        kCellType: [OASimpleTableViewCell getCellIdentifier],
        kCellTitle: [_selectedPaletteColorItem toHumanString],
        kCellTintColor: UIColorFromRGB(color_extra_text_gray)
    }];
}

- (OAGPXTableCellData *)generateGridCellData
{
    return [OAGPXTableCellData withData:@{
        kTableKey: @"color_grid",
        kCellType: [OACollectionSingleLineTableViewCell getCellIdentifier]
    }];
}

- (OAGPXTableCellData *) generateAllColorsCellData
{
    return [OAGPXTableCellData withData:@{
        kTableKey: @"allColors",
        kCellType: [OASimpleTableViewCell getCellIdentifier],
        kCellTitle: OALocalizedString(@"shared_string_all_colors"),
        kCellTintColor: [UIColor colorNamed:ACColorNameIconColorActive]
    }];
}

- (void)removeCellsFromSection:(OAGPXTableSectionData *)sectionData cellKeys:(NSArray<NSString *> *)cellKeys
{
    [sectionData.subjects.copy enumerateObjectsUsingBlock:^(OAGPXTableCellData * _Nonnull cellData, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([cellKeys containsObject:cellData.key])
            [sectionData.subjects removeObject:cellData];
    }];
}

- (void)removeCellFromSection:(OAGPXTableSectionData *)sectionData cellKey:(NSString *)cellKey
{
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
        
        NSArray *cellKeys = @[
            @"color_day_night_empty_space",
            @"color_day_night_value",
            @"color_grid",
            @"top_description",
            @"bottom_description",
            @"gradientLegend",
            @"paletteName",
            @"allColors"
        ];
        
        for (NSString *key in cellKeys) {
            [self removeCellFromSection:sectionData cellKey:key];
        }
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
    _cellPaletteLegendIndex = -1;
    _cellPaletteNameIndex = -1;
    _cellColorGridIndex = -1;
    OAGPXTableSectionData *sectionData = [_tableData getSubject:@"section_color"];
    if (sectionData)
    {
        if (![sectionData.values[@"color_map_style"] boolValue])
        {
            [self clearColorSection:NO];

            OAGPXTableCellData *colorTypesCellData = [sectionData getSubject:@"color_types"];
            if (!colorTypesCellData)
            {
                [sectionData.subjects addObject:[OAGPXTableCellData withData:@{
                        kTableKey: @"color_types_empty_space",
                        kCellType: [OADividerCell getCellIdentifier],
                        kTableValues: @{ @"float_value": @10. }
                }]];
                NSMutableArray<NSDictionary *> *lineColoringTypes = [NSMutableArray array];
                for (OARouteAppearanceType *type in _coloringTypes)
                {
                    [lineColoringTypes addObject:@{
                            @"title": type.title,
                            @"available": @(type.isActive)
                    }];
                }
                [sectionData.subjects addObject:[OAGPXTableCellData withData:@{
                        kTableKey: @"color_types",
                        kCellType: [OAFoldersCell getCellIdentifier],
                        kTableValues: @{
                                @"array_value": lineColoringTypes,
                                @"selected_integer_value": @([_coloringTypes indexOfObject:_selectedType])
                        }
                }]];
            }

            if ([_selectedType.coloringType isCustomColor])
            {
                [sectionData.subjects addObject:[OAGPXTableCellData withData:@{
                        kTableKey: @"color_day_night_empty_space",
                        kCellType: [OADividerCell getCellIdentifier],
                        kTableValues: @{ @"float_value": @8. }
                }]];
                [sectionData.subjects addObject:[OAGPXTableCellData withData:@{
                        kTableKey: @"color_day_night_value",
                        kCellType: [OASegmentedControlCell getCellIdentifier],
                        kTableValues: @{ @"array_value": @[kColorDayMode, kColorNightMode] },
                        kCellToggle: @NO
                }]];
                [sectionData.subjects addObject:[OAGPXTableCellData withData:@{
                        kTableKey: @"color_grid",
                        kCellType: [OAColorsTableViewCell getCellIdentifier],
                        kTableValues: @{
                                @"array_value": _availableColors,
                                @"int_value": @([_previewRouteLineInfo getCustomColor:_nightMode])
                        }
                }]];
            }
            else if ([_selectedType.coloringType isGradient])
            {
                [sectionData.subjects addObject:[self generatePaletteLegendCellData]];
                _cellPaletteLegendIndex = sectionData.subjects.count - 1;
                [sectionData.subjects addObject:[self generatePaletteNameCellData]];
                _cellPaletteNameIndex = sectionData.subjects.count - 1;
                [sectionData.subjects addObject:[self generateGridCellData]];
                _cellColorGridIndex = sectionData.subjects.count - 1;
                [sectionData.subjects addObject:[self generateAllColorsCellData]];
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
            _cellColorGridIndex = [sectionData.subjects indexOfObject:colorGridCellData];
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
                [sectionData.subjects addObject:[OAGPXTableCellData withData:@{
                        kTableKey: @"width_types_empty_space",
                        kCellType: [OADividerCell getCellIdentifier],
                        kTableValues: @{ @"float_value": @12. }
                }]];
                [sectionData.subjects addObject:[OAGPXTableCellData withData:@{
                        kTableKey: @"width_value",
                        kCellType: [OASegmentedControlCell getCellIdentifier],
                        kTableValues: @{ @"array_value": [OARouteWidthMode getRouteWidthModes] },
                        kCellToggle: @YES
                }]];
                [sectionData.subjects addObject:[OAGPXTableCellData withData:@{
                        kTableKey: @"width_slider_empty_space",
                        kCellType: [OADividerCell getCellIdentifier],
                        kTableValues: @{ @"float_value": [self isCustomWidthMode] ? @6. : @19. }
                }]];
            }

            OAGPXTableCellData *widthCustomSliderCellData = [sectionData getSubject:@"width_custom_slider"];
            if ([self isCustomWidthMode] && !widthCustomSliderCellData)
            {
                OARouteLayer *routeLayer = _mapPanelViewController.mapViewController.mapLayers.routeMapLayer;
                NSMutableArray<NSString *> *customWidthValues = [NSMutableArray array];
                for (NSInteger i = [routeLayer getCustomRouteWidthMin]; i <= [routeLayer getCustomRouteWidthMax]; i++)
                {
                    [customWidthValues addObject:[NSString stringWithFormat:@"%li", i]];
                }

                [sectionData.subjects addObject:[OAGPXTableCellData withData:@{
                        kTableKey: @"width_custom_slider",
                        kCellType: [OASegmentSliderTableViewCell getCellIdentifier],
                        kTableValues: @{
                                @"custom_string_value": [NSString stringWithFormat:@"%li",
                                        [sectionData.values[@"custom_width_value"] integerValue]],
                                @"array_value": customWidthValues
                        }
                }]];
            }
        }
        else
        {
            [self clearWidthSection:YES];
        }
    }
}

#pragma mark - Cell action methods

- (void)onSwitch:(BOOL)toggle tableData:(OAGPXBaseTableData *)tableData
{
    if ([tableData.key isEqualToString:@"cell_color_map_style"])
    {
        OAGPXTableSectionData *sectionData = [_tableData getSubject:@"section_color"];
        if (sectionData)
        {
            sectionData.values[@"color_map_style"] = @(toggle);
            if (toggle)
            {
                _selectedType = [self getRouteAppearanceType:OAColoringType.DEFAULT];
                self.applyButton.userInteractionEnabled = YES;
                self.applyNavBarButton.userInteractionEnabled = YES;
                [self.applyButton setTitleColor:[UIColor colorNamed:ACColorNameIconColorActive] forState:UIControlStateNormal];
                [self.applyNavBarButton setTitleColor:[UIColor colorNamed:ACColorNameIconColorActive] forState:UIControlStateNormal];
            }
            else if (_selectedType.coloringType == OAColoringType.DEFAULT)
            {
                _selectedType = [self getRouteAppearanceType:OAColoringType.CUSTOM_COLOR];
            }
            else
            {
                _selectedType = [self getRouteAppearanceType:_previewRouteLineInfo.coloringType];
            }

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
    else if ([tableData.key isEqualToString:@"color_grid"] && [_selectedType.coloringType isGradient])
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
    else if ([tableData.key isEqualToString:@"paletteName"])
    {
        [tableData setData:@{
            kCellTitle: [_selectedPaletteColorItem toHumanString]
        }];
    }
}

- (void)updateProperty:(id)value tableData:(OAGPXBaseTableData *)tableData
{
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
    else if ([tableData.key isEqualToString:@"allColors"])
    {
        OAColorCollectionViewController *colorCollectionViewController = [[OAColorCollectionViewController alloc] initWithCollectionType:EOAColorCollectionTypePaletteItems
                                                                                                                                   items:_gradientColorsCollection
                                                                                                                            selectedItem:_selectedPaletteColorItem];
        colorCollectionViewController.delegate = self;
        [self.navigationController pushViewController:colorCollectionViewController animated:YES];
    }
}

- (IBAction)onBackButtonPressed:(id)sender
{
    [self hide];
}

- (IBAction)onApplyButtonPressed:(id)sender
{
    __weak __typeof(self) weakSelf = self;
    [self hide:YES duration:.2 onComplete:^{
        [weakSelf.settings.customRouteColorDay set:[weakSelf.previewRouteLineInfo getCustomColor:NO] mode:weakSelf.appMode];
        [weakSelf.settings.customRouteColorNight set:[weakSelf.previewRouteLineInfo getCustomColor:YES] mode:weakSelf.appMode];
        [weakSelf.settings.routeColoringType set:weakSelf.previewRouteLineInfo.coloringType mode:weakSelf.appMode];
        [weakSelf.settings.routeInfoAttribute set:weakSelf.previewRouteLineInfo.routeInfoAttribute mode:weakSelf.appMode];
        [weakSelf.settings.routeLineWidth set:weakSelf.previewRouteLineInfo.width mode:weakSelf.appMode];
        [weakSelf.settings.routeGradientPalette set:weakSelf.previewRouteLineInfo.gradientPalette mode:weakSelf.appMode];
        [weakSelf.settings.routeShowTurnArrows set:weakSelf.previewRouteLineInfo.showTurnArrows mode:weakSelf.appMode];

        if (weakSelf.mapSourceUpdatedObserver)
        {
            [weakSelf.mapSourceUpdatedObserver detach];
            weakSelf.mapSourceUpdatedObserver = nil;
        }
        [weakSelf.settings.appearanceMode set:weakSelf.oldDayNightMode mode:weakSelf.appMode];
        [[OADayNightHelper instance] forceUpdate];

        [weakSelf updateRouteLayer:weakSelf.previewRouteLineInfo];
        [weakSelf.mapPanelViewController.mapViewController.mapLayers.routePreviewLayer resetLayer];

        if (weakSelf.delegate)
            [weakSelf.delegate onCloseAppearance];
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
            cell.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
            cell.dividerColor = [UIColor colorNamed:ACColorNameCustomSeparator];
            cell.dividerInsets = UIEdgeInsetsZero;
            cell.separatorInset = UIEdgeInsetsMake(0., self.tableView.frame.size.width, 0., 0.);
            cell.dividerHight = 0.;
        }
        outCell = cell;
    }
    else if ([cellData.type isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell =
                [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier]
                                                         owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.switchView.on = [self isOn:cellData];
            cell.titleLabel.text = cellData.title;

            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(onSwitchPressed:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
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
            cell.valueLabel.tintColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
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
            _colorValuesCell.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
            _colorValuesCell.collectionView.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
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
            cell.textView.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
        }
        if (cell)
        {
            [cell makeSmallMargins:indexPath.row != [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1];
            cell.textView.text = cellData.title;
            cell.textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
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
            cell.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
            cell.segmentedControl.backgroundColor = [[UIColor colorNamed:ACColorNameIconColorActive] colorWithAlphaComponent:.1];
            [cell changeHeight:YES];
            UIFont *font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            [cell.segmentedControl setTitleTextAttributes:@{
                NSForegroundColorAttributeName : UIColor.whiteColor,
                NSFontAttributeName : font }
                                                 forState:UIControlStateSelected];
            [cell.segmentedControl setTitleTextAttributes:@{
                NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameTextColorActive],
                NSFontAttributeName : font }
                                                 forState:UIControlStateNormal];

            cell.segmentedControl.selectedSegmentTintColor = [UIColor colorNamed:ACColorNameIconColorActive];
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
            cell.topRightLabel.textColor = [UIColor colorNamed:ACColorNameTextColorActive];
            cell.topRightLabel.font = [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightMedium];
        }
        if (cell)
        {
            [cell showLabels:NO topRight:NO bottomLeft:YES bottomRight:YES];
            cell.bottomLeftLabel.text = arrayValue.firstObject;
            cell.bottomRightLabel.text = arrayValue.lastObject;
            [cell.sliderView setNumberOfMarks:arrayValue.count];
            cell.sliderView.selectedMark = [arrayValue indexOfObject:cellData.values[@"custom_string_value"]];

            cell.sliderView.tag = indexPath.section << 10 | indexPath.row;
            [cell.sliderView removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
            [cell.sliderView addTarget:self
                                action:@selector(sliderChanged:)
                      forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
        }
        outCell = cell;
    }
    else if ([cellData.type isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
    {
        OARightIconTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier]
                                                         owner:self options:nil];
            cell = (OARightIconTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameTextColorActive];
            cell.rightIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
        }
        if (cell)
        {
            cell.titleLabel.text = cellData.title;
            cell.rightIconView.image = [UIImage templateImageNamed:cellData.rightIconName];
        }
        return cell;
    }
    else if ([cellData.type isEqualToString:[OACollectionSingleLineTableViewCell getCellIdentifier]])
    {
        OACollectionSingleLineTableViewCell *cell =
            [tableView dequeueReusableCellWithIdentifier:[OACollectionSingleLineTableViewCell getCellIdentifier]];
        cell.separatorInset = UIEdgeInsetsZero;
        [cell rightActionButtonVisibility:NO];

        PaletteCollectionHandler *paletteHandler = [[PaletteCollectionHandler alloc] initWithData:@[[_sortedPaletteColorItems asArray]] collectionView:cell.collectionView];
        paletteHandler.delegate = self;
        NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:[_sortedPaletteColorItems indexOfObjectSync:_selectedPaletteColorItem] inSection:0];
        if (selectedIndexPath.row == NSNotFound)
            selectedIndexPath = [NSIndexPath indexPathForRow:[_sortedPaletteColorItems indexOfObjectSync:[_gradientColorsCollection getDefaultGradientPalette]] inSection:0];
        [paletteHandler setSelectedIndexPath:selectedIndexPath];
        [cell setCollectionHandler:paletteHandler];
        return cell;
    }
    else if ([cellData.type isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            BOOL isPaletteName = [cellData.key isEqualToString:@"paletteName"];
            cell.selectionStyle = isPaletteName ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleDefault;
            cell.separatorInset = UIEdgeInsetsMake(0., isPaletteName ? 0. : self.tableView.frame.size.width, 0., 0.);
            cell.titleLabel.text = cellData.title;
            cell.titleLabel.textColor = cellData.tintColor ?: [UIColor colorNamed:ACColorNameTextColorPrimary];
            cell.titleLabel.font = [UIFont preferredFontForTextStyle:isPaletteName ? UIFontTextStyleFootnote : UIFontTextStyleBody];
        }
        return cell;
    }
    else if ([cellData.type isEqualToString:OALineChartCell.reuseIdentifier])
    {
        OALineChartCell *cell = (OALineChartCell *) [tableView dequeueReusableCellWithIdentifier:OALineChartCell.reuseIdentifier
                                                                                         forIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.separatorInset = UIEdgeInsetsMake(0, CGFLOAT_MAX, 0, 0);

        [GpxUIHelper setupGradientChartWithChart:cell.lineChartView
                             useGesturesAndScale:NO
                                  xAxisGridColor:[UIColor colorNamed:ACColorNameChartAxisGridLine]
                                     labelsColor:[UIColor colorNamed:ACColorNameTextColorSecondary]];

        ColorPalette *colorPalette;
        if ([_selectedPaletteColorItem isKindOfClass:PaletteGradientColor.class])
        {
            PaletteGradientColor *paletteColor = (PaletteGradientColor *) _selectedPaletteColorItem;
            colorPalette = paletteColor.colorPalette;
        }
        if (!colorPalette)
            return cell;

        cell.lineChartView.data =
            [GpxUIHelper buildGradientChartWithChart:cell.lineChartView
                                        colorPalette:colorPalette
                                      valueFormatter:[GradientUiHelper getGradientTypeFormatter:_gradientColorsCollection.gradientType
                                                                                       analysis:nil]];
        [cell.lineChartView notifyDataSetChanged];
        return cell;
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
                                          font:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]].height;
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
    UIFont *textFont = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    NSMutableAttributedString *textStr = [[NSMutableAttributedString alloc] initWithString:footer attributes:@{
            NSFontAttributeName: textFont,
            NSForegroundColorAttributeName: [UIColor colorNamed:ACColorNameTextColorSecondary]
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
        [self updateProperty:@(cell.sliderView.selectedMark + 1) tableData:cellData];
        [self updateData:cellData];

        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)onCollectionDeleted:(NSNotification *)notification
{
    if (![notification.object isKindOfClass:NSArray.class])
        return;
    
    NSArray<PaletteGradientColor *> *gradientPaletteColor = (NSArray<PaletteGradientColor *> *) notification.object;
    PaletteGradientColor *currentGradientPaletteColor;
    if ([_selectedPaletteColorItem isKindOfClass:PaletteGradientColor.class])
        currentGradientPaletteColor = (PaletteGradientColor *) _selectedPaletteColorItem;
    else
        return;
    
    auto currentIndex = [_sortedPaletteColorItems indexOfObjectSync:currentGradientPaletteColor];
    NSMutableArray<NSIndexPath *> *indexPathsToDelete = [NSMutableArray array];
    for (PaletteGradientColor *paletteColor in gradientPaletteColor)
    {
        NSInteger index = [_sortedPaletteColorItems indexOfObjectSync:paletteColor];
        if (index != NSNotFound)
        {
            [_sortedPaletteColorItems removeObjectSync:paletteColor];
            [indexPathsToDelete addObject:[NSIndexPath indexPathForRow:index inSection:0]];
            if (index == currentIndex)
                _isDefaultColorRestored = YES;
        }
    }
    
    if (indexPathsToDelete.count > 0 && [_selectedType.coloringType isGradient] && _cellColorGridIndex != -1)
    {
        __weak __typeof(self) weakSelf = self;
        [self.tableView performBatchUpdates:^{
            NSIndexPath *colorsCollectionIndexPath = [NSIndexPath indexPathForRow:weakSelf.cellColorGridIndex
                                                                        inSection:weakSelf.sectionColors];
            OACollectionSingleLineTableViewCell *colorCell = [weakSelf.tableView cellForRowAtIndexPath:colorsCollectionIndexPath];
            OABaseCollectionHandler *handler = [colorCell getCollectionHandler];
            [handler removeItems:indexPathsToDelete];
        } completion:^(BOOL finished) {
            if (weakSelf.isDefaultColorRestored)
            {
                weakSelf.previewRouteLineInfo.gradientPalette = PaletteGradientColor.defaultName;
                weakSelf.oldPreviewRouteLineInfo.gradientPalette = weakSelf.previewRouteLineInfo.gradientPalette;
                weakSelf.selectedPaletteColorItem = [weakSelf.gradientColorsCollection getDefaultGradientPalette];
                [weakSelf refreshPreviewLayer];
                
                NSMutableArray *indexPaths = [NSMutableArray array];
                if (weakSelf.cellPaletteNameIndex != -1)
                    [indexPaths addObject:[NSIndexPath indexPathForRow:weakSelf.cellPaletteNameIndex inSection:weakSelf.sectionColors]];
                if (weakSelf.cellPaletteLegendIndex != -1)
                {
                    [weakSelf updateData:weakSelf.tableData.subjects[weakSelf.sectionColors].subjects[weakSelf.cellPaletteLegendIndex]];
                    [indexPaths addObject:[NSIndexPath indexPathForRow:weakSelf.cellPaletteLegendIndex inSection:weakSelf.sectionColors]];
                }
                if (indexPaths.count > 0)
                {
                    [weakSelf.tableView reloadRowsAtIndexPaths:indexPaths
                                              withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            }
        }];
    }
}

- (void)onCollectionCreated:(NSNotification *)notification
{
    if (![notification.object isKindOfClass:NSArray.class])
        return;
    
    NSArray<PaletteGradientColor *> *gradientPaletteColor = (NSArray<PaletteGradientColor *> *) notification.object;
    NSMutableArray<NSIndexPath *> *indexPathsToInsert = [NSMutableArray array];
    for (PaletteGradientColor *paletteColor in gradientPaletteColor)
    {
        NSInteger index = [paletteColor getIndex] - 1;
        NSIndexPath *indexPath;
        if (index < [_sortedPaletteColorItems countSync])
        {
            indexPath = [NSIndexPath indexPathForRow:index inSection:0];
            [_sortedPaletteColorItems insertObjectSync:paletteColor atIndex:index];
        }
        else
        {
            indexPath = [NSIndexPath indexPathForRow:[_sortedPaletteColorItems countSync] inSection:0];
            [_sortedPaletteColorItems addObjectSync:paletteColor];
        }
        [indexPathsToInsert addObject:indexPath];
    }
    
    if (indexPathsToInsert.count > 0 && [_selectedType.coloringType isGradient] && _cellColorGridIndex != -1)
    {
        __weak __typeof(self) weakSelf = self;
        [self.tableView performBatchUpdates:^{
            NSIndexPath *colorsCollectionIndexPath = [NSIndexPath indexPathForRow:weakSelf.cellColorGridIndex
                                                                        inSection:weakSelf.sectionColors];
            OACollectionSingleLineTableViewCell *colorCell = [weakSelf.tableView cellForRowAtIndexPath:colorsCollectionIndexPath];
            OABaseCollectionHandler *handler = [colorCell getCollectionHandler];
            for (NSIndexPath *indexPath in indexPathsToInsert)
            {
                [handler insertItem:[weakSelf.sortedPaletteColorItems objectAtIndexSync:indexPath.row]
                        atIndexPath:indexPath];
            }
        } completion:nil];
    }
}

- (void)onCollectionUpdated:(NSNotification *)notification
{
    if (![notification.object isKindOfClass:NSArray.class])
        return;
    
    NSArray<PaletteGradientColor *> *gradientPaletteColor = (NSArray<PaletteGradientColor *> *) notification.object;
    NSMutableArray<NSIndexPath *> *indexPathsToUpdate = [NSMutableArray array];
    BOOL currentPaletteColor;
    for (PaletteGradientColor *paletteColor in gradientPaletteColor)
    {
        if ([_sortedPaletteColorItems containsObjectSync:paletteColor])
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_sortedPaletteColorItems indexOfObjectSync:paletteColor] inSection:0];
            [indexPathsToUpdate addObject:indexPath];
            if (paletteColor == _selectedPaletteColorItem)
                currentPaletteColor = YES;
        }
    }
    
    if (indexPathsToUpdate.count > 0 && [_selectedType.coloringType isGradient] && _cellColorGridIndex != -1)
    {
        __weak __typeof(self) weakSelf = self;
        [self.tableView performBatchUpdates:^{
            NSIndexPath *colorsCollectionIndexPath = [NSIndexPath indexPathForRow:weakSelf.cellColorGridIndex
                                                                        inSection:weakSelf.sectionColors];
            OACollectionSingleLineTableViewCell *colorCell = [weakSelf.tableView cellForRowAtIndexPath:colorsCollectionIndexPath];
            OABaseCollectionHandler *handler = [colorCell getCollectionHandler];
            for (NSIndexPath *indexPath in indexPathsToUpdate)
            {
                [handler replaceItem:[weakSelf.sortedPaletteColorItems objectAtIndexSync:indexPath.row]
                         atIndexPath:indexPath];
                if (currentPaletteColor && weakSelf.cellPaletteLegendIndex != -1)
                {
                    [weakSelf updateData:weakSelf.tableData.subjects[weakSelf.sectionColors].subjects[weakSelf.cellPaletteLegendIndex]];
                    [weakSelf.tableView reloadRowsAtIndexPaths:@[
                        [NSIndexPath indexPathForRow:weakSelf.cellPaletteLegendIndex inSection:weakSelf.sectionColors]]
                                              withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            }
        } completion:nil];
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
    if ([_selectedType.coloringType isGradient])
    {
        _gradientColorsCollection = [[GradientColorsCollection alloc] initWithColorizationType:(ColorizationType) [_selectedType.coloringType toColorizationType]];
        [_sortedPaletteColorItems replaceAllWithObjectsSync:[_gradientColorsCollection getPaletteColors]];
        _selectedPaletteColorItem = [_gradientColorsCollection getDefaultGradientPalette];
        _previewRouteLineInfo.gradientPalette = PaletteGradientColor.defaultName;
    }

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

    [self checkColoringAvailability];
}

#pragma mark - OAColorsTableViewCellDelegate

- (void)colorChanged:(NSInteger)tag
{
    [_previewRouteLineInfo setCustomColor:_availableColors[tag].intValue nightMode:_nightMode];
    [self updateRouteLayer:_previewRouteLineInfo];

    if (_cellColorGridIndex > -1 && _tableData.subjects.count >= 1)
    {
        OAGPXTableSectionData *sectionData = _tableData.subjects[_sectionColors];
        if (sectionData.subjects.count - 1 >= _cellColorGridIndex)
        {
            OAGPXTableCellData *cellData = sectionData.subjects[_cellColorGridIndex];
            [self updateData:cellData];

            [UIView setAnimationsEnabled:NO];
            [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_cellColorGridIndex
                                                                        inSection:_sectionColors]]
                                  withRowAnimation:UITableViewRowAnimationNone];
            [UIView setAnimationsEnabled:YES];
        }
    }
}

- (void) onMapSourceUpdated
{
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf updateRouteLayer:weakSelf.previewRouteLineInfo];
    });
}

#pragma mark - OACollectionCellDelegate

- (void)onCollectionItemSelected:(NSIndexPath *)indexPath
{
    _selectedPaletteColorItem = [_sortedPaletteColorItems objectAtIndexSync:indexPath.row];
    if ([_selectedPaletteColorItem isKindOfClass:PaletteGradientColor.class])
    {
        PaletteGradientColor *paletteColor = (PaletteGradientColor *) _selectedPaletteColorItem;
        _previewRouteLineInfo.gradientPalette = paletteColor.paletteName;
        [self updateRouteLayer:_previewRouteLineInfo];

        if (_cellPaletteNameIndex > -1 && _tableData.subjects.count >= 1)
        {
            OAGPXTableSectionData *sectionData = _tableData.subjects[_sectionColors];
            if (sectionData.subjects.count - 1 >= _cellPaletteNameIndex)
            {
                NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray array];
                if (_cellPaletteNameIndex > -1)
                {
                    [self updateData:sectionData.subjects[_cellPaletteNameIndex]];
                    [indexPaths addObject:[NSIndexPath indexPathForRow:_cellPaletteNameIndex inSection:_sectionColors]];
                }
                if (_cellPaletteLegendIndex > -1)
                    [indexPaths addObject:[NSIndexPath indexPathForRow:_cellPaletteLegendIndex inSection:_sectionColors]];

                if (indexPaths.count > 0)
                {
                    [UIView setAnimationsEnabled:NO];
                    [self.tableView reloadRowsAtIndexPaths:indexPaths
                                          withRowAnimation:UITableViewRowAnimationNone];
                    [UIView setAnimationsEnabled:YES];
                }
            }
        }
    }
}

- (void)reloadCollectionData
{
}

#pragma mark - OAColorCollectionDelegate

- (void)selectPaletteItem:(PaletteColor *)paletteItem
{
    [self onCollectionItemSelected:[NSIndexPath indexPathForRow:[_sortedPaletteColorItems indexOfObjectSync:paletteItem] inSection:0]];
}

@end
