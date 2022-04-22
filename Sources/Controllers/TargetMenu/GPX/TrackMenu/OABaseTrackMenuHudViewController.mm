//
//  OABaseTrackMenuHudViewController.h
//  OsmAnd
//
//  Created by Skalii on 25.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABaseTrackMenuHudViewController.h"
#import "OARootViewController.h"
#import "OAMapHudViewController.h"
#import "OAMapRendererView.h"
#import "OAColors.h"
#import "OAGPXDatabase.h"
#import "OAGPXMutableDocument.h"
#import "OsmAndApp.h"
#import "OASavingTrackHelper.h"
#import "OAGPXTrackAnalysis.h"

#define VIEWPORT_SHIFTED_SCALE 1.5f
#define VIEWPORT_NON_SHIFTED_SCALE 1.0f

@implementation OAGPXTableCellData

+ (instancetype)withData:(NSDictionary *)data
{
    OAGPXTableCellData *cellData = [OAGPXTableCellData new];
    if (cellData)
    {
        [cellData setData:data];
    }
    return cellData;
}

- (void)setData:(NSDictionary *)data
{
    if ([data.allKeys containsObject:kTableDataKey])
        _key = data[kTableDataKey];
    if ([data.allKeys containsObject:kCellType])
        _type = data[kCellType];
    if ([data.allKeys containsObject:kTableValues])
        _values = data[kTableValues];
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
        _tintColor = [data[kCellTintColor] integerValue];
}

@end

@implementation OAGPXTableSectionData

+ (instancetype)withData:(NSDictionary *)data
{
    OAGPXTableSectionData *sectionData = [OAGPXTableSectionData new];
    if (sectionData)
    {
        [sectionData setData:data];
    }
    return sectionData;
}

- (void)setData:(NSDictionary *)data
{
    if ([data.allKeys containsObject:kTableDataKey])
        _key = data[kTableDataKey];
    if ([data.allKeys containsObject:kSectionCells])
        _cells = data[kSectionCells];
    if ([data.allKeys containsObject:kSectionHeader])
        _header = data[kSectionHeader];
    if ([data.allKeys containsObject:kSectionHeaderHeight])
        _headerHeight = [data[kSectionHeaderHeight] floatValue];
    if ([data.allKeys containsObject:kSectionFooter])
        _footer = data[kSectionFooter];
    if ([data.allKeys containsObject:kSectionFooterHeight])
        _footerHeight = [data[kSectionFooterHeight] floatValue];
    if ([data.allKeys containsObject:kTableValues])
        _values = data[kTableValues];
}

- (BOOL)containsCell:(NSString *)key
{
    for (OAGPXTableCellData *cellData in self.cells)
    {
        if ([cellData.key isEqualToString:key])
            return YES;
    }
    return NO;
}

- (OAGPXTableCellData *)getCell:(NSString *)key
{
    for (OAGPXTableCellData *cellData in self.cells)
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
    OAGPXTableData *tableData = [OAGPXTableData new];
    if (tableData)
    {
        [tableData setData:data];
    }
    return tableData;
}

- (void)setData:(NSDictionary *)data
{
    if ([data.allKeys containsObject:kTableSections])
        _sections = data[kTableSections];
}

- (BOOL)containsSection:(NSString *)key
{
    for (OAGPXTableSectionData *sectionData in self.sections)
    {
        if ([sectionData.key isEqualToString:key])
            return YES;
    }
    return NO;
}

- (OAGPXTableSectionData *)getSection:(NSString *)key
{
    for (OAGPXTableSectionData *sectionData in self.sections)
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

@property (nonatomic) OAGPX *gpx;
@property (nonatomic) BOOL isShown;
@property (nonatomic) NSArray<OAGPXTableSectionData *> *tableData;

@end

@implementation OABaseTrackMenuHudViewController
{
    CGFloat _cachedYViewPort;
}

- (instancetype)initWithGpx:(OAGPX *)gpx
{
    self = [self initWithNibName:[self getNibName] bundle:nil];
    if (self)
    {
        _gpx = gpx;

        _settings = [OAAppSettings sharedManager];
        _savingHelper = [OASavingTrackHelper sharedInstance];
        _mapPanelViewController = [OARootViewController instance].mapPanel;
        _mapViewController = _mapPanelViewController.mapViewController;
        [self updateGpxData:NO updateDocument:YES];
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
    _isCurrentTrack = !_gpx || _gpx.gpxFilePath.length == 0 || _gpx.gpxFileName.length == 0;

    _isShown = _isCurrentTrack
            ? [_settings.mapSettingShowRecordingTrack get]
            : [[_settings.mapSettingVisibleGpx get] containsObject:_gpx.gpxFilePath];

    if (!_isShown)
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
            _doc = [[OAGPXMutableDocument alloc] initWithGpxFile:gpxFullPath];
        }
    }
    [self updateAnalysis];

    if (replaceGPX)
    {
        if (_isCurrentTrack)
        {
            _gpx = [_savingHelper getCurrentGPX];
        }
        else if (_doc)
        {
            OAGPXDatabase *db = [OAGPXDatabase sharedDb];
            OAGPX *gpx = [db buildGpxItem:_gpx.gpxFilePath title:_doc.metadata.name desc:_doc.metadata.desc bounds:_doc.bounds document:_doc];
            [db replaceGpxItem:gpx];
            [db save];
            _gpx = gpx;
        }
    }
}

- (void)updateAnalysis
{
    if (_doc)
    {
        _analysis = [_doc getGeneralTrack] && [_doc getGeneralSegment]
                ? [OAGPXTrackAnalysis segment:0 seg:_doc.generalSegment] : [_doc getAnalysis:0];
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
    self.backButton.imageView.tintColor = UIColorFromRGB(color_primary_purple);
    [self.backButton addBlurEffect:YES cornerRadius:12. padding:0];

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
    [_mapPanelViewController setTopControlsVisible:NO
                          onlyMapSettingsAndSearch:NO
                              customStatusBarStyle:[OAAppSettings sharedManager].nightMode
                                      ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault];
    [_mapPanelViewController.hudViewController updateMapRulerDataWithDelay];
    [self changeHud:[self getViewHeight]];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if (![self isLandscape])
            [self goExpanded];
    } completion:nil];
}

- (void)hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete
{
    [self restoreMapViewPort];
    [_mapViewController hideContextPinMarker];
    [super hide:YES duration:duration onComplete:^{
        [_mapPanelViewController.hudViewController resetToDefaultRulerLayout];
        [_mapPanelViewController hideScrollableHudViewController];
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

- (void)adjustMapViewPort
{
    if ([self isLandscape] && _mapViewController.mapView.viewportXScale != VIEWPORT_SHIFTED_SCALE)
        _mapViewController.mapView.viewportXScale = VIEWPORT_SHIFTED_SCALE;
    else if (![self isLandscape] && _mapViewController.mapView.viewportXScale != VIEWPORT_NON_SHIFTED_SCALE)
        _mapViewController.mapView.viewportXScale = VIEWPORT_NON_SHIFTED_SCALE;
    if (_mapViewController.mapView.viewportYScale != [self getViewHeight] / DeviceScreenHeight)
        _mapViewController.mapView.viewportYScale = [self getViewHeight] / DeviceScreenHeight;
}

- (void)restoreMapViewPort
{
    OAMapRendererView *mapView = _mapViewController.mapView;
    if (mapView.viewportXScale != VIEWPORT_NON_SHIFTED_SCALE)
        mapView.viewportXScale = VIEWPORT_NON_SHIFTED_SCALE;
    if (mapView.viewportYScale != _cachedYViewPort)
        mapView.viewportYScale = _cachedYViewPort;
}

- (BOOL)isAdjustedMapViewPort
{
    OAMapRendererView *mapView = _mapViewController.mapView;
    return mapView.viewportYScale != _cachedYViewPort && mapView.viewportXScale != VIEWPORT_NON_SHIFTED_SCALE;
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
    [self hide:YES duration:.2 onComplete:^{
        [_mapViewController hideContextPinMarker];
    }];
}

#pragma mark - OADraggableViewActions

- (void)onViewStateChanged:(CGFloat)height
{
    [self changeHud:height];
    if (![self isTabSelecting] && [self adjustCentering])
    {
        if ((self.currentState != EOADraggableMenuStateFullScreen && ![self isLandscape]) || [self isLandscape])
        {
            [self adjustMapViewPort];
            [_mapPanelViewController targetGoToGPX];
        }
    }
}

- (void)onViewHeightChanged:(CGFloat)height
{
    [self changeHud:height];
}

@end
