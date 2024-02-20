//
//  OABaseButtonsViewController.m
//  OsmAnd Maps
//
//  Created by Skalii on 15.02.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseButtonsViewController.h"
#import "OATableDataModel.h"
#import "OsmAnd_Maps-Swift.h"
#import "OASizes.h"
#import "GeneratedAssetSymbols.h"

@interface OABaseButtonsViewController ()

@property (weak, nonatomic) IBOutlet UIView *bottomBackgroundView;
@property (weak, nonatomic) IBOutlet UIStackView *bottomStackView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *leftBottomMarginConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *rightBottomMarginConstraint;
@property (weak, nonatomic) IBOutlet UIView *aboveBottomMarginView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *aboveBottomMarginVertivalConstraint;
@property (weak, nonatomic) IBOutlet UIStackView *middleBottomMarginStackView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *middleFirstMarginViewVerticalConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *middleFirstMarginViewHorizontalConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *middleSecondMarginViewVerticalConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *middleSecondMarginViewHorizontalConstraint;
@property (weak, nonatomic) IBOutlet UIView *belowBottomMarginView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *belowBottomMarginVertivalConstraint;

@property (nonatomic) OATableDataModel *tableData;

@end

@implementation OABaseButtonsViewController
{
    BOOL _isBottomBackgroundViewBlurred;
}

@synthesize tableData;

#pragma mark - Initialization

- (instancetype)init
{
    self = [super initWithNibName:@"OABaseButtonsViewController" bundle:nil];
    if (self)
    {
        self.tableData = [OATableDataModel model];
        [self commonInit];
    }
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self updateBottomButtons];
}

#pragma mark - Base setup UI

- (void)updateBottomButtons
{
    [self setupBottomAxis];
    [self setupBottomButtons];
    [self setupBottomFonts];

    UIColor *bottomBackgroundColor = [self getBottomBackgroundColor];
    if (bottomBackgroundColor)
    {
        self.bottomBackgroundView.backgroundColor = bottomBackgroundColor;
    }
    else
    {
        if (!_isBottomBackgroundViewBlurred)
        {
            [self.bottomBackgroundView addBlurEffect:[ThemeManager shared].isLightTheme cornerRadius:0. padding:0.];
            _isBottomBackgroundViewBlurred = YES;
        }
    }
}

- (void)refreshUI
{
    [super refreshUI];
    [self updateBottomButtons];
}

- (void)setupBottomAxis
{
    UILayoutConstraintAxis axisMode = [self getBottomAxisMode];
    BOOL isVertical = axisMode == UILayoutConstraintAxisVertical;
    self.bottomStackView.axis = axisMode;
    self.aboveBottomMarginView.hidden = !isVertical;
    self.aboveBottomMarginVertivalConstraint.active = isVertical;
    self.leftBottomMarginConstraint.constant = isVertical ? kPaddingOnSideOfContent : (kSmallPaddingOnSideOfContent / 2);
    self.rightBottomMarginConstraint.constant = isVertical ? kPaddingOnSideOfContent : (kSmallPaddingOnSideOfContent / 2);
    self.middleBottomMarginStackView.axis = axisMode;
    self.middleBottomMarginStackView.distribution = isVertical ? UIStackViewDistributionFill : UIStackViewDistributionEqualSpacing;
    self.middleFirstMarginViewVerticalConstraint.active = isVertical;
    self.middleFirstMarginViewHorizontalConstraint.active = !isVertical;
    self.middleSecondMarginViewVerticalConstraint.active = isVertical;
    self.middleSecondMarginViewHorizontalConstraint.active = !isVertical;
    self.belowBottomMarginView.hidden = !isVertical;
    self.belowBottomMarginVertivalConstraint.active = isVertical;
}

- (void)setupBottomButtons
{
    UILayoutConstraintAxis axisMode = [self getBottomAxisMode];

    EOABaseButtonColorScheme topButtonColorScheme = [self getTopButtonColorScheme];
    UIColor *topButtonTintColor = [self getButtonTintColor:topButtonColorScheme];
    [self.topButton setTitleColor:topButtonTintColor forState:UIControlStateNormal];
    self.topButton.tintColor = topButtonTintColor;
    self.topButton.backgroundColor = [self getButtonBackgroundColor:topButtonColorScheme];
    self.topButton.enabled = topButtonColorScheme != EOABaseButtonColorSchemeInactive && topButtonColorScheme != EOABaseButtonColorSchemeBlank;

    EOABaseButtonColorScheme bottomButtonColorScheme = [self getBottomButtonColorScheme];
    UIColor *bottomButtonTintColor = [self getButtonTintColor:bottomButtonColorScheme];
    [self.bottomButton setTitleColor:bottomButtonTintColor forState:UIControlStateNormal];
    self.bottomButton.tintColor = bottomButtonTintColor;
    self.bottomButton.backgroundColor = [self getButtonBackgroundColor:bottomButtonColorScheme];
    self.bottomButton.enabled = bottomButtonColorScheme != EOABaseButtonColorSchemeInactive && bottomButtonColorScheme != EOABaseButtonColorSchemeBlank;

    NSString *topButtonTitle = [self getTopButtonTitle];
    NSAttributedString *topButtonTitleAttr = [self getTopButtonTitleAttr];
    NSString *topButtonIconName = [self getTopButtonIconName];
    BOOL hasTopButtonIcon = topButtonIconName && topButtonIconName.length > 0;
    BOOL hasTopButton = (topButtonTitle && topButtonTitle.length > 0) || (topButtonTitleAttr && topButtonTitleAttr.length > 0) || hasTopButtonIcon;
    if (axisMode == UILayoutConstraintAxisVertical)
    {
        self.topButton.hidden = !hasTopButton;
        self.topButton.contentEdgeInsets = UIEdgeInsetsMake(10., kSmallPaddingOnSideOfContent, 10., kSmallPaddingOnSideOfContent);
    }
    else
    {
        self.topButton.userInteractionEnabled = hasTopButton;
        self.topButton.contentEdgeInsets = UIEdgeInsetsMake(10., kSmallPaddingOnSideOfContent / 2, 10., kSmallPaddingOnSideOfContent / 2);
    }

    if (topButtonTitleAttr && topButtonTitleAttr.length > 0)
    {
        [self.topButton setTitle:nil forState:UIControlStateNormal];
        [self.topButton setAttributedTitle:topButtonTitleAttr forState:UIControlStateNormal];
    }
    else
    {
        [self.topButton setAttributedTitle:nil forState:UIControlStateNormal];
        [self.topButton setTitle:topButtonTitle forState:UIControlStateNormal];
    }
    [self.topButton setImage:hasTopButtonIcon ? [UIImage templateImageNamed:topButtonIconName] : nil forState:UIControlStateNormal];

    NSString *bottomButtonTitle = [self getBottomButtonTitle];
    NSAttributedString *bottomButtonTitleAttr = [self getBottomButtonTitleAttr];
    NSString *bottomButtonIconName = [self getBottomButtonIconName];
    BOOL hasBottomButtonIcon = bottomButtonIconName && bottomButtonIconName.length > 0;
    BOOL hasBottomButton = (bottomButtonTitle && bottomButtonTitle.length > 0) || (bottomButtonTitleAttr && bottomButtonTitleAttr.length > 0) || hasBottomButtonIcon;
    if (axisMode == UILayoutConstraintAxisVertical)
    {
        self.bottomButton.hidden = !hasBottomButton;
        self.bottomButton.contentEdgeInsets = UIEdgeInsetsMake(10., kSmallPaddingOnSideOfContent, 10., kSmallPaddingOnSideOfContent);
    }
    else
    {
        self.bottomButton.userInteractionEnabled = hasBottomButton;
        self.bottomButton.contentEdgeInsets = UIEdgeInsetsMake(10., kSmallPaddingOnSideOfContent / 2, 10., kSmallPaddingOnSideOfContent / 2);
    }

    if (bottomButtonTitleAttr && bottomButtonTitleAttr.length > 0)
    {
        [self.bottomButton setTitle:nil forState:UIControlStateNormal];
        [self.bottomButton setAttributedTitle:bottomButtonTitleAttr forState:UIControlStateNormal];
    }
    else
    {
        [self.bottomButton setAttributedTitle:nil forState:UIControlStateNormal];
        [self.bottomButton setTitle:bottomButtonTitle forState:UIControlStateNormal];
    }
    [self.bottomButton setImage:hasBottomButtonIcon ? [UIImage templateImageNamed:bottomButtonIconName] : nil forState:UIControlStateNormal];

    self.middleBottomMarginStackView.spacing = [self getSpaceBetweenButtons];
    self.middleBottomMarginStackView.hidden = axisMode == UILayoutConstraintAxisVertical && (!hasTopButton || !hasBottomButton);

    BOOL hasBottomButtons = hasTopButton || hasBottomButton;
    self.bottomBackgroundView.hidden = !hasBottomButtons;
    self.bottomStackView.hidden = !hasBottomButtons;
    self.separatorBottomView.hidden = !hasBottomButtons || ![self isBottomSeparatorVisible];
}

- (void)setupBottomFonts
{
    self.topButton.titleLabel.font = [self getButtonFont:[self getTopButtonColorScheme]];
    self.bottomButton.titleLabel.font = [self getButtonFont:[self getBottomButtonColorScheme]];
}

- (UIFont *)getButtonFont:(EOABaseButtonColorScheme)scheme
{
    return scheme == EOABaseButtonColorSchemeBlank || [self getBottomAxisMode] != UILayoutConstraintAxisVertical
            ? [UIFont preferredFontForTextStyle:UIFontTextStyleBody]
            : [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold maximumSize:20.];
}

- (UIColor *)getBottomBackgroundColor
{
    switch ([self getBottomColorScheme])
    {
        case EOABaseBottomColorSchemeBlank:
            return [UIColor colorNamed:ACColorNameViewBg];
        case EOABaseBottomColorSchemeGray:
            return [UIColor colorNamed:ACColorNameGroupBg];
        case EOABaseBottomColorSchemeWhite:
            return [UIColor colorNamed:ACColorNameGroupBg];
        default:
            return nil;
    }
}

- (UIColor *)getButtonTintColor:(EOABaseButtonColorScheme)scheme
{
    switch (scheme)
    {
        case EOABaseButtonColorSchemeBlank:
        case EOABaseButtonColorSchemeInactive:
            return [UIColor colorNamed:ACColorNameTextColorSecondary];
        case EOABaseButtonColorSchemeGrayAttn:
            return [UIColor colorNamed:ACColorNameButtonBgColorDisruptive];
        case EOABaseButtonColorSchemePurple:
        case EOABaseButtonColorSchemeRed:
            return [UIColor colorNamed:ACColorNameButtonTextColorPrimary];
        default:
            return [UIColor colorNamed:ACColorNameButtonTextColorSecondary];
    }
}

- (UIColor *)getButtonBackgroundColor:(EOABaseButtonColorScheme)scheme
{
    if ([self getBottomAxisMode] == UILayoutConstraintAxisHorizontal)
        return UIColor.clearColor;

    switch (scheme)
    {
        case EOABaseButtonColorSchemeBlank:
            return UIColor.clearColor;
        case EOABaseButtonColorSchemePurple:
            return [UIColor colorNamed:ACColorNameButtonBgColorPrimary];
        case EOABaseButtonColorSchemeRed:
            return [UIColor colorNamed:ACColorNameButtonBgColorDisruptive];
        default:
            return [UIColor colorNamed:ACColorNameButtonBgColorDisabled];
    }
}

#pragma mark - Base UI

- (UILayoutConstraintAxis)getBottomAxisMode
{
    return UILayoutConstraintAxisVertical;
}

- (EOABaseBottomColorScheme)getBottomColorScheme
{
    return EOABaseBottomColorSchemeBlurred;
}

- (CGFloat)getSpaceBetweenButtons
{
    return 0.;
}

- (NSString *)getTopButtonTitle
{
    return @"";
}

- (NSAttributedString *)getTopButtonTitleAttr
{
    return nil;
}

- (NSString *)getBottomButtonTitle
{
    return @"";
}

- (NSAttributedString *)getBottomButtonTitleAttr
{
    return nil;
}

- (NSString *)getTopButtonIconName
{
    return @"";
}

- (NSString *)getBottomButtonIconName
{
    return @"";
}

- (EOABaseButtonColorScheme)getTopButtonColorScheme
{
    return EOABaseButtonColorSchemeRed;
}

- (EOABaseButtonColorScheme)getBottomButtonColorScheme
{
    return EOABaseButtonColorSchemeGraySimple;
}

- (BOOL)isBottomSeparatorVisible
{
    return YES;
}

#pragma mark - IBAction

- (IBAction)onTopButtonPressed:(UIButton *)sender
{
    [self onTopButtonPressed];
}

- (IBAction)onBottomButtonPressed:(UIButton *)sender
{
    [self onBottomButtonPressed];
}

#pragma mark - Selectors

- (void)onTopButtonPressed
{
}

- (void)onBottomButtonPressed
{
}

- (void)onContentSizeChanged:(NSNotification *)notification
{
    [super onContentSizeChanged:notification];
    [self setupBottomButtons];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == [self sectionsCount])
        return 0.001;
    else if (section == 0 && [self hideFirstHeader])
        return 0.001;

    return [self getCustomHeightForHeader:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if (section == [self sectionsCount])
        return self.bottomBackgroundView.frame.size.height + kFooterHeightDefault;

    return [self getCustomHeightForFooter:section];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == [self sectionsCount])
        return nil;

    return [self getCustomViewForHeader:section];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (section == [self sectionsCount])
        return nil;

    return [self getCustomViewForFooter:section];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == [self sectionsCount])
        return 0.001;

    return [self rowsCount:section];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self sectionsCount] + 1;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == [self sectionsCount])
        return nil;

    return [self getTitleForHeader:section];
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == [self sectionsCount])
        return nil;

    return [self getTitleForFooter:section];
}

@end

// !!!
// remove from project:
//
//OABaseBigTitleSettingsViewController
