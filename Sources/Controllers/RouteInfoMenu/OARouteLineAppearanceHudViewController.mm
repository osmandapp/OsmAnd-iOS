//
//  OARouteLineAppearanceHudViewController.mm
//  OsmAnd
//
//  Created by Skalii on 20.12.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OARouteLineAppearanceHudViewController.h"
#import "OARootViewController.h"
#import "OAMapHudViewController.h"
#import "OATableViewCustomFooterView.h"
#import "OAIconTitleValueCell.h"
#import "OAPreviewRouteLineInfo.h"
#import "OAColors.h"
#import "Localization.h"
#import "OsmAndApp.h"

@interface OARouteLineAppearanceHudViewController() <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate>

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
    OAApplicationMode *_appMode;
    OAMapPanelViewController *_mapPanelViewController;

    OAPreviewRouteLineInfo *_previewRouteLineInfo;
    OAColoringType *_selectedColoringType;

    OAColoringType *_oldColoringType;
    CGFloat _originalStatusBarHeight;
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
    _mapPanelViewController = [OARootViewController instance].mapPanel;
    _previewRouteLineInfo = [self createPreviewRouteLineInfo];

    [self setOldValues];
    [self updateAllValues];
}

- (void)setOldValues
{

}

- (void)updateAllValues
{

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self applyLocalization];

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

- (void)applyLocalization
{

}

- (void)hide:(BOOL)animated duration:(NSTimeInterval)duration onComplete:(void (^)(void))onComplete
{
    [super hide:YES duration:duration onComplete:^{
        [_mapPanelViewController.hudViewController resetToDefaultRulerLayout];
        [_mapPanelViewController hideScrollableHudViewController];
        if (onComplete)
            onComplete();
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

- (void)generateData
{

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

//    previewRouteLineInfo.setIconId(appMode.getNavigationIcon().getIconId());
//    previewRouteLineInfo.setIconColor(appMode.getProfileColor(isNightMode()));

    return previewRouteLineInfo;
}

- (void)changeHud:(CGFloat)height
{
    [_mapPanelViewController targetSetBottomControlsVisible:YES
                                                 menuHeight:[self isLandscape] ? 0 : height - [OAUtilities getBottomMargin]
                                                   animated:YES];
    [self changeMapRulerPosition:height];
}

- (IBAction)onBackButtonPressed:(id)sender
{
    [self hide:YES duration:.2 onComplete:^{
        if (self.delegate)
            [self.delegate onCloseAppearance];
    }];
}

- (IBAction)onApplyButtonPressed:(id)sender
{
    [self hide:YES duration:.2 onComplete:^{
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
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
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
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;
        cell.textView.text = @"Test";
        cell.descriptionView.text = @"test";
        cell.textView.textColor = UIColorFromRGB(color_primary_purple);
    }

    if ([cell needsUpdateConstraints])
        [cell updateConstraints];

    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return section == 0 ? 0.001 : tableView.sectionHeaderHeight;
}

@end
