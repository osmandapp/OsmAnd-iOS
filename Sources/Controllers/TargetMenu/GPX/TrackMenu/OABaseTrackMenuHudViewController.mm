//
//  OABaseTrackMenuHudViewController.h
//  OsmAnd
//
//  Created by Skalii on 25.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABaseTrackMenuHudViewController.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapHudViewController.h"
#import "OAMapRendererView.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAGPXDatabase.h"
#import "OsmAndApp.h"
#import "OASavingTrackHelper.h"
#import "GeneratedAssetSymbols.h"
#import "OASelectedGPXHelper.h"
#import "OAGPXUIHelper.h"

@implementation OAGPXBaseTableData

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _values = [NSMutableDictionary dictionary];
        _subjects = [NSMutableArray array];
    }
    return self;
}

+ (instancetype)withData:(NSDictionary *)data
{
    OAGPXBaseTableData *cellData = [OAGPXBaseTableData new];
    if (cellData && data)
        [cellData setData:data];

    return cellData;
}

- (void)setData:(NSDictionary *)data
{
    if ([data.allKeys containsObject:kTableKey])
        _key = data[kTableKey];
    if ([data.allKeys containsObject:kTableValues])
    {
        id subjects = data[kTableValues];
        _values = [subjects isKindOfClass:NSMutableDictionary.class] ? subjects : [NSMutableDictionary dictionaryWithDictionary:subjects];
    }
    if ([data.allKeys containsObject:kTableSubjects])
    {
        id subjects = data[kTableSubjects];
        _subjects = [subjects isKindOfClass:NSMutableArray.class] ? subjects : [NSMutableArray arrayWithArray:subjects];
    }
}

- (OAGPXBaseTableData *)getSubject:(NSString *)key
{
    return nil;
}

@end

@implementation OAGPXTableCellData

@dynamic subjects;

+ (instancetype)withData:(NSDictionary *)data
{
    OAGPXTableCellData *cellData = [OAGPXTableCellData new];
    if (cellData && data)
        [cellData setData:data];

    return cellData;
}

- (void)setData:(NSDictionary *)data
{
    [super setData:data];

    if ([data.allKeys containsObject:kCellType])
        _type = data[kCellType];
    if ([data.allKeys containsObject:kCellTitle])
        _title = data[kCellTitle];
    if ([data.allKeys containsObject:kCellDesc])
        _desc = data[kCellDesc];
    if ([data.allKeys containsObject:kCellLeftIcon])
        _leftIcon = data[kCellLeftIcon];
    if ([data.allKeys containsObject:kCellRightIconName])
        _rightIconName = data[kCellRightIconName];
    if ([data.allKeys containsObject:kCellToggle])
        _toggle = [data[kCellToggle] boolValue];
    if ([data.allKeys containsObject:kCellTintColor])
        _tintColor = data[kCellTintColor];
    if ([data.allKeys containsObject:kCellIsDisabled])
        _isDisabled = [data[kCellIsDisabled] boolValue];
}

- (OAGPXTableCellData *)getSubject:(NSString *)key
{
    for (OAGPXTableCellData *cellData in self.subjects)
    {
        if ([cellData.key isEqualToString:key])
            return cellData;
    }
    return nil;
}

@end

@implementation OAGPXTableSectionData

@dynamic subjects;

+ (instancetype)withData:(NSDictionary *)data
{
    OAGPXTableSectionData *cellData = [OAGPXTableSectionData new];
    if (cellData && data)
        [cellData setData:data];

    return cellData;
}

- (void)setData:(NSDictionary *)data
{
    [super setData:data];

    if ([data.allKeys containsObject:kSectionHeader])
        _header = data[kSectionHeader];
    if ([data.allKeys containsObject:kSectionHeaderHeight])
        _headerHeight = [data[kSectionHeaderHeight] floatValue];
    if ([data.allKeys containsObject:kSectionFooter])
        _footer = data[kSectionFooter];
    if ([data.allKeys containsObject:kSectionFooterHeight])
        _footerHeight = [data[kSectionFooterHeight] floatValue];
}

- (OAGPXTableCellData *)getSubject:(NSString *)key
{
    for (OAGPXTableCellData *cellData in self.subjects)
    {
        if ([cellData.key isEqualToString:key])
            return cellData;
    }
    return nil;
}

@end

@implementation OAGPXTableData

+ (instancetype)withData:(NSDictionary *)data
{
    OAGPXTableData *cellData = [OAGPXTableData new];
    if (cellData && data)
        [cellData setData:data];

    return cellData;
}

- (OAGPXTableSectionData *)getSubject:(NSString *)key
{
    for (OAGPXTableSectionData *sectionData in self.subjects)
    {
        if ([sectionData.key isEqualToString:key])
            return sectionData;
    }
    return nil;
}

@end

@interface OABaseTrackMenuHudViewController()

@property (weak, nonatomic) IBOutlet UIView *backButtonContainerView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *backButtonLeadingConstraint;

@property (nonatomic) OASTrackItem *gpx;
@property (nonatomic) BOOL isShown;
@property (nonatomic) NSArray<OAGPXTableSectionData *> *tableData;

@end

@implementation OABaseTrackMenuHudViewController
{
    CGFloat _cachedYViewPort;
}

- (instancetype)initWithGpx:(OASTrackItem *)gpx
{
    self = [self initWithNibName:[self getNibName] bundle:nil];
    if (self)
    {
        _gpx = gpx;
        _settings = [OAAppSettings sharedManager];
        _savingHelper = [OASavingTrackHelper sharedInstance];
        _mapPanelViewController = [OARootViewController instance].mapPanel;
        _mapViewController = _mapPanelViewController.mapViewController;
        _isCurrentTrack = gpx.isShowCurrentTrack;
        [self updateGpxData:gpx == nil updateDocument:YES];
        if (!_analysis)
            [self updateAnalysis];
        [self commonInit];
    }
    return self;
}

- (NSString *)getNibName
{
    return nil; //override
}

- (void)updateGpxData:(BOOL)replaceGPX updateDocument:(BOOL)updateDocument
{
    if (!_isShown && _gpx.dataItem && !_gpx.dataItem.isTempTrack)
        [self changeTrackVisible];

    if (updateDocument)
    {
        _doc = nil;
        if (_isCurrentTrack)
        {
            _doc = _savingHelper.currentTrack;
        }
        else
        {
            NSString *gpxFullPath = [[OsmAndApp instance].gpxPath stringByAppendingPathComponent:_gpx.gpxFilePath];
            OASGpxFile *gpx = [[OASelectedGPXHelper instance] getGpxFileFor:gpxFullPath];
            if (!gpx)
            {
                OASKFile *file = [[OASKFile alloc] initWithFilePath:gpxFullPath];
                _doc = [OASGpxUtilities.shared loadGpxFileFile:file];
            }
            else
            {
                _doc = gpx;
            }
        }
    }
    [self updateAnalysis];

    if (!_isCurrentTrack && _gpx && _gpx.dataItem.nearestCity.length == 0 && _analysis && _analysis.locationStart)
    {
        auto locationStart = _analysis.locationStart;
        
        OAPOI *nearestCity = [OAGPXUIHelper searchNearestCity:CLLocationCoordinate2DMake(locationStart.lat, locationStart.lon)];
        NSString *nearestCityString = nearestCity ? nearestCity.nameLocalized : @"";

        OAGPXDatabase *db = [OAGPXDatabase sharedDb];
        OASGpxDataItem *gpx = [db getGPXItem:_gpx.gpxFilePath];
        if (gpx)
        {
            [[OASGpxDbHelper shared] updateDataItemParameterItem:_gpx.dataItem
                                                       parameter:OASGpxParameter.nearestCityName
                                                           value:nearestCityString];
        }
    }

    if (replaceGPX)
    {
        if (_isCurrentTrack)
        {
            _gpx = [[OASTrackItem alloc] initWithGpxFile:_savingHelper.currentTrack];
        }
        else if (_doc)
        {
            
            OAGPXDatabase *gpxDb = [OAGPXDatabase sharedDb];
            OASGpxDataItem *gpx = [gpxDb getGPXItem:_gpx.gpxFilePath];
            if (!gpx)
            {
                gpx = [gpxDb addGPXFileToDBIfNeeded:_gpx.gpxFilePath];
            }
            gpx.nearestCity = _gpx.nearestCity;
            [gpxDb updateDataItem:gpx];
            _gpx = [[OASTrackItem alloc] initWithFile:gpx.file];
        }
    }
}


- (OASGpxTrackAnalysis *)getAnalysisFor:(OASTrkSegment *)segment
{
    OASGpxTrackAnalysis *analysis = [[OASGpxTrackAnalysis alloc] init];
    auto splitSegments = [ArraySplitSegmentConverter toKotlinArrayFrom:@[[[OASSplitSegment alloc] initWithSegment:segment]]];
    [analysis prepareInformationFileTimeStamp:0 pointsAnalyser:nil splitSegments:splitSegments];
    return analysis;
}

- (void)updateAnalysis
{
    if (_doc)
    {
        _analysis = !_isCurrentTrack && [_doc getGeneralTrack] && [_doc getGeneralSegment]
        ? [self getAnalysisFor:[_doc getGeneralSegment]]
        : [_doc getAnalysisFileTimestamp:0 fromDistance:nil toDistance:nil pointsAnalyzer:OASPlatformUtil.shared.getTrackPointsAnalyser];
    }
    else
    {
        _analysis = nil;
    }
}

- (BOOL)changeTrackVisible
{
    if (self.isShown)
    {
        if (self.isCurrentTrack)
        {
            [self.settings.mapSettingShowRecordingTrack set:NO];
            [self.mapViewController hideRecGpxTrack];
        }
        else
        {
            [self.settings hideGpx:@[self.gpx.gpxFilePath] update:YES];
        }
    }
    else
    {
        if (self.isCurrentTrack)
        {
            [self.settings.mapSettingShowRecordingTrack set:YES];
            [self.mapViewController showRecGpxTrack:YES];
        }
        else
        {
            [self.settings showGpx:@[self.gpx.gpxFilePath] update:YES];
        }
    }

    return self.isShown = !self.isShown;
}

- (void)commonInit
{
    //override
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self applyLocalization];
    _cachedYViewPort = _mapViewController.mapView.viewportYScale;

    UIImage *backImage = [UIImage templateImageNamed:@"ic_custom_arrow_back"];
    [self.backButton setImage:[self.backButton isDirectionRTL] ? backImage.imageFlippedForRightToLeftLayoutDirection : backImage
                     forState:UIControlStateNormal];
    self.backButton.imageView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
    [self.backButton addBlurEffect:[ThemeManager shared].isLightTheme cornerRadius:12. padding:0];
    self.backButton.accessibilityLabel = localizedString(@"shared_string_dismiss");

    [self setupView];

    [self generateData];
    [self setupHeaderView];

    [self updateShowingState:[self isLandscape] ? EOADraggableMenuStateFullScreen : EOADraggableMenuStateExpanded];
}

- (void)applyLocalization
{
    //override
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [_mapPanelViewController targetUpdateControlsLayout:YES customStatusBarStyle:self.preferredStatusBarStyle];
    [_mapPanelViewController.hudViewController updateMapRulerDataWithDelay];
    [self changeHud:[self getViewHeight]];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    __weak __typeof(self) weakSelf = self;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if (![weakSelf isLandscape])
            [weakSelf goExpanded];
    } completion:nil];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection])
        [self.backButton addBlurEffect:[ThemeManager shared].isLightTheme cornerRadius:12. padding:0];
}

- (void)hide
{
    [self hide:YES duration:.2 onComplete:nil];
}

- (void)hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete
{
    [self restoreMapViewPort];
    [_mapViewController hideContextPinMarker];
    __weak __typeof(self) weakSelf = self;
    [super hide:YES duration:duration onComplete:^{
        [weakSelf.mapPanelViewController.hudViewController resetToDefaultRulerLayout];
        [weakSelf.mapPanelViewController hideScrollableHudViewController];
        if (onComplete)
            onComplete();
    }];
}

- (void)setupView
{
    //override
}

- (void)setupHeaderView
{
    //override
}

- (void)generateData
{
    //override
}

- (BOOL)isTabSelecting
{
    return NO;  //override
}

- (BOOL)adjustCentering
{
    return NO;  //override
}

- (void)setupModeViewShadowVisibility
{
    self.topHeaderContainerView.layer.shadowOpacity = 0.0;
}

- (CGFloat)expandedMenuHeight
{
    return DeviceScreenHeight / 2;
}

- (BOOL)showStatusBarWhenFullScreen
{
    return YES;
}

- (void)doAdditionalLayout
{
    BOOL isRTL = [self.backButtonContainerView isDirectionRTL];
    self.backButtonLeadingConstraint.constant = [self isLandscape]
            ? (isRTL ? 0. : [self getLandscapeViewWidth] - [OAUtilities getLeftMargin] + 10.)
            : [OAUtilities getLeftMargin] + 10.;
    self.backButtonContainerView.hidden = ![self isLandscape] && self.currentState == EOADraggableMenuStateFullScreen;
}

- (void)adjustViewPort:(BOOL)landscape
{
    [_mapPanelViewController.mapViewController setViewportScaleX:landscape ? kViewportBottomScale : kViewportScale];
    if (!landscape)
        [_mapPanelViewController.mapViewController setViewportScaleY:(DeviceScreenHeight - [self getViewHeight]) / DeviceScreenHeight];
}

- (void)restoreMapViewPort
{
    [_mapPanelViewController.mapViewController setViewportScaleX:kViewportScale y:_cachedYViewPort];
}

- (BOOL)isAdjustedMapViewPort
{
    OAMapRendererView *mapView = _mapViewController.mapView;
    return mapView.viewportYScale != _cachedYViewPort && mapView.viewportXScale != kViewportScale;
}

- (void)changeHud:(CGFloat)height
{
    [_mapPanelViewController.hudViewController updateBottomContolMarginsForHeight];
}

- (NSLayoutConstraint *)createBaseEqualConstraint:(UIView *)firstItem
                                   firstAttribute:(NSLayoutAttribute)firstAttribute
                                       secondItem:(UIView *)secondItem
                                  secondAttribute:(NSLayoutAttribute)secondAttribute
{
    return [self createBaseEqualConstraint:firstItem
                            firstAttribute:firstAttribute
                                secondItem:secondItem
                           secondAttribute:secondAttribute
                                  constant:0.f];
}

- (NSLayoutConstraint *)createBaseEqualConstraint:(UIView *)firstItem
                                   firstAttribute:(NSLayoutAttribute)firstAttribute
                                       secondItem:(UIView *)secondItem
                                  secondAttribute:(NSLayoutAttribute)secondAttribute
                                         constant:(CGFloat)constant
{
    return [NSLayoutConstraint constraintWithItem:firstItem
                                        attribute:firstAttribute
                                        relatedBy:NSLayoutRelationEqual
                                           toItem:secondItem
                                        attribute:secondAttribute
                                       multiplier:1.0f
                                         constant:constant];
}

- (IBAction)onBackButtonPressed:(id)sender
{
    [self hide];
}

#pragma mark - OADraggableViewActions

- (void)onViewStateChanged:(CGFloat)height
{
    [self changeHud:height];
    if (![self isTabSelecting] && [self adjustCentering])
    {
        BOOL landscape = [self isLandscape];
        if ((self.currentState != EOADraggableMenuStateFullScreen && !landscape) || landscape)
        {
            [self adjustViewPort:landscape];
            [_mapPanelViewController targetGoToGPX];
        }
    }
}

- (void)onViewHeightChanged:(CGFloat)height
{
    [self changeHud:height];
}

@end
