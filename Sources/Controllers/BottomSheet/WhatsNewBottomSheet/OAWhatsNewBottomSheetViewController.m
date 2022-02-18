
//
//  OAWhatsNewBottomSheetViewController.m
//  OsmAnd
//
//  Created by Max Kojin on 26.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAWhatsNewBottomSheetViewController.h"
#import "OAAppVersionDependentConstants.h"
#import "OADescrTitleCell.h"
#import "Localization.h"
#import "OAColors.h"
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
             @"type" : [OADescrTitleCell getCellIdentifier],
             @"attributedText" : [self getAttributedContentText]
        }]];
    _data = data;
}

- (NSMutableAttributedString *)getAttributedContentText
{
    NSString *fullAppVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *title = [NSString stringWithFormat:OALocalizedString(@"latest_version"), fullAppVersion];
    NSString *description = OALocalizedString([NSString stringWithFormat:@"ios_release_%@", [OAAppVersionDependentConstants getShortAppVersion]]);
    
    NSString *labelText = [NSString stringWithFormat:@"%@\n\n%@", title, description];
    NSRange boldRange = NSMakeRange(0, title.length);
    NSRange fullRange = NSMakeRange(0, labelText.length);
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:labelText];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    [paragraphStyle setLineSpacing:5];
    [paragraphStyle setLineHeightMultiple:0.8];
    [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:fullRange];
    
    UIFont *regularFont = [UIFont systemFontOfSize:17 weight:UIFontWeightRegular];
    UIFont *semiboldFont = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
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
    [OARootViewController.instance openSafariWithURL:kLatestChangesUrl];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    if ([item[@"type"] isEqualToString:[OADescrTitleCell getCellIdentifier]])
    {
        OADescrTitleCell* cell;
        cell = (OADescrTitleCell *)[self.tableView dequeueReusableCellWithIdentifier:[OADescrTitleCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADescrTitleCell getCellIdentifier] owner:self options:nil];
            cell = (OADescrTitleCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.contentView.backgroundColor = UIColor.clearColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.descriptionView.textColor = [UIColor blackColor];
            cell.descriptionView.backgroundColor = UIColor.clearColor;
            cell.textView.hidden = YES;
        }
        if (cell)
        {
            cell.descriptionView.attributedText = item[@"attributedText"];
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
