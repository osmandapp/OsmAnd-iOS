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
    if ([self isModal])
        self.navBarHeightConstraint.constant = modalNavBarHeight;
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
                                                        NSFontAttributeName : [UIFont systemFontOfSize:15.0],
                                                        NSBackgroundColorAttributeName : UIColor.clearColor}];
    label.textAlignment = NSTextAlignmentLeft;
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _tableHeaderView.backgroundColor = UIColor.clearColor;
    [_tableHeaderView addSubview:label];
    self.tableView.tableHeaderView = _tableHeaderView;
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
    UIFont *labelFont = [UIFont systemFontOfSize:15.0];
    CGFloat textWidth = DeviceScreenWidth - (kSidePadding + OAUtilities.getLeftMargin) * 2;
    return [OAUtilities heightForHeaderViewText:text width:textWidth font:labelFont lineSpacing:6.0];
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
