//
//  OAManageTypeViewController.mm
//  OsmAnd
//
//  Created by Skalii on 26.08.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAManageTypeViewController.h"
#import "OABaseBackupTypesViewController.h"
#import "OASimpleTableViewCell.h"
#import "OAValueTableViewCell.h"
#import "OAExportSettingsType.h"
#import "OASettingsCategoryItems.h"
#import "OAColors.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

@implementation OAManageTypeViewController
{
    OAExportSettingsType *_settingsType;
    NSString *_size;
    NSArray<NSArray<NSDictionary *> *> *_data;
    NSMutableDictionary<NSNumber *, NSString *> *_footers;
}

#pragma mark - Initialization

- (instancetype)initWithSettingsType:(OAExportSettingsType *)settingsType size:(NSString *)size
{
    self = [super init];
    if (self)
    {
        _settingsType = settingsType;
        _size = size;
        _footers = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return _settingsType.title;
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

- (BOOL)isNavbarSeparatorVisible
{
    return NO;
}

- (EOABaseNavbarStyle)getNavbarStyle
{
    return EOABaseNavbarStyleLargeTitle;
}

#pragma mark - Table data

- (void)generateData
{
    _data = @[
            @[@{
                    @"key" : @"size_cell",
                    @"type" : [OAValueTableViewCell getCellIdentifier],
                    @"title" : OALocalizedString(@"shared_string_size"),
                    @"value" : _size
            }],
            @[@{
                    @"key" : @"delete_cell",
                    @"type" : [OASimpleTableViewCell getCellIdentifier],
                    @"title" : OALocalizedString(@"shared_string_delete_data")
            }]
    ];
    _footers[@(_data.count - 1)] = [NSString stringWithFormat:OALocalizedString(@"backup_delete_data_type_description"), _settingsType.title];
}

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    return _footers[@(section)];
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *) nib[0];
            cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameButtonBgColorDisruptive];
            cell.titleLabel.font = [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightMedium];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.valueLabel.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.valueLabel.text = item[@"value"];
        }
        return cell;
    }

    return nil;
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

#pragma mark - UITableViewDelegate

- (CGFloat)getCustomHeightForHeader:(NSInteger)section
{
    if (section == 0)
        return 14.;

    return [super getCustomHeightForHeader:section];
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"key"] isEqualToString:@"delete_cell"])
    {
        UIAlertController *alert =
                             [UIAlertController alertControllerWithTitle:OALocalizedString(@"shared_string_delete_data")
                                                                 message:[NSString stringWithFormat:OALocalizedString(@"cloud_confirm_delete_type"), _settingsType.title]
                                                          preferredStyle:UIAlertControllerStyleAlert];

                     UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel")
                                                                            style:UIAlertActionStyleDefault
                                                                          handler:nil];

                     UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_delete")
                                                                                style:UIAlertActionStyleDefault
                                                                              handler:^(UIAlertAction * _Nonnull action)
                                                                              {
                                                                                  [self dismissViewController];

                                                                                  if (self.manageTypeDelegate)
                                                                                      [self.manageTypeDelegate onDeleteTypeData:_settingsType];
                                                                              }
                     ];

                     [alert addAction:cancelAction];
                     [alert addAction:deleteAction];

                     alert.preferredAction = deleteAction;

                     [self presentViewController:alert animated:YES completion:nil];
    }
}

@end
