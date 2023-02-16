//
//  OABaseButtonsViewController.m
//  OsmAnd Maps
//
//  Created by Skalii on 15.02.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseButtonsViewController.h"
#import "OAColors.h"
#import "OASizes.h"

@interface OABaseButtonsViewController ()

@property (weak, nonatomic) IBOutlet UIView *bottomBackgroundView;
@property (weak, nonatomic) IBOutlet UIStackView *middleBottomMarginStackView;

@end

@implementation OABaseButtonsViewController

#pragma mark - Initialization

- (instancetype)init
{
    self = [super initWithNibName:@"OABaseButtonsViewController" bundle:nil];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupBottomButtons];
    [self setupBottomFonts];
    
    self.separatorBottomView.hidden = ![self isBottomSeparatorVisible];
    self.middleBottomMarginStackView.spacing = [self getSpaceBetweenButtons];
    
    UIColor *bottomBackgroundColor = [self getBottomBackgroundColor];
    if (bottomBackgroundColor)
        self.bottomBackgroundView.backgroundColor = bottomBackgroundColor;
    else
        [self.bottomBackgroundView addBlurEffect:YES cornerRadius:0. padding:0.];
}

#pragma mark - Base setup UI

- (void)setupBottomButtons
{
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
    BOOL hasTopButton = topButtonTitle && topButtonTitle.length > 0;
    self.topButton.hidden = !hasTopButton;
    [self.topButton setTitle:topButtonTitle forState:UIControlStateNormal];
    
    NSString *bottomButtonTitle = [self getBottomButtonTitle];
    BOOL hasBottomButton = bottomButtonTitle && bottomButtonTitle.length > 0;
    self.bottomButton.hidden = !hasBottomButton;
    [self.bottomButton setTitle:bottomButtonTitle forState:UIControlStateNormal];
    
    self.middleBottomMarginStackView.hidden = !hasTopButton || !hasBottomButton;
}

- (void)setupBottomFonts
{
    self.topButton.titleLabel.font = [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];
    self.bottomButton.titleLabel.font = [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];
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

- (NSString *)getBottomButtonTitle
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
