//
//  OABaseSettingsViewController.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 25.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseSettingsViewController.h"
#import "OAColors.h"
#import "OASizes.h"
#import "OAApplicationMode.h"
#import "Localization.h"

#define kSidePadding 20

@interface OABaseSettingsViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OABaseSettingsViewController
{
    UIView *_tableHeaderView;
}

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode
{
    self = [super initWithNibName:@"OABaseSettingsViewController" bundle:nil];
    if (self) {
        _appMode = appMode;
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    [self.backButton setImage:[UIImage imageNamed:@"ic_navbar_chevron"].imageFlippedForRightToLeftLayoutDirection forState:UIControlStateNormal];
    [self setupNavBarHeight];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self setupNavBarHeight];
}

- (void)applyLocalization
{
    self.subtitleLabel.text = _appMode.toHumanString;
}

- (void) commonInit
{
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (void) setupNavBarHeight
{
    self.navBarHeightConstraint.constant = [self isModal] ? [OAUtilities isLandscape] ? defaultNavBarHeight : modalNavBarHeight : defaultNavBarHeight;
}

- (void) setupTableHeaderViewWithText:(NSString *)text
{
    CGFloat textWidth = DeviceScreenWidth - (kSidePadding + OAUtilities.getLeftMargin) * 2;
    CGFloat textHeight = [self heightForLabel:text];
    _tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, DeviceScreenWidth, textHeight + kSidePadding)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kSidePadding + OAUtilities.getLeftMargin, kSidePadding, textWidth, textHeight)];
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineSpacing:6];
    label.attributedText = [[NSAttributedString alloc] initWithString:text
                                                        attributes:@{NSParagraphStyleAttributeName : style,
                                                        NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer),
                                                        NSFontAttributeName : [UIFont scaledSystemFontOfSize:13.0],
                                                        NSBackgroundColorAttributeName : UIColor.clearColor}];
    label.textAlignment = NSTextAlignmentLeft;
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _tableHeaderView.backgroundColor = UIColor.clearColor;
    [_tableHeaderView addSubview:label];
    self.tableView.tableHeaderView = _tableHeaderView;
}

-(void) addAccessibilityLabels
{
    self.backButton.accessibilityLabel = OALocalizedString(@"shared_string_back");
}

- (void) showCancelButtonWithBackButton
{
    self.backButton.hidden = NO;
    self.cancelButton.hidden = NO;
    self.cancelButtonLeftConstraint.constant = 8 + self.backButton.frame.size.width;
}

- (IBAction) backButtonPressed:(id)sender
{
    [self dismissViewController];
}

- (IBAction)cancelButtonPressed:(id)sender
{
    [self dismissViewController];
}

- (IBAction)doneButtonPressed:(id)sender
{
    
}

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return nil;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat) heightForLabel:(NSString *)text
{
    UIFont *labelFont = [UIFont scaledSystemFontOfSize:[self fontSizeForLabel]];
    CGFloat textWidth = DeviceScreenWidth - (kSidePadding + OAUtilities.getLeftMargin) * 2;
    return [OAUtilities heightForHeaderViewText:text width:textWidth font:labelFont lineSpacing:6.0];
}

- (CGFloat)fontSizeForLabel
{
    return 15.;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *) view;
        headerView.textLabel.textColor = UIColorFromRGB(color_text_footer);
    }
}

- (void) tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView *headerView = (UITableViewHeaderFooterView *) view;
        headerView.textLabel.textColor = UIColorFromRGB(color_text_footer);
    }
}

#pragma mark - OASettingsDataDelegate

- (void) onSettingsChanged
{
    [_tableView reloadData];
}

@end
