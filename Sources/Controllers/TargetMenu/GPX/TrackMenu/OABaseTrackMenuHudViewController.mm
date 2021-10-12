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
#import "Localization.h"
#import "OAColors.h"
#import "OAGPXDatabase.h"
#import "OAGPXDocument.h"

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
    if ([data.allKeys containsObject:kCellKey])
        _key = data[kCellKey];
    if ([data.allKeys containsObject:kCellType])
        _type = data[kCellType];
    if ([data.allKeys containsObject:kCellValues])
        _values = data[kCellValues];
    if ([data.allKeys containsObject:kCellTitle])
        _title = data[kCellTitle];
    if ([data.allKeys containsObject:kCellDesc])
        _desc = data[kCellDesc];
    if ([data.allKeys containsObject:kCellLeftIcon])
        _leftIcon = data[kCellLeftIcon];
    if ([data.allKeys containsObject:kCellRightIcon])
        _rightIcon = data[kCellRightIcon];
    if ([data.allKeys containsObject:kCellToggle])
        _toggle = [data[kCellToggle] boolValue];
    if ([data.allKeys containsObject:kCellOnSwitch])
        _onSwitch = data[kCellOnSwitch];
    if ([data.allKeys containsObject:kCellIsOn])
        _isOn = data[kCellIsOn];
    if ([data.allKeys containsObject:kTableUpdateData])
        _updateData = data[kTableUpdateData];
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
    if ([data.allKeys containsObject:kSectionCells])
        _cells = data[kSectionCells];
    if ([data.allKeys containsObject:kSectionHeader])
        _header = data[kSectionHeader];
    if ([data.allKeys containsObject:kSectionFooter])
        _header = data[kSectionFooter];
    if ([data.allKeys containsObject:kTableUpdateData])
        _updateData = data[kTableUpdateData];
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

        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _savingHelper = [OASavingTrackHelper sharedInstance];
        _mapPanelViewController = [OARootViewController instance].mapPanel;
        _mapViewController = _mapPanelViewController.mapViewController;
        [self updateGpxData];
        [self commonInit];
    }
    return self;
}

- (NSString *)getNibName
{
    return nil; //override
}

- (void)updateGpxData
{
    _isCurrentTrack = !_gpx || _gpx.gpxFilePath.length == 0 || _gpx.gpxFileName.length == 0;
    if (_isCurrentTrack)
    {
        if (!_gpx)
        _gpx = [_savingHelper getCurrentGPX];

        _gpx.gpxTitle = OALocalizedString(@"track_recording_name");
    }
    _doc = _isCurrentTrack ? (OAGPXDocument *) _savingHelper.currentTrack
            : [[OAGPXDocument alloc] initWithGpxFile:[_app.gpxPath stringByAppendingPathComponent:_gpx.gpxFilePath]];

    _analysis = [_doc getAnalysis:_isCurrentTrack ? 0
            : (long) [[OAUtilities getFileLastModificationDate:_gpx.gpxFilePath] timeIntervalSince1970]];

    _isShown = [_settings.mapSettingVisibleGpx.get containsObject:_gpx.gpxFilePath];
}

- (void)commonInit
{
    //override
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self applyLocalization];

    [self.backButton setImage:[UIImage templateImageNamed:@"ic_custom_arrow_back"] forState:UIControlStateNormal];
    self.backButton.imageView.tintColor = UIColorFromRGB(color_primary_purple);
    [self.backButton addBlurEffect:YES cornerRadius:12. padding:0];

    [self setupView];

    [self generateData];
    [self setupHeaderView];

    if (![self isLandscape])
        [self goExpanded];
    else
        [self goFullScreen];
}

- (void)applyLocalization
{
    //override
}

- (void)viewWillAppear:(BOOL)animated
{
    [self updateViewAnimated];
    [self show:YES
         state:[self isLandscape] ? EOADraggableMenuStateFullScreen : EOADraggableMenuStateExpanded
    onComplete:^{
        [_mapPanelViewController displayGpxOnMap:_gpx];
        [_mapPanelViewController setTopControlsVisible:NO
                                  customStatusBarStyle:[OAAppSettings sharedManager].nightMode
                                          ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault];
        _cachedYViewPort = _mapViewController.mapView.viewportYScale;
        [self adjustMapViewPort];
        [_mapPanelViewController targetSetBottomControlsVisible:YES
                                                     menuHeight:[self isLandscape] ? 0
                                                             : [self getViewHeight] - [OAUtilities getBottomMargin]
                                                       animated:YES];
        [self changeMapRulerPosition];
        [_mapPanelViewController.hudViewController updateMapRulerData];
    }];
}

- (void)hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete
{
    [super hide:YES duration:duration onComplete:^{
        [_mapPanelViewController.hudViewController resetToDefaultRulerLayout];
        [self restoreMapViewPort];
        [_mapPanelViewController hideScrollableHudViewController];
        [_mapPanelViewController targetSetBottomControlsVisible:YES menuHeight:0 animated:YES];
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
    self.backButtonLeadingConstraint.constant = [self isLandscape] ? self.tableView.frame.size.width : [OAUtilities getLeftMargin] + 10.;
    self.backButtonContainerView.hidden = ![self isLandscape] && self.currentState == EOADraggableMenuStateFullScreen;
}

- (void)adjustMapViewPort
{
    _mapViewController.mapView.viewportXScale = [self isLandscape] ? VIEWPORT_SHIFTED_SCALE : VIEWPORT_NON_SHIFTED_SCALE;
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

- (void)changeMapRulerPosition
{
    CGFloat bottomMargin = [self isLandscape] ? 0 : (-[self getViewHeight] + [OAUtilities getBottomMargin] - 20.);
    [_mapPanelViewController targetSetMapRulerPosition:bottomMargin
                                                  left:([self isLandscape] ? self.tableView.frame.size.width
                                                          : [OAUtilities getLeftMargin] + 20.)];
}

- (OAGPXTableCellData *)getCellData:(NSIndexPath *)indexPath
{
    return _tableData[indexPath.section].cells[indexPath.row];
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
    [self hide:YES duration:.2 onComplete:nil];
}

#pragma mark - OADraggableViewActions

- (void)onViewHeightChanged:(CGFloat)height
{
    [_mapPanelViewController targetSetBottomControlsVisible:YES
                                                 menuHeight:[self isLandscape] ? 0
                                                         : height - [OAUtilities getBottomMargin]
                                                   animated:YES];
    [self changeMapRulerPosition];
    [self adjustMapViewPort];
}

@end
