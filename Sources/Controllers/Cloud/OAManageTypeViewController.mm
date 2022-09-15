//
//  OAManageTypeViewController.mm
//  OsmAnd
//
//  Created by Skalii on 26.08.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAManageTypeViewController.h"
#import "OABaseBackupTypesViewController.h"
#import "OACustomBasicTableCell.h"
#import "OAExportSettingsType.h"
#import "OASettingsCategoryItems.h"
#import "OAColors.h"
#import "Localization.h"

@interface OAManageTypeViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAManageTypeViewController
{
    OAExportSettingsType *_settingsType;
    NSString *_size;
    NSArray<NSArray<NSDictionary *> *> *_data;
    NSMutableDictionary<NSNumber *, NSString *> *_footers;
}

- (instancetype)initWithSettingsType:(OAExportSettingsType *)settingsType size:(NSString *)size
{
    self = [super initWithNibName:@"OAManageTypeViewController" bundle:nil];
    if (self)
    {
        _settingsType = settingsType;
        _size = size;
        _footers = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.titleLabel.hidden = YES;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self increaseTableHeaderHeight];

    [self setupView];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (@available(iOS 13.0, *))
        return UIStatusBarStyleDarkContent;

    return UIStatusBarStyleDefault;
}

- (void)applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = _settingsType.title;
    [self.backButton setTitle:OALocalizedString(@"manage_storage") forState:UIControlStateNormal];
}

- (NSString *)getTableHeaderTitle
{
    return _settingsType.title;
}

- (void)onRotation
{
    [self increaseTableHeaderHeight];
}

- (void)increaseTableHeaderHeight
{
    UIView *tableHeaderView = self.tableView.tableHeaderView;
    CGRect frame = tableHeaderView.frame;
    frame.size.height += 21.;
    tableHeaderView.frame = frame;
}

- (void)setupView
{
    _data = @[
            @[@{
                    @"key" : @"size_cell",
                    @"type" : [OACustomBasicTableCell getCellIdentifier],
                    @"title" : OALocalizedString(@"res_size")
            }],
            @[@{
                    @"key" : @"delete_cell",
                    @"type" : [OACustomBasicTableCell getCellIdentifier],
                    @"title" : OALocalizedString(@"shared_string_delete_data")
            }]
    ];
    _footers[@(_data.count - 1)] = [NSString stringWithFormat:OALocalizedString(@"backup_delete_data_type_description"), _settingsType.title];
}

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

- (IBAction)backButtonClicked:(id)sender
{
    [self dismissViewController];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OACustomBasicTableCell getCellIdentifier]])
    {
        OACustomBasicTableCell *cell = [tableView dequeueReusableCellWithIdentifier:[OACustomBasicTableCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OACustomBasicTableCell getCellIdentifier] owner:self options:nil];
            cell = (OACustomBasicTableCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell rightIconVisibility:NO];
            [cell descriptionVisibility:NO];
            [cell switchVisibility:NO];
        }
        if (cell)
        {
            BOOL isSize = [item[@"key"] isEqualToString:@"size_cell"];
            cell.selectionStyle = isSize ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleDefault;
            cell.titleLabel.text = item[@"title"];
            cell.titleLabel.font = [UIFont systemFontOfSize:17. weight:isSize ? UIFontWeightRegular : UIFontWeightMedium];
            cell.titleLabel.textColor = isSize ? UIColor.blackColor : UIColorFromRGB(color_support_red);
            cell.valueLabel.text = isSize ? _size : @"";
        }
        return cell;
    }

    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return _footers[@(section)];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
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

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
