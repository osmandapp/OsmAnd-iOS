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
#import "GeneratedAssetSymbols.h"

static const NSInteger kMaxMissingDataZoomShift = 5;
static const NSInteger kMinZoomPickerRow = 1;
static const NSInteger kMaxZoomPickerRow = 2;
static const NSInteger kElevationMinMeters = 0;
static const NSInteger kElevationMaxMeters = 2000;

@interface OAMapSettingsTerrainParametersViewController () <UITableViewDelegate, UITableViewDataSource, OACustomPickerTableViewCellDelegate, OACollectionCellDelegate>

@property (weak, nonatomic) IBOutlet UIView *backButtonContainerView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIView *doneButtonContainerView;
@property (weak, nonatomic) IBOutlet UIButton *resetButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *backButtonLeadingConstraint;

@end

@implementation OAMapSettingsTerrainParametersViewController
{
    OsmAndAppInstance _app;
    OATableDataModel *_data;
    TerrainMode *_terrainMode;
    OAMapPanelViewController *_mapPanel;
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

    GradientColorsCollection *_gradientColorsCollection;
    NSMutableArray<PaletteColor *> *_sortedPaletteColorItems;
    PaletteColor *_basePaletteColorItem;
    PaletteColor *_currentPaletteColorItem;
    NSIndexPath *_paletteNameIndexPath;
    NSIndexPath *_paletteGridIndexPath;
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
        _sortedPaletteColorItems = [NSMutableArray arrayWithArray:[_gradientColorsCollection getPaletteColors]];
        _basePaletteColorItem = [_gradientColorsCollection getGradientPaletteBy:[_terrainMode getKeyName]];
        if (!_basePaletteColorItem)
            _basePaletteColorItem = [_gradientColorsCollection getGradientPaletteBy:[[TerrainMode getDefaultMode:_terrainMode.type] getKeyName]];
        _currentPaletteColorItem = _basePaletteColorItem;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onColorPalettesFilesUpdated:)
                                                     name:ColorPaletteHelper.colorPalettesUpdatedNotification
                                                   object:nil];
    }

    _minZoom = _baseMinZoom;
    _maxZoom = _baseMaxZoom;
    _currentAlpha = _baseAlpha;
}

- (void)onColorPalettesFilesUpdated:(NSNotification *)notification
{
    if (![notification.object isKindOfClass:NSDictionary.class] || _terrainType != EOATerrainSettingsTypePalette)
        return;

    NSDictionary<NSString *, NSString *> *colorPaletteFiles = (NSDictionary *) notification.object;
    if (!colorPaletteFiles)
        return;
    NSString *currentPaletteFile = [_terrainMode getMainFile];
    BOOL reloadData = NO;
    BOOL deleted = NO;
    for (NSString *colorPaletteFile in colorPaletteFiles.allKeys)
    {
        if ([_gradientColorsCollection hasTerrainGradientPaletteBy:colorPaletteFile]
            || [colorPaletteFiles[colorPaletteFile] isEqualToString:ColorPaletteHelper.createdFileKey])
        {
            reloadData = YES;
            if ([currentPaletteFile isEqualToString:colorPaletteFile]
                && [colorPaletteFiles[colorPaletteFile] isEqualToString:ColorPaletteHelper.deletedFileKey])
            {
                deleted = YES;
                break;
            }
        }
    }
    if (reloadData)
    {
        _gradientColorsCollection = [[GradientColorsCollection alloc] initWithTerrainType:_terrainMode.type];
        _sortedPaletteColorItems = [NSMutableArray arrayWithArray:[_gradientColorsCollection getPaletteColors]];
        if (deleted)
            _basePaletteColorItem = [_gradientColorsCollection getDefaultGradientPalette];
        else
            _basePaletteColorItem = [_gradientColorsCollection getGradientPaletteBy:[_terrainMode getKeyName]];
        _currentPaletteColorItem = _basePaletteColorItem;

        dispatch_async(dispatch_get_main_queue(), ^{
            [self generateData];
            [UIView transitionWithView:self.tableView
                              duration:0.35f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^(void)
             {
                [self.tableView reloadData];
            }
                            completion:nil];
        });
    }
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
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        if (![self isLandscape])
            [self goMinimized:NO];
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
            kCellKeyKey: @"paletteName",
            kCellTypeKey: [OASimpleTableViewCell getCellIdentifier],
        }];
        _paletteNameIndexPath = [NSIndexPath indexPathForRow:[topSection rowCount] - 1 inSection:[_data sectionCount] - 1];
        [topSection addRowFromDictionary:@{
            kCellKeyKey: @"colorGrid",
            kCellTypeKey: [OACollectionSingleLineTableViewCell getCellIdentifier]
        }];
        _paletteGridIndexPath = [NSIndexPath indexPathForRow:[topSection rowCount] - 1 inSection:[_data sectionCount] - 1];
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
    self.backButtonLeadingConstraint.constant = [self isLandscape]
        ? (isRTL ? 0. : [self getLandscapeViewWidth] - [OAUtilities getLeftMargin] + 10.)
        : [OAUtilities getLeftMargin] + 10.;
}

- (void)hide
{
    if (_terrainType == EOATerrainSettingsTypeVisibility && _baseAlpha != _currentAlpha)
        [_terrainMode setTransparency:_baseAlpha / 0.01];
    else if (_terrainType == EOATerrainSettingsTypeZoomLevels && (_baseMinZoom != _minZoom || _baseMaxZoom != _maxZoom))
        [_terrainMode setZoomValuesWithMinZoom:_baseMinZoom maxZoom:_baseMaxZoom];
    else if (_terrainType == EOATerrainSettingsTypeVerticalExaggeration && _baseVerticalExaggerationScale != _currentVerticalExaggerationScale)
        _app.data.verticalExaggerationScale = _baseVerticalExaggerationScale;
    else if (_terrainType == EOATerrainSettingsTypePalette && _basePaletteColorItem != _currentPaletteColorItem)
        [self setPaletteColorItem:_basePaletteColorItem];
    else if (_terrainType == EOAGPXSettingsTypeVerticalExaggeration && _baseGPXVerticalExaggerationScale != _currentGPXVerticalExaggerationScale)
        [self applyGPXVerticalExaggerationForScale:_baseGPXVerticalExaggerationScale];
    else if (_terrainType == EOAGPXSettingsTypeWallHeight && _baseGPXElevationMeters != _currentGPXElevationMeters)
        [self applyGPXElevationMeters:_baseGPXElevationMeters];

    [self hide:YES duration:.2 onComplete:^{
        if (self.delegate)
            [self.delegate onBackTerrainParameters];
        if (self.hideCallback)
            self.hideCallback();
    }];
}

- (void)hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete
{
    [super hide:YES duration:duration onComplete:^{
        [_mapPanel hideScrollableHudViewController];
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
    
    [self hide:YES duration:.2 onComplete:^{
        if (self.delegate)
            [self.delegate onBackTerrainParameters];
        if (self.hideCallback)
            self.hideCallback();
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
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.titleLabel.text = [_currentPaletteColorItem toHumanString];
        cell.titleLabel.textColor = UIColorFromRGB(color_extra_text_gray);
        cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        return cell;
    }
    else if ([item.cellType isEqualToString:[OACollectionSingleLineTableViewCell reuseIdentifier]])
    {
        OACollectionSingleLineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OACollectionSingleLineTableViewCell reuseIdentifier]];
            cell.separatorInset = UIEdgeInsetsZero;

        PaletteCollectionHandler *paletteHandler = [[PaletteCollectionHandler alloc] initWithData:@[_sortedPaletteColorItems] collectionView:cell.collectionView];
        paletteHandler.delegate = self;
        NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:[_sortedPaletteColorItems indexOfObject:_currentPaletteColorItem] inSection:0];
        if (selectedIndexPath.row == NSNotFound)
            selectedIndexPath = [NSIndexPath indexPathForRow:[_sortedPaletteColorItems indexOfObject:[_gradientColorsCollection getGradientPaletteBy:[_terrainMode getKeyName]]] inSection:0];
        [paletteHandler setSelectedIndexPath:selectedIndexPath];
        [cell setCollectionHandler:paletteHandler];

        [cell rightActionButtonVisibility:NO];
        [cell.collectionView performBatchUpdates:^{
            for (NSInteger i = 0; i < cell.collectionView.numberOfSections; i ++)
            {
                [cell.collectionView reloadSections:[NSIndexSet indexSetWithIndex:i]];
            }
        } completion:nil];
        [cell layoutIfNeeded];
        return cell;
    }
    return nil;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
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
    _currentPaletteColorItem = _sortedPaletteColorItems[indexPath.row];
    _isValueChange = _basePaletteColorItem != _currentPaletteColorItem;
    [self setPaletteColorItem:_currentPaletteColorItem];
    if (_paletteNameIndexPath)
    {
        [self.tableView reloadRowsAtIndexPaths:@[_paletteNameIndexPath]
                              withRowAnimation:UITableViewRowAnimationNone];
    }
}

@end
