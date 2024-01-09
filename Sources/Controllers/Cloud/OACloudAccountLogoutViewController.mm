//
//  OACloudAccountLogoutViewController.mm
//  OsmAnd
//
//  Created by Skalii on 21.08.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OACloudAccountLogoutViewController.h"
#import "OAValueTableViewCell.h"
#import "OAAppSettings.h"
#import "OsmAnd_Maps-Swift.h"
#import "Localization.h"
#import "GeneratedAssetSymbols.h"

@implementation OACloudAccountLogoutViewController
{
    NSArray<NSArray<NSDictionary *> *> *_data;
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"login_account");
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

#pragma mark - Table data

- (void)generateData
{
    _data = @[
            @[@{
                    @"key": @"user_cell",
                    @"type": [OAValueTableViewCell getCellIdentifier],
                    @"title": [[OAAppSettings sharedManager].backupUserEmail get],
                    @"icon": @"ic_custom_user_profile"
            }],
            @[@{
                    @"key": @"logout_cell",
                    @"type": [OAValueTableViewCell getCellIdentifier],
                    @"title": OALocalizedString(@"shared_string_logout")
            }]
    ];
}

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    UITableViewCell *outCell = nil;

    if ([item[@"type"] isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
            [cell valueVisibility:NO];
        }
        if (cell)
        {
            BOOL isLogoutCell = [item[@"key"] isEqualToString:@"logout_cell"];
            cell.selectionStyle = isLogoutCell ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
            [cell leftIconVisibility:!isLogoutCell];
            cell.titleLabel.font = [UIFont scaledSystemFontOfSize:17. weight:isLogoutCell ? UIFontWeightMedium : UIFontWeightRegular];
            cell.titleLabel.text = item[@"title"];
            cell.titleLabel.textColor = isLogoutCell ? [UIColor colorNamed:ACColorNameButtonBgColorDisruptive] : [UIColor colorNamed:ACColorNameTextColorPrimary];
            cell.titleLabel.textAlignment = isLogoutCell ? NSTextAlignmentCenter : NSTextAlignmentNatural;
            cell.leftIconView.image = [UIImage templateImageNamed:item[@"icon"]];
            cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorDefault];
        }
        outCell = cell;
    }

    [outCell updateConstraintsIfNeeded];
    return outCell;
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"key"] isEqualToString:@"logout_cell"])
    {

        UIAlertController *alert =
                [UIAlertController alertControllerWithTitle:OALocalizedString(@"shared_string_logout")
                                                    message:OALocalizedString(@"logout_from_osmand_cloud_decsr")
                                             preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel")
                                                               style:UIAlertActionStyleDefault
                                                             handler:nil
        ];

        UIAlertAction *logoutAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_logout")
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * _Nonnull action)
                                                                 {

                                                                     if (self.logoutDelegate)
                                                                         [self.logoutDelegate onLogout];

                                                                     [self dismissViewController];
                                                                 }
        ];

        [alert addAction:cancelAction];
        [alert addAction:logoutAction];

        alert.preferredAction = logoutAction;

        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end
