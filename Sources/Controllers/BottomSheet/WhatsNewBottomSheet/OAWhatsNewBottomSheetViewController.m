
//
//  OAWhatsNewBottomSheetViewController.m
//  OsmAnd
//
//  Created by Max Kojin on 26.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAWhatsNewBottomSheetViewController.h"
#import "OAAppVersion.h"
#import "OASimpleTableViewCell.h"
#import "Localization.h"
#import "OALinks.h"
#import "OARootViewController.h"

#define kVerticalMargin 16.
#define kHorizontalMargin 20.

@interface OAWhatsNewBottomSheetViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAWhatsNewBottomSheetViewController
{
    NSArray<NSArray<NSDictionary *> *> *_data;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.sectionHeaderHeight = kVerticalMargin;
    [self.leftIconView setImage:[UIImage imageNamed:@"ic_custom_poi.png"]];
}

- (void) adjustFrame
{
    if (!OAUtilities.isLandscapeIpadAware && [self screenHeight] > 0.75 * DeviceScreenHeight)
        [self goFullScreen];

    [super adjustFrame];
}

- (void) applyLocalization
{
    self.titleView.text = [NSString stringWithFormat:OALocalizedString(@"help_what_is_new")];
    [self.leftButton setTitle:OALocalizedString(@"shared_string_close") forState:UIControlStateNormal];
    [self.rightButton setTitle:OALocalizedString(@"shared_string_read_more") forState:UIControlStateNormal];
}

- (void) generateData
{
    NSMutableArray *data = [NSMutableArray new];
    [data addObject:@[
        @{
             @"type" : [OASimpleTableViewCell getCellIdentifier],
             @"attributedText" : [self getAttributedContentText]
        }]];
    _data = data;
}

- (NSMutableAttributedString *)getAttributedContentText
{
    NSString *title = [NSString stringWithFormat:OALocalizedString(@"latest_version"), OAAppVersion.getVersion];
    NSString *description = OALocalizedString([NSString stringWithFormat:@"ios_release_%@", [OAAppVersion getVersionWithSeparator:@"_"]]);
    
    NSString *labelText = [NSString stringWithFormat:@"%@\n\n%@", title, description];
    NSRange boldRange = NSMakeRange(0, title.length);
    NSRange fullRange = NSMakeRange(0, labelText.length);
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:labelText];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:5];
    [paragraphStyle setLineHeightMultiple:0.8];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:fullRange];
    
    UIFont *regularFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    UIFont *semiboldFont = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    [attributedString addAttribute:NSFontAttributeName value:regularFont range:fullRange];
    [attributedString addAttribute:NSFontAttributeName value:semiboldFont range:boldRange];
    
    return attributedString;
}

- (CGFloat)screenHeight
{
    CGFloat width = DeviceScreenWidth - 2 * kHorizontalMargin;
    CGFloat headerHeight = self.headerView.frame.size.height;
    CGFloat contentHeight = [OAUtilities calculateTextBounds:[self getAttributedContentText] width:width].height;
    CGFloat buttonsHeight = 60. + [OAUtilities getBottomMargin];
    return headerHeight + contentHeight + buttonsHeight + 2 * kVerticalMargin;
}

- (void) onRightButtonPressed
{
    [super onRightButtonPressed];
    [OARootViewController.instance openSafariWithURL:kDocsLatestVersion];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    if ([item[@"type"] isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.backgroundColor = UIColor.clearColor;
            cell.contentView.backgroundColor = UIColor.clearColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.titleLabel.backgroundColor = UIColor.clearColor;
            cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        }
        if (cell)
        {
            cell.titleLabel.attributedText = item[@"attributedText"];
        }
        return cell;
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return kVerticalMargin;
}

@end
