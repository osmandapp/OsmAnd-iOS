//
//  OAWhatsNewBottomSheetViewController.m
//  OsmAnd
//
//  Created by Max Kojin on 26.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAWhatsNewBottomSheetViewController.h"
#import "OAAppVersionDependedConstants.h"
#import "OATitleIconRoundCell.h"
#import "OADescrTitleCell.h"
#import "Localization.h"
#import "OAColors.h"

#define kIconTitleIconRoundCell @"OATitleIconRoundCell"
#define kDescrTitleCell @"OADescrTitleCell"

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
    self.tableView.sectionHeaderHeight = 16.;
    [self.leftIconView setImage:[UIImage imageNamed:@"ic_custom_poi.png"]];
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
    
    NSString *fullAppVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *title = [NSString stringWithFormat:OALocalizedString(@"latest_version"), fullAppVersion];
    NSString *releaseNotesKey = [NSString stringWithFormat:@"ios_release_%@", [OAAppVersionDependedConstants getShortAppVersionWithSeparator:@"_"]];
    
    [data addObject:@[
        @{
             @"type" : kDescrTitleCell,
             @"title" : title,
             @"description" : OALocalizedString(releaseNotesKey)
        }]];
    _data = data;
}

- (void) onRightButtonPressed
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kLatestChangesUrl] options: @{} completionHandler:nil];
    [super onRightButtonPressed];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    
    if ([item[@"type"] isEqualToString:kIconTitleIconRoundCell])
    {
        static NSString* const identifierCell = kIconTitleIconRoundCell;
        OATitleIconRoundCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kIconTitleIconRoundCell owner:self options:nil];
            cell = (OATitleIconRoundCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
        }
        if (cell)
        {
            [cell roundCorners:(indexPath.row == 0) bottomCorners:(indexPath.row == _data[indexPath.section].count - 1)];
            cell.titleView.text = item[@"title"];
            
            
            UIColor *tintColor = item[@"custom_color"];
            if (tintColor)
            {
                cell.iconColorNormal = tintColor;
                cell.textColorNormal = tintColor;
                cell.iconView.image = [[UIImage imageNamed:item[@"img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            }
            else
            {
                cell.textColorNormal = nil;
                cell.iconView.image = [UIImage imageNamed:item[@"img"]];
                cell.titleView.textColor = UIColor.blackColor;
                cell.separatorView.hidden = indexPath.row == _data[indexPath.section].count - 1;
            }
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kDescrTitleCell])
    {
        OADescrTitleCell* cell;
        cell = (OADescrTitleCell *)[self.tableView dequeueReusableCellWithIdentifier:kDescrTitleCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kDescrTitleCell owner:self options:nil];
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
            NSString *labelText = [NSString stringWithFormat:@"%@\n\n%@", item[@"title"], item[@"description"]];
            NSRange boldRange = NSMakeRange(0, ((NSString *)item[@"title"]).length);
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
            
            cell.descriptionView.attributedText = attributedString;
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

@end
