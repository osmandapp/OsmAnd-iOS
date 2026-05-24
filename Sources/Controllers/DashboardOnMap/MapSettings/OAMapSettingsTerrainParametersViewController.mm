//
//  OAMapSettingsTerrainParametersViewController.m
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 08.09.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAMapSettingsTerrainParametersViewController.h"
#import "Localization.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OsmAndApp.h"
#import "OATitleSliderTableViewCell.h"
#import "OACustomPickerTableViewCell.h"
#import "OAValueTableViewCell.h"
#import "OACollectionSingleLineTableViewCell.h"
#import "OASimpleTableViewCell.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAMapLayers.h"
#import "OAAppData.h"
#import "OATerrainMapLayer.h"
#import "OAConcurrentCollections.h"
#import "GeneratedAssetSymbols.h"
#import <DGCharts/DGCharts-Swift.h>

static const NSInteger kMinZoomPickerRow = 1;
static const NSInteger kMaxZoomPickerRow = 2;
static const NSInteger kElevationMinMeters = 0;
static const NSInteger kElevationMaxMeters = 2000;

@interface OAMapSettingsTerrainParametersViewController () <UITableViewDelegate, UITableViewDataSource, OACustomPickerTableViewCellDelegate, OACollectionCellDelegate, ColorCollectionViewControllerDelegate, UIColorPickerViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *backButtonContainerView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIView *doneButtonContainerView;
@property (weak, nonatomic) IBOutlet UIButton *resetButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *backButtonLeadingConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *resetButtonTrailingConstraint;

@property (nonatomic) OAMapPanelViewController *mapPanel;
@property (nonatomic) OAConcurrentArray<OASPaletteItemGradient *> *sortedPaletteColorItems;
@property (nonatomic) NSMutableArray<OASPaletteItemSolid *> *sortedColorItems;
@property (nonatomic) OAGPXAppearanceCollection *appearanceCollection;
@property (nonatomic) NSIndexPath *paletteGridIndexPath;
@property (nonatomic) NSIndexPath *paletteNameIndexPath;
@property (nonatomic) NSIndexPath *paletteLegendIndexPath;
@property (nonatomic) NSIndexPath *colorsCollectionIndexPath;
@property (nonatomic) OASPaletteItemGradient *basePaletteColorItem;
@property (nonatomic) OASPaletteItemGradient *currentPaletteColorItem;
@property (nonatomic) OASPaletteItemSolid *baseDayColorItem;
@property (nonatomic) OASPaletteItemSolid *currentDayColorItem;
@property (nonatomic) OASPaletteItemSolid *baseNightColorItem;
@property (nonatomic) OASPaletteItemSolid *currentNightColorItem;
@property (nonatomic) BOOL isDefaultColorRestored;
@property (nonatomic) BOOL isNightCoordinatesGridColorMode;

@end

@implementation OAMapSettingsTerrainParametersViewController
{
    OsmAndAppInstance _app;
    OATableDataModel *_data;
    TerrainMode *_terrainMode;
    OASRTMPlugin *_plugin;
    OAAppSettings *_settings;
    OACoordinatesGridSettings *_coordinatesGridSettings;

    NSArray<NSString *> *_possibleZoomValues;

    NSInteger _minZoom;
    NSInteger _maxZoom;
    NSInteger _baseMinZoom;
    NSInteger _baseMaxZoom;
    double _baseAlpha;
    double _currentAlpha;

    double _baseVerticalExaggerationScale;
    double _currentVerticalExaggerationScale;

    double _baseGPXVerticalExaggerationScale;
    double _currentGPXVerticalExaggerationScale;

    NSInteger _baseGPXElevationMeters;
    NSInteger _currentGPXElevationMeters;

    NSIndexPath *_minValueIndexPath;
    NSIndexPath *_maxValueIndexPath;
    NSIndexPath *_openedPickerIndexPath;

    UIButton *_applyButton;

    BOOL _isValueChange;
}

#pragma mark - Initialization

- (instancetype)initWithSettingsType:(EOATerrainSettingsType)terrainType
{
    self = [super initWithNibName:@"OAMapSettingsTerrainParametersViewController" bundle:nil];
    if (self)
    {
        _terrainType = terrainType;
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _data = [OATableDataModel model];
    _app = OsmAndApp.instance;
    _plugin = (OASRTMPlugin *) [OAPluginsHelper getPlugin:OASRTMPlugin.class];
    _terrainMode = [_plugin getTerrainMode];
    _mapPanel = OARootViewController.instance.mapPanel;
    _settings = [OAAppSettings sharedManager];
    _coordinatesGridSettings = [[OACoordinatesGridSettings alloc] init];

    _baseMinZoom = _terrainType == EOATerrainSettingsTypeCoordinatesGridZoomLevels ? [_coordinatesGridSettings getZoomLevelsWithRestrictionsForAppMode:[_settings.applicationMode get]].min : [_plugin getTerrainMinZoom];
    _baseMaxZoom = _terrainType == EOATerrainSettingsTypeCoordinatesGridZoomLevels ? [_coordinatesGridSettings getZoomLevelsWithRestrictionsForAppMode:[_settings.applicationMode get]].max : [_plugin getTerrainMaxZoom];
    _baseAlpha = [_terrainMode getTransparency] * 0.01;

    if (_terrainType == EOATerrainSettingsTypeVerticalExaggeration)
    {
        _baseVerticalExaggerationScale = _app.data.verticalExaggerationScale;
        _currentVerticalExaggerationScale = _baseVerticalExaggerationScale;
    }
    else if (_terrainType == EOATerrainSettingsTypePalette)
    {
        OASGradientPaletteCategory *paletteCategory = [TerrainTypeWrapper toPaletteCategoryWithType:_terrainMode.type];
        _sortedPaletteColorItems = [[OAConcurrentArray alloc] init];
        if (paletteCategory)
        {
            [_sortedPaletteColorItems addObjectsSync:[[GradientPaletteHelper shared] paletteItemsWithCategory:paletteCategory sortMode:OASPaletteSortMode.lastUsedTime]];
            _basePaletteColorItem = [[GradientPaletteHelper shared] paletteItemOrDefaultWithCategory:paletteCategory name:[_terrainMode getKeyName]];
        }
        _currentPaletteColorItem = _basePaletteColorItem;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(productPurchased:)
                                                     name:OAIAPProductPurchasedNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(productsRestored:)
                                                     name:OAIAPProductsRestoredNotification
                                                   object:nil];
    }
    else if (_terrainType == EOATerrainSettingsTypeCoordinatesGridColor)
    {
        _appearanceCollection = [OAGPXAppearanceCollection sharedInstance];
        _sortedColorItems = [NSMutableArray arrayWithArray:[_appearanceCollection getAvailableColorsSortingByLastUsed]];
        _isNightCoordinatesGridColorMode = _settings.nightMode;
        _baseDayColorItem = [_appearanceCollection getColorItemWithValue:[_coordinatesGridSettings getDayGridColor]] ?: [_appearanceCollection defaultLineColorItem];
        _currentDayColorItem  = _baseDayColorItem;
        _baseNightColorItem = [_appearanceCollection getColorItemWithValue:[_coordinatesGridSettings getNightGridColor]] ?: [_appearanceCollection defaultLineColorItem];
        _currentNightColorItem = _baseNightColorItem;
    }

    _minZoom = _baseMinZoom;
    _maxZoom = _baseMaxZoom;
    _currentAlpha = _baseAlpha;
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
}

- (void)configureGPXVerticalExaggerationScale:(CGFloat)scale
{
    if (_terrainType == EOAGPXSettingsTypeVerticalExaggeration)
    {
        _baseGPXVerticalExaggerationScale = scale;
        _currentGPXVerticalExaggerationScale = _baseGPXVerticalExaggerationScale;
    }
}

- (void)configureGPXElevationMeters:(NSInteger)meters
{
    if (_terrainType == EOAGPXSettingsTypeWallHeight)
    {
        _baseGPXElevationMeters = meters;
        _currentGPXElevationMeters = _baseGPXElevationMeters;
    }
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self applyLocalization];

    _possibleZoomValues = [self getPossibleZoomValues];
    [self registerCells];
    [self generateData];

    [self.resetButton setImage:[UIImage templateImageNamed:@"ic_navbar_reset"] forState:UIControlStateNormal];
    [self.backButton addBlurEffect:[ThemeManager shared].isLightTheme cornerRadius:12. padding:0];
    [self.resetButton addBlurEffect:[ThemeManager shared].isLightTheme cornerRadius:12. padding:0];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    [self setupBottomButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refreshColorsCollection];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [_mapPanel targetUpdateControlsLayout:YES
                     customStatusBarStyle:_settings.nightMode ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    __weak __typeof(self) weakSelf = self;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        if (![weakSelf isLandscape])
            [weakSelf goMinimized:NO];
    } completion:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];

    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection])
    {
        [self.backButton addBlurEffect:[ThemeManager shared].isLightTheme cornerRadius:12. padding:0];
        [self.resetButton addBlurEffect:[ThemeManager shared].isLightTheme cornerRadius:12. padding:0];
    }
}

- (void)registerCells
{
    [self.tableView registerNib:[UINib nibWithNibName:[OATitleSliderTableViewCell reuseIdentifier] bundle:nil] forCellReuseIdentifier:[OATitleSliderTableViewCell reuseIdentifier]];
    [self.tableView registerNib:[UINib nibWithNibName:[OAValueTableViewCell reuseIdentifier] bundle:nil] forCellReuseIdentifier:[OAValueTableViewCell reuseIdentifier]];
    [self.tableView registerNib:[UINib nibWithNibName:[RouteInfoListItemCell reuseIdentifier] bundle:nil] forCellReuseIdentifier:[RouteInfoListItemCell reuseIdentifier]];
    [self.tableView registerNib:[UINib nibWithNibName:[OACustomPickerTableViewCell reuseIdentifier] bundle:nil] forCellReuseIdentifier:[OACustomPickerTableViewCell reuseIdentifier]];
    [self.tableView registerNib:[UINib nibWithNibName:[OASimpleTableViewCell reuseIdentifier] bundle:nil] forCellReuseIdentifier:[OASimpleTableViewCell reuseIdentifier]];
    [self.tableView registerNib:[UINib nibWithNibName:[OACollectionSingleLineTableViewCell reuseIdentifier] bundle:nil] forCellReuseIdentifier:[OACollectionSingleLineTableViewCell reuseIdentifier]];
    [self.tableView registerNib:[UINib nibWithNibName:GradientChartCell.reuseIdentifier bundle:nil] forCellReuseIdentifier:GradientChartCell.reuseIdentifier];
    [self.tableView registerNib:[UINib nibWithNibName:SegmentTextTableViewCell.reuseIdentifier bundle:nil] forCellReuseIdentifier:SegmentTextTableViewCell.reuseIdentifier];
}

#pragma mark - Base setup UI

- (void)applyLocalization
{
    [self.backButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
}

- (NSString *)getHeaderText
{
    NSString *result = nil;
    switch (_terrainType)
    {
        case EOATerrainSettingsTypeVisibility:
            result = OALocalizedString(@"visibility");
            break;
        case EOATerrainSettingsTypePalette:
            result = [_terrainMode getDescription];
            break;
        case EOATerrainSettingsTypeZoomLevels:
        case EOATerrainSettingsTypeCoordinatesGridZoomLevels:
            result = OALocalizedString(@"shared_string_zoom_levels");
            break;
        case EOATerrainSettingsTypeVerticalExaggeration:
        case EOAGPXSettingsTypeVerticalExaggeration:
            result = OALocalizedString(@"vertical_exaggeration");
            break;
        case EOAGPXSettingsTypeWallHeight:
            result = OALocalizedString(@"wall_height");
            break;
        case EOATerrainSettingsTypeCoordinatesGridColor:
            result = OALocalizedString(@"grid_color");
            break;
    }
    return result;
}

- (NSString *)getFooterText
{
    NSString *result = nil;
    switch (_terrainType)
    {
        case EOATerrainSettingsTypeVisibility:
        case EOATerrainSettingsTypePalette:
        case EOATerrainSettingsTypeCoordinatesGridColor:
            break;
        case EOATerrainSettingsTypeZoomLevels:
        case EOATerrainSettingsTypeCoordinatesGridZoomLevels:
            result = OALocalizedString(@"map_settings_zoom_level_description");
            break;
        case EOAGPXSettingsTypeVerticalExaggeration:
            result = OALocalizedString(@"track_vertical_exaggeration_description");
            break;
        case EOATerrainSettingsTypeVerticalExaggeration:
            result = OALocalizedString(@"vertical_exaggeration_description");
            break;
        case EOAGPXSettingsTypeWallHeight:
            result = OALocalizedString(@"wall_height_description");
            break;
    }
    return result;
}

- (void)generateData
{
    [_data clearAllData];

    OATableSectionData *topSection = [_data createNewSection];
    topSection.headerText = [self getHeaderText];
    topSection.footerText = [self getFooterText];
    if (_terrainType == EOATerrainSettingsTypeVerticalExaggeration || _terrainType == EOAGPXSettingsTypeVerticalExaggeration)
    {
        [topSection addRowFromDictionary:@{
            kCellKeyKey : @"verticalExaggerationSlider",
            kCellTypeKey : [OATitleSliderTableViewCell reuseIdentifier],
            kCellTitleKey : OALocalizedString(@"shared_string_scale")
        }];
    }
    else if (_terrainType == EOAGPXSettingsTypeWallHeight)
    {
        [topSection addRowFromDictionary:@{
            kCellKeyKey : @"wallHeightSlider",
            kCellTypeKey : [OATitleSliderTableViewCell reuseIdentifier],
            kCellTitleKey : OALocalizedString(@"shared_string_height")
        }];
    }
    else if (_terrainType == EOATerrainSettingsTypeVisibility)
    {
        [topSection addRowFromDictionary:@{
            kCellKeyKey : @"visibilitySlider",
            kCellTypeKey : [OATitleSliderTableViewCell reuseIdentifier],
            kCellTitleKey : OALocalizedString(@"visibility")
        }];
    }
    else if (_terrainType == EOATerrainSettingsTypeZoomLevels || _terrainType == EOATerrainSettingsTypeCoordinatesGridZoomLevels)
    {
        [topSection addRowFromDictionary:@{
            kCellTypeKey : [OAValueTableViewCell reuseIdentifier],
            kCellTitleKey: OALocalizedString(@"rec_interval_minimum"),
            @"value" : @(_minZoom)
        }];
        _minValueIndexPath = [NSIndexPath indexPathForRow:[_data rowCount:[_data sectionCount] - 1] - 1 inSection:[_data sectionCount] - 1];
        if (_openedPickerIndexPath && _openedPickerIndexPath.row == _minValueIndexPath.row + 1)
            [topSection addRowFromDictionary:@{ kCellTypeKey : [OACustomPickerTableViewCell reuseIdentifier] }];

        [topSection addRowFromDictionary:@{
            kCellTypeKey : [OAValueTableViewCell reuseIdentifier],
            kCellTitleKey : OALocalizedString(@"shared_string_maximum"),
            @"value" : @(_maxZoom)
        }];
        _maxValueIndexPath = [NSIndexPath indexPathForRow:[_data rowCount:[_data sectionCount] - 1] - 1 inSection:[_data sectionCount] - 1];
        if (_openedPickerIndexPath && _openedPickerIndexPath.row == _maxValueIndexPath.row + 1)
            [topSection addRowFromDictionary:@{ kCellTypeKey : [OACustomPickerTableViewCell reuseIdentifier] }];
    }
    else if (_terrainType == EOATerrainSettingsTypePalette)
    {
        [topSection addRowFromDictionary:@{
            kCellKeyKey: @"gradientLegend",
            kCellTypeKey: GradientChartCell.reuseIdentifier,
        }];
        _paletteLegendIndexPath = [NSIndexPath indexPathForRow:[topSection rowCount] - 1 inSection:[_data sectionCount] - 1];
        [topSection addRowFromDictionary:@{
            kCellKeyKey: @"paletteName",
            kCellTypeKey: [OASimpleTableViewCell getCellIdentifier],
        }];
        _paletteNameIndexPath = [NSIndexPath indexPathForRow:[topSection rowCount] - 1 inSection:[_data sectionCount] - 1];
        [topSection addRowFromDictionary:@{
            kCellKeyKey: @"colorGrid",
            kCellTypeKey: [OACollectionSingleLineTableViewCell getCellIdentifier]
        }];
        _paletteGridIndexPath = [NSIndexPath indexPathForRow:[topSection rowCount] - 1 inSection:[_data sectionCount] - 1];
        [topSection addRowFromDictionary:@{
            kCellKeyKey: @"allColors",
            kCellTypeKey: [OASimpleTableViewCell getCellIdentifier],
            kCellTitleKey: OALocalizedString(@"shared_string_all_colors"),
            @"tintTitle": [UIColor colorNamed:ACColorNameTextColorActive]
        }];
    }
    else if (_terrainType == EOATerrainSettingsTypeCoordinatesGridColor)
    {
        [topSection addRowFromDictionary:@{
            kCellKeyKey: @"coordinatesGridColor",
            kCellTypeKey: OASimpleTableViewCell.reuseIdentifier,
            kCellTitleKey: OALocalizedString(@"shared_string_color"),
            @"tintTitle": [UIColor colorNamed:ACColorNameTextColorPrimary]
        }];
        [topSection addRowFromDictionary:@{
            kCellKeyKey: @"color_day_night",
            kCellTypeKey: SegmentTextTableViewCell.reuseIdentifier,
        }];
        [topSection addRowFromDictionary:@{
            kCellKeyKey: @"coordinatesGridColors",
            kCellTypeKey: OACollectionSingleLineTableViewCell.reuseIdentifier
        }];
        _colorsCollectionIndexPath = [NSIndexPath indexPathForRow:[topSection rowCount] - 1 inSection:[_data sectionCount] - 1];
        [topSection addRowFromDictionary:@{
            kCellKeyKey: @"allColors",
            kCellTypeKey: [OASimpleTableViewCell getCellIdentifier],
            kCellTitleKey: OALocalizedString(@"shared_string_all_colors"),
            @"tintTitle": [UIColor colorNamed:ACColorNameTextColorActive]
        }];
    }
}

- (void)generateValueForIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath == _minValueIndexPath)
        [[_data itemForIndexPath:indexPath] setObj:@(_minZoom) forKey:@"value"];
    else if (indexPath == _maxValueIndexPath)
        [[_data itemForIndexPath:indexPath] setObj:@(_maxZoom) forKey:@"value"];
}

- (void)setupBottomButton
{
    _applyButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_applyButton setTitle:OALocalizedString(@"shared_string_apply") forState:UIControlStateNormal];
    _applyButton.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
    _applyButton.layer.cornerRadius = 10;
    _applyButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_applyButton addTarget:self action:@selector(onApplyButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self updateApplyButton];
    [self.toolBarView addSubview:_applyButton];

    [NSLayoutConstraint activateConstraints:@[
        [_applyButton.centerXAnchor constraintEqualToAnchor:self.toolBarView.centerXAnchor],
        [_applyButton.topAnchor constraintEqualToAnchor:self.toolBarView.topAnchor],
        [_applyButton.leadingAnchor constraintEqualToAnchor:self.toolBarView.leadingAnchor constant:20.0],
        [_applyButton.trailingAnchor constraintEqualToAnchor:self.toolBarView.trailingAnchor constant:-20.0],
        [_applyButton.heightAnchor constraintEqualToConstant:44.0]
    ]];
}

- (void)updateApplyButton
{
    _applyButton.backgroundColor = _isValueChange ? [UIColor colorNamed:ACColorNameButtonBgColorPrimary] : [UIColor colorNamed:ACColorNameButtonBgColorSecondary];
    [_applyButton setTitleColor: _isValueChange ? [UIColor colorNamed:ACColorNameButtonTextColorPrimary] : [UIColor lightGrayColor] forState:UIControlStateNormal];
    _applyButton.userInteractionEnabled = _isValueChange;
}

- (CGFloat)initialMenuHeight
{
    CGFloat divider = 2.0;
    if (_terrainType == EOATerrainSettingsTypeVerticalExaggeration || _terrainType == EOAGPXSettingsTypeVerticalExaggeration || _terrainType == EOAGPXSettingsTypeWallHeight)
    {
        divider = 2.5;
    }
    else if (_terrainType == EOATerrainSettingsTypeVisibility)
    {
        divider = 3.0;
    }
    return ([OAUtilities calculateScreenHeight] / divider) + [OAUtilities getBottomMargin];
}

- (CGFloat)getToolbarHeight
{
    return 50.;
}

- (BOOL)supportsFullScreen
{
    return NO;
}

- (BOOL)useGestureRecognizer
{
    return NO;
}

- (void)doAdditionalLayout
{
    BOOL isRTL = [self.backButtonContainerView isDirectionRTL];
    CGFloat landscapeWidthAdjusted = [self getLandscapeViewWidth] - [OAUtilities getLeftMargin] + 10.;
    CGFloat commonMargin = [OAUtilities getLeftMargin] + 10.;
    CGFloat defaultPadding = 13.;
    self.backButtonLeadingConstraint.constant = [self isLandscape] ? (isRTL ? defaultPadding : landscapeWidthAdjusted) : commonMargin;
    self.resetButtonTrailingConstraint.constant = [self isLandscape] ? (isRTL ? landscapeWidthAdjusted : defaultPadding) : commonMargin;
}

- (void)hide
{
    if (_terrainType == EOATerrainSettingsTypeVisibility && _baseAlpha != _currentAlpha)
        [_terrainMode setTransparency:_baseAlpha / 0.01];
    else if (_terrainType == EOATerrainSettingsTypeZoomLevels && (_baseMinZoom != _minZoom || _baseMaxZoom != _maxZoom))
        [_terrainMode setZoomValuesWithMinZoom:(int32_t) _baseMinZoom maxZoom:(int32_t) _baseMaxZoom];
    else if (_terrainType == EOATerrainSettingsTypeVerticalExaggeration && _baseVerticalExaggerationScale != _currentVerticalExaggerationScale)
        _app.data.verticalExaggerationScale = _baseVerticalExaggerationScale;
    else if (_terrainType == EOATerrainSettingsTypePalette && ((_basePaletteColorItem && _currentPaletteColorItem && ![_basePaletteColorItem.id isEqualToString:_currentPaletteColorItem.id]) || _isDefaultColorRestored))
        [self setPaletteColorItem:_basePaletteColorItem];
    else if (_terrainType == EOATerrainSettingsTypeCoordinatesGridColor && (![_appearanceCollection isSameColorValue:_baseDayColorItem secondItem:_currentDayColorItem] || ![_appearanceCollection isSameColorValue:_baseNightColorItem secondItem:_currentNightColorItem]))
        [self setCoordinatesGridBaseColorItem];
    else if (_terrainType == EOAGPXSettingsTypeVerticalExaggeration && _baseGPXVerticalExaggerationScale != _currentGPXVerticalExaggerationScale)
        [self applyGPXVerticalExaggerationForScale:_baseGPXVerticalExaggerationScale];
    else if (_terrainType == EOAGPXSettingsTypeWallHeight && _baseGPXElevationMeters != _currentGPXElevationMeters)
        [self applyGPXElevationMeters:_baseGPXElevationMeters];
    else if (_terrainType == EOATerrainSettingsTypeCoordinatesGridZoomLevels && (_baseMinZoom != _minZoom || _baseMaxZoom != _maxZoom))
        [self setCoordinatesGridZoomValuesWithMinZoom:_baseMinZoom maxZoom:_baseMaxZoom];

    __weak __typeof(self) weakSelf = self;
    [self hide:YES duration:.2 onComplete:^{
        if (weakSelf.delegate)
            [weakSelf.delegate onBackTerrainParameters];
        if (weakSelf.hideCallback)
            weakSelf.hideCallback();
    }];
}

- (void)hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete
{
    __weak __typeof(self) weakSelf = self;
    [super hide:YES duration:duration onComplete:^{
        if (weakSelf.terrainType == EOATerrainSettingsTypeCoordinatesGridColor)
            [[OADayNightHelper instance] resetTempMode];
        [weakSelf.mapPanel hideScrollableHudViewController];
        if (onComplete)
            onComplete();
    }];
}

#pragma mark - Additions

- (BOOL)resetVisibilityValues
{
    CGFloat defaultAlpha = ([_terrainMode isHillshade] ? hillshadeDefaultTrasparency : defaultTrasparency) * 0.01;
    if (_currentAlpha != defaultAlpha)
    {
        _currentAlpha = defaultAlpha;
        [_terrainMode setTransparency:defaultAlpha / 0.01];
        _isValueChange = _baseAlpha != _currentAlpha;
        [self updateApplyButton];
        return YES;
    }
    return NO;
}

- (BOOL)resetZoomLevels
{
    NSInteger defaultMinZoom = _terrainType == EOATerrainSettingsTypeCoordinatesGridZoomLevels ? [_coordinatesGridSettings getSupportedZoomLevels].min : terrainMinSupportedZoom;
    NSInteger defaultMaxZoom = _terrainType == EOATerrainSettingsTypeCoordinatesGridZoomLevels ? [_coordinatesGridSettings getSupportedZoomLevels].max : terrainMaxSupportedZoom;
    if (_minZoom != defaultMinZoom || _maxZoom != defaultMaxZoom)
    {
        _minZoom = defaultMinZoom;
        _maxZoom = defaultMaxZoom;
        if (_terrainType == EOATerrainSettingsTypeCoordinatesGridZoomLevels)
            [self setCoordinatesGridZoomValuesWithMinZoom:_minZoom maxZoom:_maxZoom];
        else
            [_terrainMode setZoomValuesWithMinZoom:(int32_t)_minZoom maxZoom:(int32_t)_maxZoom];

        _isValueChange = _baseMinZoom != _minZoom || _baseMaxZoom != _maxZoom;
        [self updateApplyButton];
        return YES;
    }
    return NO;
}

- (BOOL)resetPalette
{
    if (_paletteGridIndexPath)
    {
        OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:_paletteGridIndexPath];
        if (colorCell)
        {
            NSIndexPath *defaultIndexPath = [[colorCell getCollectionHandler] getDefaultIndexPath];
            if (defaultIndexPath && ![defaultIndexPath isEqual:[[colorCell getCollectionHandler] getSelectedIndexPath]])
            {
                [[colorCell getCollectionHandler] onItemSelected:defaultIndexPath
                                                  collectionView:colorCell.collectionView];
                return YES;
            }
        }
    }
    return NO;
}

- (BOOL)resetCoordinatesGridColor
{
    if (!_colorsCollectionIndexPath)
        return NO;

    NSInteger defDay = _settings.coordinatesGridColorDay.defValue;
    NSInteger defNight = _settings.coordinatesGridColorNight.defValue;
    if (_currentDayColorItem.colorInt == defDay && _currentNightColorItem.colorInt == defNight)
        return NO;

    _currentDayColorItem = [_appearanceCollection getColorItemWithValue:(int)defDay] ?: [_appearanceCollection defaultLineColorItem];
    _currentNightColorItem = [_appearanceCollection getColorItemWithValue:(int)defNight] ?: [_appearanceCollection defaultLineColorItem];
    [self applyCoordinatesGridColor];
    OACollectionSingleLineTableViewCell *colorCell = (OACollectionSingleLineTableViewCell *)[self.tableView cellForRowAtIndexPath:_colorsCollectionIndexPath];
    if (colorCell)
    {
        OAColorCollectionHandler *handler = (OAColorCollectionHandler *)[colorCell getCollectionHandler];
        NSInteger idx = [_appearanceCollection indexOfColorItem:_isNightCoordinatesGridColorMode ? _currentNightColorItem : _currentDayColorItem items:_sortedColorItems];
        if (idx != NSNotFound)
        {
            NSIndexPath *path = [NSIndexPath indexPathForRow:(NSInteger)idx inSection:0];
            [handler onItemSelected:path collectionView:colorCell.collectionView];
        }
    }

    _isValueChange = ![_appearanceCollection isSameColorValue:_baseDayColorItem secondItem:_currentDayColorItem] || ![_appearanceCollection isSameColorValue:_baseNightColorItem secondItem:_currentNightColorItem];
    [self updateApplyButton];
    return YES;
}

- (void)refreshColorsCollection
{
    if (_terrainType == EOATerrainSettingsTypeCoordinatesGridColor && (_colorsCollectionIndexPath && _colorsCollectionIndexPath.section < [self.tableView numberOfSections] && _colorsCollectionIndexPath.row < [self.tableView numberOfRowsInSection:_colorsCollectionIndexPath.section]))
    {
        _sortedColorItems = [NSMutableArray arrayWithArray:[_appearanceCollection getAvailableColorsSortingByLastUsed]];
        [self.tableView reloadRowsAtIndexPaths:@[_colorsCollectionIndexPath] withRowAnimation:UITableViewRowAnimationNone];
        OACollectionSingleLineTableViewCell *colorCell = (OACollectionSingleLineTableViewCell *) [self.tableView cellForRowAtIndexPath:_colorsCollectionIndexPath];
        if (!colorCell)
            return;

        NSIndexPath *selectedIndexPath = [[colorCell getCollectionHandler] getSelectedIndexPath];
        if (selectedIndexPath && selectedIndexPath.row != NSNotFound && ![colorCell.collectionView.indexPathsForVisibleItems containsObject:selectedIndexPath])
            [colorCell.collectionView scrollToItemAtIndexPath:selectedIndexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:NO];
    }
}

- (BOOL)resetGPXVerticalExaggerationValues
{
    double scale = 0.25;
    if (_currentGPXVerticalExaggerationScale != scale)
    {
        _currentGPXVerticalExaggerationScale = scale;
        _isValueChange = _baseGPXVerticalExaggerationScale != _currentGPXVerticalExaggerationScale;
        [self applyGPXVerticalExaggerationForScale:_currentGPXVerticalExaggerationScale];
        [self updateApplyButton];
        return YES;
    }
    return NO;
}

- (BOOL)resetGPXElevationMetersValues
{
    if (_currentGPXElevationMeters != kElevationDefMeters)
    {
        _currentGPXElevationMeters = kElevationDefMeters;
        _isValueChange = _baseGPXElevationMeters != _currentGPXElevationMeters;
        [self applyGPXElevationMeters:_currentGPXElevationMeters];
        [self updateApplyButton];
        return YES;
    }
    return NO;
}

- (void)applyGPXVerticalExaggerationForScale:(CGFloat)scale
{
    if (self.applyCallback)
        self.applyCallback(scale);
}

- (void)applyGPXElevationMeters:(NSInteger)meters
{
    if (self.applyWallHeightCallback)
        self.applyWallHeightCallback(meters);
}

- (BOOL)resetVerticalExaggerationValues
{
    if (_currentVerticalExaggerationScale != kExaggerationDefScale)
    {
        _currentVerticalExaggerationScale = kExaggerationDefScale;
        _isValueChange = _baseVerticalExaggerationScale != _currentVerticalExaggerationScale;
        [self applyVerticalExaggerationScale];
        [self updateApplyButton];
        return YES;
    }
    return NO;
}

- (void)applyCurrentVisibility
{
    [_terrainMode setTransparency:_currentAlpha / 0.01];
}

- (void)applyCurrentZoomLevels
{
    if (_terrainType == EOATerrainSettingsTypeCoordinatesGridZoomLevels)
        [_coordinatesGridSettings setZoomLevels:{ .min = _minZoom, .max = _maxZoom } forAppMode:[_settings.applicationMode get]];
    else
        [_terrainMode setZoomValuesWithMinZoom:(int32_t)_minZoom maxZoom:(int32_t)_maxZoom];
}

- (void)applyVerticalExaggerationScale
{
    _app.data.verticalExaggerationScale = _currentVerticalExaggerationScale;
}

- (void)applyPalette
{
    [self setPaletteColorItem:_currentPaletteColorItem];
}

- (void)applyCoordinatesGridColor
{
    [_coordinatesGridSettings setGridColor:(int)_currentDayColorItem.colorInt forAppMode:[_settings.applicationMode get] nightMode:NO];
    [_coordinatesGridSettings setGridColor:(int)_currentNightColorItem.colorInt forAppMode:[_settings.applicationMode get] nightMode:YES];
}

- (NSArray<NSString *> *)getPossibleZoomValues
{
    NSInteger minZoom = _terrainType == EOATerrainSettingsTypeCoordinatesGridZoomLevels ? [_coordinatesGridSettings getSupportedZoomLevels].min : terrainMinSupportedZoom;
    NSInteger maxZoom = _terrainType == EOATerrainSettingsTypeCoordinatesGridZoomLevels ? [_coordinatesGridSettings getSupportedZoomLevels].max : terrainMaxSupportedZoom;

    NSMutableArray *res = [NSMutableArray new];
    for (NSInteger zoomLevel = minZoom; zoomLevel <= maxZoom; zoomLevel++)
    {
        [res addObject:[NSString stringWithFormat:@"%ld", zoomLevel]];
    }
    return res;
}

- (void)setPaletteColorItem:(OASPaletteItemGradient *)paletteColor
{
    if (paletteColor)
    {
        TerrainMode *mode = [TerrainMode getMode:_terrainMode.type keyName:paletteColor.id];
        if (mode)
        {
            _terrainMode = mode;
            [_plugin setTerrainMode:mode];
            [self updateApplyButton];
        }
    }
}

- (void)setCoordinatesGridBaseColorItem
{
    [_coordinatesGridSettings setGridColor:(int)_baseDayColorItem.colorInt forAppMode:[_settings.applicationMode get] nightMode:NO];
    [_coordinatesGridSettings setGridColor:(int)_baseNightColorItem.colorInt forAppMode:[_settings.applicationMode get] nightMode:YES];
}

- (void)setCoordinatesGridZoomValuesWithMinZoom:(NSInteger)baseMinZoom maxZoom:(NSInteger)baseMaxZoom
{
    [_coordinatesGridSettings setZoomLevels:{ .min = baseMinZoom, .max = baseMaxZoom } forAppMode:[_settings.applicationMode get]];
}

#pragma mark - Selectors

- (IBAction)backButtonPressed:(UIButton *)sender
{
    [self hide];
}

- (IBAction)resetButtonPressed:(UIButton *)sender
{
    BOOL wasReset = NO;
    if (_terrainType == EOATerrainSettingsTypeVisibility)
        wasReset = [self resetVisibilityValues];
    else if (_terrainType == EOATerrainSettingsTypeZoomLevels || _terrainType == EOATerrainSettingsTypeCoordinatesGridZoomLevels)
        wasReset = [self resetZoomLevels];
    else if (_terrainType == EOATerrainSettingsTypeVerticalExaggeration)
        wasReset = [self resetVerticalExaggerationValues];
    else if (_terrainType == EOATerrainSettingsTypePalette)
        wasReset = [self resetPalette];
    else if (_terrainType == EOATerrainSettingsTypeCoordinatesGridColor)
        wasReset = [self resetCoordinatesGridColor];
    else if (_terrainType == EOAGPXSettingsTypeVerticalExaggeration)
        wasReset = [self resetGPXVerticalExaggerationValues];
    else if (_terrainType == EOAGPXSettingsTypeWallHeight)
        wasReset = [self resetGPXElevationMetersValues];

    if (wasReset)
    {
        [self generateData];
        [self.tableView reloadData];
    }
}

- (void)onApplyButtonPressed
{
    if (_terrainType == EOATerrainSettingsTypeVisibility && _currentAlpha != [_terrainMode getTransparency] * 0.01)
        [self applyCurrentVisibility];
    else if (_terrainType == EOATerrainSettingsTypeZoomLevels && (_minZoom != [_terrainMode getMinZoom] || _maxZoom != [_terrainMode getMaxZoom]))
        [self applyCurrentZoomLevels];
    else if (_terrainType == EOATerrainSettingsTypeCoordinatesGridZoomLevels && (_minZoom != [_coordinatesGridSettings getZoomLevels].min || _maxZoom != [_coordinatesGridSettings getZoomLevels].max))
        [self applyCurrentZoomLevels];
    else if (_terrainType == EOATerrainSettingsTypeVerticalExaggeration && _currentVerticalExaggerationScale != _app.data.verticalExaggerationScale)
        [self applyVerticalExaggerationScale];
    else if (_terrainType == EOATerrainSettingsTypePalette && _currentPaletteColorItem && _isValueChange)
        [self applyPalette];
    else if (_terrainType == EOATerrainSettingsTypeCoordinatesGridColor)
        [self applyCoordinatesGridColor];
    else if (_terrainType == EOAGPXSettingsTypeVerticalExaggeration && _baseGPXVerticalExaggerationScale != _currentGPXVerticalExaggerationScale)
        [self applyGPXVerticalExaggerationForScale:_currentGPXVerticalExaggerationScale];
    else if (_terrainType == EOAGPXSettingsTypeWallHeight && _baseGPXElevationMeters != _currentGPXElevationMeters)
        [self applyGPXElevationMeters:_currentGPXElevationMeters];

    if (_terrainType == EOATerrainSettingsTypePalette && _currentPaletteColorItem)
    {
        [[GradientPaletteHelper shared] markPaletteItemAsUsed:_currentPaletteColorItem];
    }
    else if (_terrainType == EOATerrainSettingsTypeCoordinatesGridColor)
    {
        if (_isNightCoordinatesGridColorMode)
        {
            [_appearanceCollection selectColor:_currentDayColorItem];
            [_appearanceCollection selectColor:_currentNightColorItem];
        }
        else
        {
            [_appearanceCollection selectColor:_currentNightColorItem];
            [_appearanceCollection selectColor:_currentDayColorItem];
        }
    }

    __weak __typeof(self) weakSelf = self;
    [self hide:YES duration:.2 onComplete:^{
        if (weakSelf.delegate)
            [weakSelf.delegate onBackTerrainParameters];
        if (weakSelf.hideCallback)
            weakSelf.hideCallback();
    }];
}

- (void)sliderValueChanged:(UISlider *)slider
{
    if (_terrainType == EOATerrainSettingsTypeVerticalExaggeration)
    {
        _currentVerticalExaggerationScale = slider.value;
        _app.data.verticalExaggerationScale = _currentVerticalExaggerationScale;
        _isValueChange = _baseVerticalExaggerationScale != _currentVerticalExaggerationScale;
        [self updateApplyButton];
        return;
    }
    if (_terrainType == EOAGPXSettingsTypeVerticalExaggeration)
    {
        CGFloat step = 0.1;
        CGFloat roundedValue = slider.value >= 1.0 ? round(slider.value / step) * step : slider.value;
        if (_currentGPXVerticalExaggerationScale != roundedValue)
        {
            _currentGPXVerticalExaggerationScale = roundedValue;
            _isValueChange = _baseGPXVerticalExaggerationScale != _currentGPXVerticalExaggerationScale;
            [self applyGPXVerticalExaggerationForScale:_currentGPXVerticalExaggerationScale];
            [self updateApplyButton];
        }
        return;
    }
    if (_terrainType == EOAGPXSettingsTypeWallHeight)
    {
        NSInteger value = (NSInteger)slider.value;
        if (_currentGPXElevationMeters != value)
        {
            _currentGPXElevationMeters = value;
            _isValueChange = _baseGPXElevationMeters != _currentGPXElevationMeters;
            [self applyGPXElevationMeters:_currentGPXElevationMeters];
            [self updateApplyButton];
        }
        return;
    }

    _currentAlpha = slider.value;
    [_terrainMode setTransparency:_currentAlpha / 0.01];

    _isValueChange = _baseAlpha != _currentAlpha;
    [self updateApplyButton];
}

- (void)segmentChanged:(NSInteger)index
{
    _isNightCoordinatesGridColorMode = index == 1;
    [[OADayNightHelper instance] setTempMode:_isNightCoordinatesGridColorMode ? DayNightModeNight : DayNightModeDay];
    [self refreshColorsCollection];
}

- (void)onColorCellButtonPressed:(UIButton *)sender
{
    UIColorPickerViewController *colorViewController = [[UIColorPickerViewController alloc] init];
    colorViewController.delegate = self;
    OASPaletteItemSolid *activeItem = _isNightCoordinatesGridColorMode ? _currentNightColorItem : _currentDayColorItem;
    colorViewController.selectedColor = activeItem ? UIColorFromARGB(activeItem.colorInt) : UIColor.clearColor;
    [self.navigationController presentViewController:colorViewController animated:YES completion:nil];
}

- (void)onPaletteCellButtonPressed:(UIButton *)sender
{
    OASGradientPaletteCategory *paletteCategory = [TerrainTypeWrapper toPaletteCategoryWithType:_terrainMode.type];
    [[GradientPaletteHelper shared] showAddPaletteEditorFrom:self paletteCategory:paletteCategory sourceView:sender];
}

- (NSString *)sliderValueString:(float)value
{
    if (_terrainType == EOATerrainSettingsTypeVerticalExaggeration)
    {
        return value <= 1 ? OALocalizedString(@"shared_string_none") : [NSString stringWithFormat:@"x%.1f", value];
    }
    else if (_terrainType == EOAGPXSettingsTypeVerticalExaggeration)
    {
        return value <= 0.25 ? OALocalizedString(@"shared_string_none") : (value < 1.0 ? [NSString stringWithFormat:@"x%.2f", value] : [NSString stringWithFormat:@"x%.1f", value]);
    }
    else
    {
        return [NSString stringWithFormat:@"%ld %@", (NSInteger)value, OALocalizedString(@"m")];
    }
}

#pragma mark - UITableViewDataSource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [_data sectionDataForIndex:section].headerText;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return [_data sectionDataForIndex:section].footerText;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [_data sectionCount];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_data rowCount:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.cellType isEqualToString:[OATitleSliderTableViewCell reuseIdentifier]])
    {
        OATitleSliderTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OATitleSliderTableViewCell reuseIdentifier]];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.sliderView.minimumTrackTintColor = [UIColor colorNamed:ACColorNameIconColorActive];
        cell.titleLabel.text = item.title;
        if (_terrainType == EOATerrainSettingsTypeVerticalExaggeration || _terrainType == EOAGPXSettingsTypeVerticalExaggeration)
        {
            __weak OATitleSliderTableViewCell *weakCell = cell;
            __weak __typeof(self) weakSelf = self;
            cell.updateValueCallback = ^(float value) {
                weakCell.valueLabel.text = [weakSelf sliderValueString:value];
            };
            cell.sliderView.minimumValue = _terrainType == EOATerrainSettingsTypeVerticalExaggeration ? 1 : 0.25;
            cell.sliderView.maximumValue = _terrainType == EOATerrainSettingsTypeVerticalExaggeration ? 3 : 4;
            cell.sliderView.value = _terrainType == EOATerrainSettingsTypeVerticalExaggeration
            ? _app.data.verticalExaggerationScale
            : _currentGPXVerticalExaggerationScale;

            cell.valueLabel.text = [self sliderValueString:cell.sliderView.value];
        }
        else if (_terrainType == EOAGPXSettingsTypeWallHeight)
        {
            __weak OATitleSliderTableViewCell *weakCell = cell;
            __weak __typeof(self) weakSelf = self;
            cell.updateValueCallback = ^(float value) {
                weakCell.valueLabel.text = [weakSelf sliderValueString:value];
            };
            cell.sliderView.minimumValue = kElevationMinMeters;
            cell.sliderView.maximumValue = kElevationMaxMeters;
            cell.sliderView.value = _currentGPXElevationMeters;
            cell.valueLabel.text = [self sliderValueString:cell.sliderView.value];
        }
        else
        {
            cell.updateValueCallback = nil;
            NSInteger transparency = [[((OASRTMPlugin *) [OAPluginsHelper getPlugin:OASRTMPlugin.class]) getTerrainMode] getTransparency];
            cell.sliderView.value = transparency * 0.01;
            cell.valueLabel.text = [NSString stringWithFormat:@"%ld%%", transparency];
        }

        [cell.sliderView removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
        [cell.sliderView addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        return cell;
    }
    else if ([item.cellType isEqualToString:[OAValueTableViewCell reuseIdentifier]])
    {
        OAValueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell reuseIdentifier]];
        [cell leftIconVisibility:NO];
        [cell descriptionVisibility:NO];
        cell.valueLabel.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.titleLabel.text = item.title;
        cell.valueLabel.text = [item stringForKey:@"value"];
        return cell;
    }
    else if ([item.cellType isEqualToString:[OACustomPickerTableViewCell reuseIdentifier]])
    {
        OACustomPickerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OACustomPickerTableViewCell reuseIdentifier]];
        cell.dataArray = _possibleZoomValues;
        NSInteger baseMinZoom = _terrainType == EOATerrainSettingsTypeCoordinatesGridZoomLevels ? [_coordinatesGridSettings getSupportedZoomLevels].min : terrainMinSupportedZoom;
        NSInteger baseMaxZoom = _terrainType == EOATerrainSettingsTypeCoordinatesGridZoomLevels ? [_coordinatesGridSettings getSupportedZoomLevels].max : terrainMaxSupportedZoom;
        NSInteger minZoom = _minZoom >= baseMinZoom && _minZoom <= baseMaxZoom ? (_minZoom - baseMinZoom) : 1;
        NSInteger maxZoom = _maxZoom >= baseMinZoom && _maxZoom <= baseMaxZoom ? (_maxZoom - baseMinZoom) : 1;
        [cell.picker selectRow:indexPath.row == 1 ? minZoom : maxZoom inComponent:0 animated:NO];
        cell.picker.tag = indexPath.row;
        cell.delegate = self;
        return cell;
    }
    else if ([item.cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        [cell leftIconVisibility:NO];
        [cell descriptionVisibility:NO];
        BOOL isPaletteName = [item.key isEqualToString:@"paletteName"];
        BOOL isCoordinatesGridColor = [item.key isEqualToString:@"coordinatesGridColor"];
        [cell setCustomLeftSeparatorInset:isCoordinatesGridColor];
        cell.separatorInset = UIEdgeInsetsMake(0., CGFLOAT_MAX, 0., 0.);
        cell.selectionStyle = isPaletteName || isCoordinatesGridColor ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleDefault;
        cell.titleLabel.text = isPaletteName ? _currentPaletteColorItem.displayName : item.title;
        cell.titleLabel.textColor = [item objForKey:@"tintTitle"] ?: UIColorFromRGB(color_extra_text_gray);
        cell.titleLabel.font = [UIFont preferredFontForTextStyle:isPaletteName ? UIFontTextStyleFootnote : UIFontTextStyleBody];
        return cell;
    }
    else if ([item.cellType isEqualToString:OACollectionSingleLineTableViewCell.reuseIdentifier])
    {
        OACollectionSingleLineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:OACollectionSingleLineTableViewCell.reuseIdentifier];
        BOOL isCoordinatesGridColors = [item.key isEqualToString:@"coordinatesGridColors"];
        BOOL isPaletteGrid = [item.key isEqualToString:@"colorGrid"];
        BOOL isRightActionButtonVisible = isCoordinatesGridColors || (isPaletteGrid && ![_terrainMode isHillshade]);
        [cell rightActionButtonVisibility:isRightActionButtonVisible];
        [cell.rightActionButton setImage:isRightActionButtonVisible ? [UIImage templateImageNamed:ACImageNameIcCustomAdd] : nil forState:UIControlStateNormal];
        cell.rightActionButton.tag = isRightActionButtonVisible ? (indexPath.section << 10 | indexPath.row) : 0;
        cell.rightActionButton.accessibilityLabel = isRightActionButtonVisible ? OALocalizedString(isCoordinatesGridColors ? @"shared_string_add_color" : @"add_palette") : nil;
        [cell.rightActionButton removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
        if (isCoordinatesGridColors)
        {
            OAColorCollectionHandler *colorHandler = [[OAColorCollectionHandler alloc] initWithData:@[_sortedColorItems] collectionView:cell.collectionView];
            colorHandler.delegate = self;
            colorHandler.hostVC = self;
            OASPaletteItemSolid *activeItem = _isNightCoordinatesGridColorMode ? _currentNightColorItem : _currentDayColorItem;
            NSInteger selectedIndex = [_appearanceCollection indexOfColorItem:activeItem items:_sortedColorItems];
            if (selectedIndex != NSNotFound)
                [colorHandler setSelectedIndexPath:[NSIndexPath indexPathForRow:selectedIndex inSection:0]];
            [cell setCollectionHandler:colorHandler];
            [cell.rightActionButton addTarget:self action:@selector(onColorCellButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        else
        {
            [cell.collectionView registerNib:[UINib nibWithNibName:PaletteCollectionViewCell.reuseIdentifier bundle:nil] forCellWithReuseIdentifier:PaletteCollectionViewCell.reuseIdentifier];
            PaletteCollectionHandler *paletteHandler = [[PaletteCollectionHandler alloc] initWithData:@[[_sortedPaletteColorItems asArray]] collectionView:cell.collectionView];
            paletteHandler.delegate = self;
            NSInteger selectedIndex = [[GradientPaletteHelper shared] indexOf:_currentPaletteColorItem in:[_sortedPaletteColorItems asArray]];
            if (selectedIndex == NSNotFound)
                selectedIndex = 0;
            NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:selectedIndex inSection:0];
            [paletteHandler setSelectedIndexPath:selectedIndexPath];
            [cell setCollectionHandler:paletteHandler];
            if (isRightActionButtonVisible)
                [cell.rightActionButton addTarget:self action:@selector(onPaletteCellButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            cell.collectionView.contentInset = UIEdgeInsetsMake(0, 10, 0, 0);
            [cell configureTopOffset:12];
            [cell configureBottomOffset:12];
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:GradientChartCell.reuseIdentifier])
    {
        GradientChartCell *cell = (GradientChartCell *) [tableView dequeueReusableCellWithIdentifier:GradientChartCell.reuseIdentifier
                                                                                        forIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.separatorInset = UIEdgeInsetsMake(0, CGFLOAT_MAX, 0, 0);
        cell.heightConstraint.constant = 80;
        cell.chartView.extraTopOffset = 20;
        cell.chartView.extraBottomOffset = 24;

        [GpxUIHelper setupGradientChartWithChart:cell.chartView
                             useGesturesAndScale:NO
                                  xAxisGridColor:[UIColor colorNamed:ACColorNameChartAxisGridLine]
                                     labelsColor:[UIColor colorNamed:ACColorNameChartTextColorAxisX]];

        OASColorPalette *colorPalette = [_currentPaletteColorItem getColorPalette];
        OASGradientPaletteCategory *paletteCategory = [TerrainTypeWrapper toPaletteCategoryWithType:_terrainMode.type];
        if (!colorPalette || !paletteCategory)
            return cell;

        cell.chartView.data = [GpxUIHelper buildGradientChartWithChart:cell.chartView colorPalette:colorPalette valueFormatter:[GradientFormatter getAxisFormatterWithPaletteCategory:paletteCategory]];
        [cell.chartView notifyDataSetChanged];
        [cell.chartView setNeedsDisplay];
        return cell;
    }
    else if ([item.cellType isEqualToString:SegmentTextTableViewCell.reuseIdentifier])
    {
        SegmentTextTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SegmentTextTableViewCell.reuseIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
        cell.separatorInset = UIEdgeInsetsMake(0., CGFLOAT_MAX, 0., 0.);
        [cell setSegmentedControlBottomSpacing:8.0];
        [cell configureSegmentedControlWithTitles:@[OALocalizedString(@"day"), OALocalizedString(@"daynight_mode_night")] selectedSegmentIndex:_settings.nightMode ? 1 : 0 selectedTitles:nil];
        __weak __typeof(self) weakSelf = self;
        cell.didSelectSegmentIndex = ^(NSInteger idx) {
            [weakSelf segmentChanged:idx];
        };
        return cell;
    }
    return nil;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if (indexPath == _minValueIndexPath || indexPath == _maxValueIndexPath)
    {
        [self.tableView beginUpdates];
        NSIndexPath *newPickerIndexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
        if (newPickerIndexPath == _openedPickerIndexPath)
        {
            [self.tableView deleteRowsAtIndexPaths:@[_openedPickerIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            _openedPickerIndexPath = nil;
        }
        else
        {
            if (_openedPickerIndexPath)
            {
                if (_openedPickerIndexPath.row < newPickerIndexPath.row)
                    newPickerIndexPath = [NSIndexPath indexPathForRow:newPickerIndexPath.row - 1 inSection:newPickerIndexPath.section];

                [self.tableView deleteRowsAtIndexPaths:@[_openedPickerIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                [self.tableView insertRowsAtIndexPaths:@[newPickerIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                _openedPickerIndexPath = newPickerIndexPath;
            }
            else
            {
                [self.tableView insertRowsAtIndexPaths:@[newPickerIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                _openedPickerIndexPath = newPickerIndexPath;
            }
        }
        [self generateData];

        [self.tableView endUpdates];
        [self.tableView scrollToRowAtIndexPath:_minValueIndexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    else if ([item.key isEqualToString:@"allColors"])
    {
        ItemsCollectionViewController *colorCollectionViewController;
        if (_terrainType == EOATerrainSettingsTypePalette)
        {
            colorCollectionViewController = [[ItemsCollectionViewController alloc] initWithCollectionType:ColorCollectionTypeTerrainPaletteItems items:[_sortedPaletteColorItems asArray] selectedItem:_currentPaletteColorItem];
        }
        else if (_terrainType == EOATerrainSettingsTypeCoordinatesGridColor)
        {
            NSArray<OASPaletteItemSolid *> *allColors = [_appearanceCollection getAvailableColorsSortingByLastUsed];
            OASPaletteItemSolid *selected = _isNightCoordinatesGridColorMode ? _currentNightColorItem : _currentDayColorItem;
            colorCollectionViewController = [[ItemsCollectionViewController alloc] initWithCollectionType:ColorCollectionTypeColorItems items:allColors selectedItem:selected];
            OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:_colorsCollectionIndexPath];
            OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];
            colorCollectionViewController.hostColorHandler = colorHandler;
        }

        colorCollectionViewController.delegate = self;
        [self.navigationController pushViewController:colorCollectionViewController animated:YES];
    }
}

#pragma mark - OACustomPickerTableViewCellDelegate

- (void)resetPickerValue:(NSInteger)zoomValue
{
    if (_openedPickerIndexPath)
    {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:_openedPickerIndexPath];
        if ([cell isKindOfClass:OACustomPickerTableViewCell.class])
        {
            OACustomPickerTableViewCell *pickerCell = (OACustomPickerTableViewCell *) cell;
            [pickerCell.picker selectRow:zoomValue - 1 inComponent:0 animated:YES];
        }
    }
}

- (void)customPickerValueChanged:(NSString *)value tag:(NSInteger)pickerTag
{
    NSIndexPath *zoomValueIndexPath;
    NSInteger intValue = [value integerValue];
    if (pickerTag == kMinZoomPickerRow)
    {
        zoomValueIndexPath = _minValueIndexPath;
        if (intValue <= _maxZoom)
        {
            _minZoom = intValue;
            [self applyCurrentZoomLevels];
        }
        else
        {
            _minZoom = _maxZoom;
            [self resetPickerValue:_maxZoom];
        }
    }
    else if (pickerTag == kMaxZoomPickerRow)
    {
        zoomValueIndexPath = _maxValueIndexPath;
        if (intValue >= _minZoom)
        {
            _maxZoom = intValue;
            [self applyCurrentZoomLevels];
        }
        else
        {
            _maxZoom = _minZoom;
            [self resetPickerValue:_minZoom];
        }
    }

    if (zoomValueIndexPath)
    {
        [self generateValueForIndexPath:zoomValueIndexPath];
        [self.tableView reloadRowsAtIndexPaths:@[zoomValueIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        _isValueChange = _baseMinZoom != _minZoom || _baseMaxZoom != _maxZoom;
        [self updateApplyButton];
    }
}

#pragma mark - OACollectionCellDelegate

- (void)onCollectionItemSelected:(NSIndexPath *)indexPath selectedItem:(id)selectedItem collectionView:(UICollectionView *)collectionView shouldDismiss:(BOOL)shouldDismiss
{
    if (_terrainType == EOATerrainSettingsTypePalette)
    {
        OASPaletteItemGradient *picked = [selectedItem isKindOfClass:OASPaletteItemGradient.class] ? (OASPaletteItemGradient *) selectedItem : [_sortedPaletteColorItems objectAtIndexSync:indexPath.row];
        if (!picked)
            return;

        _currentPaletteColorItem = picked;
        _isValueChange = ![_basePaletteColorItem.id isEqualToString:_currentPaletteColorItem.id];
        [self setPaletteColorItem:_currentPaletteColorItem];
        NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray array];
        if (_paletteNameIndexPath)
            [indexPaths addObject:_paletteNameIndexPath];
        if (_paletteLegendIndexPath)
            [indexPaths addObject:_paletteLegendIndexPath];
        if (indexPaths.count > 0)
            [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
    }
    else if (_terrainType == EOATerrainSettingsTypeCoordinatesGridColor)
    {
        if (indexPath.row < 0 || indexPath.row >= _sortedColorItems.count)
            return;

        OASPaletteItemSolid *picked = [selectedItem isKindOfClass:OASPaletteItemSolid.class] ? (OASPaletteItemSolid *) selectedItem : _sortedColorItems[indexPath.row];
        if ([selectedItem isKindOfClass:OASPaletteItemSolid.class])
            _sortedColorItems[indexPath.row] = picked;
        if (_isNightCoordinatesGridColorMode)
        {
            _currentNightColorItem = picked;
            [_coordinatesGridSettings setGridColor:(int)_currentNightColorItem.colorInt forAppMode:[_settings.applicationMode get] nightMode:YES];
        }
        else
        {
            _currentDayColorItem = picked;
            [_coordinatesGridSettings setGridColor:(int)_currentDayColorItem.colorInt forAppMode:[_settings.applicationMode get] nightMode:NO];
        }

        OACollectionSingleLineTableViewCell *cell = (OACollectionSingleLineTableViewCell *)[self.tableView cellForRowAtIndexPath:_colorsCollectionIndexPath];
        OAColorCollectionHandler *handler = (OAColorCollectionHandler *)[cell getCollectionHandler];
        [handler setSelectedIndexPath:indexPath];
        _isValueChange = ![_appearanceCollection isSameColorValue:_currentDayColorItem secondItem:_baseDayColorItem] || ![_appearanceCollection isSameColorValue:_currentNightColorItem secondItem:_baseNightColorItem];
        [self updateApplyButton];
    }
}

- (void)reloadCollectionData
{
    _currentDayColorItem = [_appearanceCollection getColorItemWithValue:[_coordinatesGridSettings getDayGridColor]] ?: [_appearanceCollection defaultLineColorItem];
    _currentNightColorItem = [_appearanceCollection getColorItemWithValue:[_coordinatesGridSettings getNightGridColor]] ?: [_appearanceCollection defaultLineColorItem];
    _sortedColorItems = [NSMutableArray arrayWithArray:[_appearanceCollection getAvailableColorsSortingByLastUsed]];
}

#pragma mark - ColorCollectionViewControllerDelegate

- (void)reloadData
{
    if (_terrainType != EOATerrainSettingsTypePalette)
        return;

    OASGradientPaletteCategory *paletteCategory = [TerrainTypeWrapper toPaletteCategoryWithType:_terrainMode.type];
    if (!paletteCategory)
        return;

    [_sortedPaletteColorItems replaceAllWithObjectsSync:[[GradientPaletteHelper shared] paletteItemsWithCategory:paletteCategory sortMode:OASPaletteSortMode.lastUsedTime]];
    if ([[GradientPaletteHelper shared] indexOf:_currentPaletteColorItem in:[_sortedPaletteColorItems asArray]] == NSNotFound)
    {
        _currentPaletteColorItem = [[GradientPaletteHelper shared] defaultPaletteItemWithCategory:paletteCategory] ?: [_sortedPaletteColorItems firstObjectSync];
        _basePaletteColorItem = _currentPaletteColorItem;
        _isDefaultColorRestored = YES;
        _isValueChange = NO;
        [self setPaletteColorItem:_currentPaletteColorItem];
        [self updateApplyButton];
    }

    NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray array];
    if (_paletteGridIndexPath)
        [indexPaths addObject:_paletteGridIndexPath];
    if (_paletteNameIndexPath)
        [indexPaths addObject:_paletteNameIndexPath];
    if (_paletteLegendIndexPath)
        [indexPaths addObject:_paletteLegendIndexPath];
    if (indexPaths.count > 0)
        [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
}

- (void)selectPaletteItem:(OASPaletteItemGradient *)paletteItem
{
    OASGradientPaletteCategory *paletteCategory = [TerrainTypeWrapper toPaletteCategoryWithType:_terrainMode.type];
    if (paletteCategory)
        [_sortedPaletteColorItems replaceAllWithObjectsSync:[[GradientPaletteHelper shared] paletteItemsWithCategory:paletteCategory sortMode:OASPaletteSortMode.lastUsedTime]];
    NSInteger row = [[GradientPaletteHelper shared] indexOf:paletteItem in:[_sortedPaletteColorItems asArray]];
    if (row != NSNotFound)
        [self onCollectionItemSelected:[NSIndexPath indexPathForRow:row inSection:0] selectedItem:paletteItem collectionView:nil shouldDismiss:YES];
}

- (void)selectColorItem:(OASPaletteItemSolid *)colorItem
{
    _sortedColorItems = [NSMutableArray arrayWithArray:[_appearanceCollection getAvailableColorsSortingByLastUsed]];
    NSInteger row = [_appearanceCollection indexOfColorItem:colorItem items:_sortedColorItems];
    if (row != NSNotFound)
        [self onCollectionItemSelected:[NSIndexPath indexPathForRow:row inSection:0] selectedItem:colorItem collectionView:nil shouldDismiss:YES];
}

- (OASPaletteItemSolid *)addAndGetNewColorItem:(UIColor *)color
{
    OASPaletteItemSolid *newColorItem = [_appearanceCollection addNewSelectedColor:color];
    if (!newColorItem)
        return nil;

    if (_colorsCollectionIndexPath)
    {
        OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:_colorsCollectionIndexPath];
        OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];
        [_sortedColorItems insertObject:newColorItem atIndex:0];
        [colorHandler addAndSelectColor:[NSIndexPath indexPathForRow:0 inSection:0] newItem:newColorItem];
    }
    return newColorItem;
}

- (void)changeColorItem:(OASPaletteItemSolid *)colorItem withColor:(UIColor *)color
{
    NSInteger row = [_appearanceCollection indexOfColorItem:colorItem items:_sortedColorItems];
    if (!_colorsCollectionIndexPath || row == NSNotFound)
        return;

    OASPaletteItemSolid *newColorItem = [_appearanceCollection changeColor:colorItem newColor:color];
    if (newColorItem)
    {
        _sortedColorItems[row] = newColorItem;
        if ([_appearanceCollection isSameColorItem:_currentDayColorItem secondItem:colorItem])
        {
            _currentDayColorItem = newColorItem;
            [_coordinatesGridSettings setGridColor:(int)_currentDayColorItem.colorInt forAppMode:[_settings.applicationMode get] nightMode:NO];
        }
        if ([_appearanceCollection isSameColorItem:_currentNightColorItem secondItem:colorItem])
        {
            _currentNightColorItem = newColorItem;
            [_coordinatesGridSettings setGridColor:(int)_currentNightColorItem.colorInt forAppMode:[_settings.applicationMode get] nightMode:YES];
        }

        _isValueChange = ![_appearanceCollection isSameColorValue:_currentDayColorItem secondItem:_baseDayColorItem] || ![_appearanceCollection isSameColorValue:_currentNightColorItem secondItem:_baseNightColorItem];
        [self updateApplyButton];
    }
}

- (OASPaletteItemSolid *)duplicateColorItem:(OASPaletteItemSolid *)colorItem
{
    OASPaletteItemSolid *duplicatedColorItem = [_appearanceCollection duplicateColor:colorItem];
    if (_colorsCollectionIndexPath)
    {
        NSInteger row = [_appearanceCollection indexOfColorItem:colorItem items:_sortedColorItems];
        if (row == NSNotFound || !duplicatedColorItem)
            return duplicatedColorItem;

        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        [_sortedColorItems insertObject:duplicatedColorItem atIndex:indexPath.row + 1];
        OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:_colorsCollectionIndexPath];
        OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
        [colorHandler addColor:newIndexPath newItem:duplicatedColorItem];
    }

    return duplicatedColorItem;
}

- (void)deleteColorItem:(OASPaletteItemSolid *)colorItem
{
    NSInteger row = [_appearanceCollection indexOfColorItem:colorItem items:_sortedColorItems];
    if (!_colorsCollectionIndexPath || row == NSNotFound)
        return;

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
    [_appearanceCollection deleteColor:colorItem];
    [_sortedColorItems removeObjectAtIndex:indexPath.row];
    OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:_colorsCollectionIndexPath];
    OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];
    BOOL isSelectedColorDeleted = [_appearanceCollection isSameColorItem:[colorHandler getSelectedItem] secondItem:colorItem];
    if (isSelectedColorDeleted)
        [colorHandler setSelectedIndexPath:nil];
    [colorHandler removeColor:indexPath];
}

#pragma mark - UIColorPickerViewControllerDelegate

- (void)colorPickerViewController:(UIColorPickerViewController *)viewController didSelectColor:(UIColor *)color continuously:(BOOL)continuously
{
    if ([OAUtilities isiOSAppOnMac])
        [self addAndGetNewColorItem:color];
}

- (void)colorPickerViewControllerDidFinish:(UIColorPickerViewController *)viewController
{
    [self addAndGetNewColorItem:viewController.selectedColor];
}

#pragma mark - OAIAPProductNotification

- (void)productPurchased:(NSNotification *)notification
{
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf generateData];
        [weakSelf.tableView reloadData];
    });
}

- (void)productsRestored:(NSNotification *)notification
{
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf generateData];
        [weakSelf.tableView reloadData];
    });
}

@end
