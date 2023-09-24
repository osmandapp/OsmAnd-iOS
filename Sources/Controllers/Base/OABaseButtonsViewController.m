//
//  OABaseButtonsViewController.m
//  OsmAnd Maps
//
//  Created by Skalii on 15.02.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseButtonsViewController.h"
#import "OATableDataModel.h"
#import "OAColors.h"
#import "OASizes.h"

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
        self.bottomBackgroundView.backgroundColor = bottomBackgroundColor;
    else
        [self.bottomBackgroundView addBlurEffect:YES cornerRadius:0. padding:0.];
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
    self.topButton.enabled = topButtonColorScheme != EOABaseButtonColorSchemeInactive;

    EOABaseButtonColorScheme bottomButtonColorScheme = [self getBottomButtonColorScheme];
    UIColor *bottomButtonTintColor = [self getButtonTintColor:bottomButtonColorScheme];
    [self.bottomButton setTitleColor:bottomButtonTintColor forState:UIControlStateNormal];
    self.bottomButton.tintColor = bottomButtonTintColor;
    self.bottomButton.backgroundColor = [self getButtonBackgroundColor:bottomButtonColorScheme];
    self.bottomButton.enabled = bottomButtonColorScheme != EOABaseButtonColorSchemeInactive;

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
    UILayoutConstraintAxis axisMode = [self getBottomAxisMode];
    UIFont *buttonFont = axisMode == UILayoutConstraintAxisVertical
        ? [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold maximumSize:20.]
        : [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.topButton.titleLabel.font = buttonFont;
    self.bottomButton.titleLabel.font = buttonFont;
}

- (UIColor *)getBottomBackgroundColor
{
    switch ([self getBottomColorScheme])
    {
        case EOABaseBottomColorSchemeBlank:
            return UIColorFromRGB(color_primary_table_background);
        case EOABaseBottomColorSchemeGray:
            return UIColorFromRGB(color_primary_gray_navbar_background);
        case EOABaseBottomColorSchemeWhite:
            return UIColor.whiteColor;
        default:
            return nil;
    }
}

- (UIColor *)getButtonTintColor:(EOABaseButtonColorScheme)scheme
{
    switch (scheme)
    {
        case EOABaseButtonColorSchemeInactive:
            return UIColorFromRGB(color_text_footer);
        case EOABaseButtonColorSchemeGrayAttn:
            return UIColorFromRGB(color_primary_red);
        case EOABaseButtonColorSchemePurple:
        case EOABaseButtonColorSchemeRed:
            return UIColor.whiteColor;
        default:
            return UIColorFromRGB(color_primary_purple);
    }
}

- (UIColor *)getButtonBackgroundColor:(EOABaseButtonColorScheme)scheme
{
    if ([self getBottomAxisMode] == UILayoutConstraintAxisHorizontal)
        return UIColor.clearColor;

    switch (scheme)
    {
        case EOABaseButtonColorSchemePurple:
            return UIColorFromRGB(color_primary_purple);
        case EOABaseButtonColorSchemeRed:
            return UIColorFromRGB(color_primary_red);
        default:
            return UIColorFromRGB(color_button_gray_background);
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

@end

// !!!
// remove from project:
//
//OABaseBigTitleSettingsViewController
