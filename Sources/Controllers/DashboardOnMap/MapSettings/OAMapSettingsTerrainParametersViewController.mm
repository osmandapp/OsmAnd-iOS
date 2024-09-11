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
#import "OALineChartCell.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAColorCollectionViewController.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAMapLayers.h"
#import "OAAppData.h"
#import "OATerrainMapLayer.h"
#import "OAConcurrentCollections.h"
#import "GeneratedAssetSymbols.h"
#import <DGCharts/DGCharts-Swift.h>

static const NSInteger kMaxMissingDataZoomShift = 5;
static const NSInteger kMinZoomPickerRow = 1;
static const NSInteger kMaxZoomPickerRow = 2;
static const NSInteger kElevationMinMeters = 0;
static const NSInteger kElevationMaxMeters = 2000;

@interface OAMapSettingsTerrainParametersViewController () <UITableViewDelegate, UITableViewDataSource, OACustomPickerTableViewCellDelegate, OACollectionCellDelegate, OAColorCollectionDelegate>

@property (weak, nonatomic) IBOutlet UIView *backButtonContainerView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIView *doneButtonContainerView;
@property (weak, nonatomic) IBOutlet UIButton *resetButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *backButtonLeadingConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *resetButtonTrailingConstraint;

@property (nonatomic) OAMapPanelViewController *mapPanel;
@property (nonatomic) OAConcurrentArray<PaletteColor *> *sortedPaletteColorItems;
@property (nonatomic) GradientColorsCollection *gradientColorsCollection;
@property (nonatomic) NSIndexPath *paletteGridIndexPath;
@property (nonatomic) NSIndexPath *paletteNameIndexPath;
@property (nonatomic) NSIndexPath *paletteLegendIndexPath;
@property (nonatomic) PaletteColor *basePaletteColorItem;
@property (nonatomic) PaletteColor *currentPaletteColorItem;
@property (nonatomic) BOOL isDefaultColorRestored;

@end

@implementation OAMapSettingsTerrainParametersViewController
{
    OsmAndAppInstance _app;
    OATableDataModel *_data;
    TerrainMode *_terrainMode;
    OASRTMPlugin *_plugin;

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

    _baseMinZoom = [_plugin getTerrainMinZoom];
    _baseMaxZoom = [_plugin getTerrainMaxZoom];
    _baseAlpha = [_terrainMode getTransparency] * 0.01;

    if (_terrainType == EOATerrainSettingsTypeVerticalExaggeration)
    {
        _baseVerticalExaggerationScale = _app.data.verticalExaggerationScale;
        _currentVerticalExaggerationScale = _baseVerticalExaggerationScale;
    }
    else if (_terrainType == EOATerrainSettingsTypePalette)
    {
        _gradientColorsCollection = [[GradientColorsCollection alloc] initWithTerrainType:_terrainMode.type];
        _sortedPaletteColorItems = [[OAConcurrentArray alloc] init];
        [_sortedPaletteColorItems addObjectsSync:[_gradientColorsCollection getPaletteColors]];
        _basePaletteColorItem = [_gradientColorsCollection getPaletteColorByName:[_terrainMode getKeyName]];
        if (!_basePaletteColorItem)
            _basePaletteColorItem = [_gradientColorsCollection getPaletteColorByName:[[TerrainMode getDefaultMode:_terrainMode.type] getKeyName]];
        _currentPaletteColorItem = _basePaletteColorItem;

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

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [_mapPanel targetUpdateControlsLayout:YES
                     customStatusBarStyle:[OAAppSettings sharedManager].nightMode ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault];
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
    [self.tableView registerNib:[UINib nibWithNibName:OALineChartCell.reuseIdentifier bundle:nil] forCellReuseIdentifier:OALineChartCell.reuseIdentifier];
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
            result = OALocalizedString(@"shared_string_zoom_levels");
            break;
        case EOATerrainSettingsTypeVerticalExaggeration:
        case EOAGPXSettingsTypeVerticalExaggeration:
            result = OALocalizedString(@"vertical_exaggeration");
            break;
        case EOAGPXSettingsTypeWallHeight:
            result = OALocalizedString(@"wall_height");
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
            break;
        case EOATerrainSettingsTypeZoomLevels:
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
    else if (_terrainType == EOATerrainSettingsTypeZoomLevels)
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
            kCellTypeKey: [OALineChartCell getCellIdentifier],
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
            @"tintTitle": [UIColor colorNamed:ACColorNameIconColorActive]
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
        [_terrainMode setZoomValuesWithMinZoom:_baseMinZoom maxZoom:_baseMaxZoom];
    else if (_terrainType == EOATerrainSettingsTypeVerticalExaggeration && _baseVerticalExaggerationScale != _currentVerticalExaggerationScale)
        _app.data.verticalExaggerationScale = _baseVerticalExaggerationScale;
    else if (_terrainType == EOATerrainSettingsTypePalette && (_basePaletteColorItem != _currentPaletteColorItem || _isDefaultColorRestored))
        [self setPaletteColorItem:_basePaletteColorItem];
    else if (_terrainType == EOAGPXSettingsTypeVerticalExaggeration && _baseGPXVerticalExaggerationScale != _currentGPXVerticalExaggerationScale)
        [self applyGPXVerticalExaggerationForScale:_baseGPXVerticalExaggerationScale];
    else if (_terrainType == EOAGPXSettingsTypeWallHeight && _baseGPXElevationMeters != _currentGPXElevationMeters)
        [self applyGPXElevationMeters:_baseGPXElevationMeters];

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
    if (_minZoom != terrainMinSupportedZoom || _maxZoom != terrainMaxSupportedZoom)
    {
        _minZoom = terrainMinSupportedZoom;
        _maxZoom = terrainMaxSupportedZoom;
        [_terrainMode setZoomValuesWithMinZoom:_minZoom maxZoom:_maxZoom];
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
            if (defaultIndexPath != [[colorCell getCollectionHandler] getSelectedIndexPath])
            {
                [[colorCell getCollectionHandler] onItemSelected:defaultIndexPath
                                                  collectionView:colorCell.collectionView];
                return YES;
            }
        }
    }
    return NO;
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
    [_terrainMode setZoomValuesWithMinZoom:_minZoom maxZoom:_maxZoom];
}

- (void)applyVerticalExaggerationScale
{
    _app.data.verticalExaggerationScale = _currentVerticalExaggerationScale;
}

- (void)applyPalette
{
    [self setPaletteColorItem:_currentPaletteColorItem];
}

- (NSArray<NSString *> *)getPossibleZoomValues
{
    NSMutableArray *res = [NSMutableArray new];
    for (NSInteger i = terrainMinSupportedZoom; i <= terrainMaxSupportedZoom; i++)
    {
        [res addObject:[NSString stringWithFormat:@"%ld", i]];
    }
    return res;
}

- (void)setPaletteColorItem:(PaletteColor *)paletteColor
{
    if ([paletteColor isKindOfClass:PaletteGradientColor.class])
    {
        PaletteGradientColor *paletteGradientColor = (PaletteGradientColor *) paletteColor;
        TerrainType terrainType = [TerrainTypeWrapper valueOfTypeName: paletteGradientColor.typeName];
        NSString *key = paletteGradientColor.paletteName;
        TerrainMode *mode = [TerrainMode getMode:terrainType keyName:key];
        if (mode)
        {
            [_plugin setTerrainMode:mode];
            [self updateApplyButton];
        }
    }
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
    else if (_terrainType == EOATerrainSettingsTypeZoomLevels)
        wasReset = [self resetZoomLevels];
    else if (_terrainType == EOATerrainSettingsTypeVerticalExaggeration)
        wasReset = [self resetVerticalExaggerationValues];
    else if (_terrainType == EOATerrainSettingsTypePalette)
        wasReset = [self resetPalette];
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
    else if (_terrainType == EOATerrainSettingsTypeVerticalExaggeration && _currentVerticalExaggerationScale != _app.data.verticalExaggerationScale)
        [self applyVerticalExaggerationScale];
    else if (_terrainType == EOATerrainSettingsTypePalette && ![((PaletteGradientColor *) _currentPaletteColorItem).paletteName isEqualToString:[[_plugin getTerrainMode] getKeyName]])
        [self applyPalette];
    else if (_terrainType == EOAGPXSettingsTypeVerticalExaggeration && _baseGPXVerticalExaggerationScale != _currentGPXVerticalExaggerationScale)
        [self applyGPXVerticalExaggerationForScale:_currentGPXVerticalExaggerationScale];
    else if (_terrainType == EOAGPXSettingsTypeWallHeight && _baseGPXElevationMeters != _currentGPXElevationMeters)
        [self applyGPXElevationMeters:_currentGPXElevationMeters];

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

- (void)onCollectionDeleted:(NSNotification *)notification
{
    if (![notification.object isKindOfClass:NSArray.class])
        return;
    
    NSArray<PaletteGradientColor *> *gradientPaletteColor = (NSArray<PaletteGradientColor *> *) notification.object;
    PaletteGradientColor *currentGradientPaletteColor;
    if ([_currentPaletteColorItem isKindOfClass:PaletteGradientColor.class])
        currentGradientPaletteColor = (PaletteGradientColor *) _currentPaletteColorItem;
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
    
    if (indexPathsToDelete.count > 0 && _paletteGridIndexPath)
    {
        __weak __typeof(self) weakSelf = self;
        [self.tableView performBatchUpdates:^{
            OACollectionSingleLineTableViewCell *colorCell = [weakSelf.tableView cellForRowAtIndexPath:weakSelf.paletteGridIndexPath];
            OABaseCollectionHandler *handler = [colorCell getCollectionHandler];
            [handler removeItems:indexPathsToDelete];
        } completion:^(BOOL finished) {
            if (weakSelf.isDefaultColorRestored)
            {
                _basePaletteColorItem = [_gradientColorsCollection getPaletteColorByName:[[TerrainMode getDefaultMode:_terrainMode.type] getKeyName]];
                _currentPaletteColorItem = _basePaletteColorItem;
                _isValueChange = NO;
                [self updateApplyButton];
                
                NSMutableArray *indexPaths = [NSMutableArray array];
                if (weakSelf.paletteLegendIndexPath)
                    [indexPaths addObject:weakSelf.paletteLegendIndexPath];
                if (weakSelf.paletteNameIndexPath)
                    [indexPaths addObject:weakSelf.paletteNameIndexPath];
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
    
    if (indexPathsToInsert.count > 0 && _paletteGridIndexPath)
    {
        __weak __typeof(self) weakSelf = self;
        [self.tableView performBatchUpdates:^{
            OACollectionSingleLineTableViewCell *colorCell = [weakSelf.tableView cellForRowAtIndexPath:weakSelf.paletteGridIndexPath];
            OABaseCollectionHandler *handler = [colorCell getCollectionHandler];
            [handler removeItems:indexPathsToInsert];
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
            if (paletteColor == _currentPaletteColorItem)
                currentPaletteColor = YES;
        }
    }
    
    if (indexPathsToUpdate.count > 0 && _paletteGridIndexPath)
    {
        __weak __typeof(self) weakSelf = self;
        [self.tableView performBatchUpdates:^{
            OACollectionSingleLineTableViewCell *colorCell = [weakSelf.tableView cellForRowAtIndexPath:weakSelf.paletteGridIndexPath];
            OABaseCollectionHandler *handler = [colorCell getCollectionHandler];
            for (NSIndexPath *indexPath in indexPathsToUpdate)
            {
                [handler replaceItem:[weakSelf.sortedPaletteColorItems objectAtIndexSync:indexPath.row]
                         atIndexPath:indexPath];
                if (currentPaletteColor && _paletteLegendIndexPath)
                {
                    [weakSelf.tableView reloadRowsAtIndexPaths:@[_paletteLegendIndexPath]
                                              withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            }
        } completion:nil];
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
        NSInteger minZoom = _minZoom >= terrainMinSupportedZoom && _minZoom <= terrainMaxSupportedZoom ? (_minZoom - terrainMinSupportedZoom) : 1;
        NSInteger maxZoom = _maxZoom >= terrainMinSupportedZoom && _maxZoom <= terrainMaxSupportedZoom ? (_maxZoom - terrainMinSupportedZoom) : 1;
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
        cell.selectionStyle = isPaletteName ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleDefault;
        cell.titleLabel.text = isPaletteName ? [_currentPaletteColorItem toHumanString] : item.title;
        cell.titleLabel.textColor = [item objForKey:@"tintTitle"] ?: UIColorFromRGB(color_extra_text_gray);
        cell.titleLabel.font = [UIFont preferredFontForTextStyle:isPaletteName ? UIFontTextStyleFootnote : UIFontTextStyleBody];
        return cell;
    }
    else if ([item.cellType isEqualToString:[OACollectionSingleLineTableViewCell reuseIdentifier]])
    {
        OACollectionSingleLineTableViewCell *cell =
            [tableView dequeueReusableCellWithIdentifier:[OACollectionSingleLineTableViewCell getCellIdentifier]];
        [cell rightActionButtonVisibility:NO];
        [cell.collectionView registerNib:[UINib nibWithNibName:PaletteCollectionViewCell.reuseIdentifier bundle:nil] forCellWithReuseIdentifier:PaletteCollectionViewCell.reuseIdentifier];

        PaletteCollectionHandler *paletteHandler = [[PaletteCollectionHandler alloc] initWithData:@[[_sortedPaletteColorItems asArray]] collectionView:cell.collectionView];
        paletteHandler.delegate = self;
        NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:[_sortedPaletteColorItems indexOfObjectSync:_currentPaletteColorItem] inSection:0];
        if (selectedIndexPath.row == NSNotFound)
            selectedIndexPath = [NSIndexPath indexPathForRow:[_sortedPaletteColorItems indexOfObjectSync:[_gradientColorsCollection getPaletteColorByName:[_terrainMode getKeyName]]] inSection:0];
        [paletteHandler setSelectedIndexPath:selectedIndexPath];
        [cell setCollectionHandler:paletteHandler];
        cell.collectionView.contentInset = UIEdgeInsetsMake(0, 10, 0, 0);
        [cell configureTopOffset:12];
        [cell configureBottomOffset:12];
        return cell;
    }
    else if ([item.cellType isEqualToString:OALineChartCell.reuseIdentifier])
    {
        OALineChartCell *cell = (OALineChartCell *) [tableView dequeueReusableCellWithIdentifier:OALineChartCell.reuseIdentifier
                                                                                         forIndexPath:indexPath];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.separatorInset = UIEdgeInsetsMake(0, CGFLOAT_MAX, 0, 0);
        cell.heightConstraint.constant = 75;
        cell.lineChartView.extraTopOffset = 20;

        [GpxUIHelper setupGradientChartWithChart:cell.lineChartView
                             useGesturesAndScale:NO
                                  xAxisGridColor:[UIColor colorNamed:ACColorNameChartAxisGridLine]
                                     labelsColor:[UIColor colorNamed:ACColorNameChartTextColorAxisX]];

        ColorPalette *colorPalette;
        if ([_currentPaletteColorItem isKindOfClass:PaletteGradientColor.class])
        {
            PaletteGradientColor *paletteColor = (PaletteGradientColor *) _currentPaletteColorItem;
            colorPalette = paletteColor.colorPalette;
        }
        if (!colorPalette)
            return cell;

        cell.lineChartView.data =
            [GpxUIHelper buildGradientChartWithChart:cell.lineChartView
                                        colorPalette:colorPalette
                                      valueFormatter:[GradientUiHelper getGradientTypeFormatter:_gradientColorsCollection.gradientType
                                                                                       analysis:nil]];

        [cell.lineChartView setVisibleYRangeWithMinYRange:0 maxYRange: 1 axis:AxisDependencyLeft];
        [cell.lineChartView notifyDataSetChanged];
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
        OAColorCollectionViewController *colorCollectionViewController = [[OAColorCollectionViewController alloc] initWithCollectionType:EOAColorCollectionTypePaletteItems
                                                                                                                                   items:_gradientColorsCollection
                                                                                                                            selectedItem:_currentPaletteColorItem];
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
            [_terrainMode setZoomValuesWithMinZoom:_minZoom maxZoom:_maxZoom];
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
            [_terrainMode setZoomValuesWithMinZoom:_minZoom maxZoom:_maxZoom];
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

- (void)onCollectionItemSelected:(NSIndexPath *)indexPath
{
    _currentPaletteColorItem = [_sortedPaletteColorItems objectAtIndexSync:indexPath.row];;
    _isValueChange = _basePaletteColorItem != _currentPaletteColorItem;
    [self setPaletteColorItem:_currentPaletteColorItem];
    NSMutableArray<NSIndexPath *> *indexPaths = [NSMutableArray array];
    if (_paletteNameIndexPath)
        [indexPaths addObject:_paletteNameIndexPath];
    if (_paletteLegendIndexPath)
        [indexPaths addObject:_paletteLegendIndexPath];
    if (indexPaths.count > 0)
        [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - OAColorCollectionDelegate

- (void)selectPaletteItem:(PaletteColor *)paletteItem
{
    [self onCollectionItemSelected:[NSIndexPath indexPathForRow:[_sortedPaletteColorItems indexOfObjectSync:paletteItem] inSection:0]];
}

@end
