//
//  OAManageTypeViewController.mm
//  OsmAnd
//
//  Created by Skalii on 26.08.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAManageTypeViewController.h"
#import "OABaseBackupTypesViewController.h"
#import "OAIconTitleValueCell.h"
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
    NSMutableArray<NSMutableDictionary *> *_data;
}

- (instancetype)initWithSettingsType:(OAExportSettingsType *)settingsType size:(NSString *)size
{
    self = [super initWithNibName:@"OAManageTypeViewController" bundle:nil];
    if (self)
    {
        _settingsType = settingsType;
        _size = size;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    [self.backButton setImage:[UIImage templateImageNamed:@"ic_navbar_chevron"] forState:UIControlStateNormal];

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

- (void)setupView
{
    NSMutableArray *data = [NSMutableArray array];

    NSMutableArray<NSMutableDictionary *> *sizeCells = [NSMutableArray array];
    NSMutableDictionary *sizeSection = [NSMutableDictionary dictionary];
    sizeSection[@"header"] = OALocalizedString(@"my_places");
    sizeSection[@"cells"] = sizeCells;
    [data addObject:sizeSection];

    NSMutableDictionary *sizeData = [NSMutableDictionary dictionary];
    sizeData[@"key"] = @"size_cell";
    sizeData[@"type"] = [OAIconTitleValueCell getCellIdentifier];
    sizeData[@"title"] = OALocalizedString(@"res_size");
    [sizeCells addObject:sizeData];

    NSMutableArray<NSMutableDictionary *> *deleteCells = [NSMutableArray array];
    NSMutableDictionary *deleteSection = [NSMutableDictionary dictionary];
    deleteSection[@"cells"] = deleteCells;
    deleteSection[@"footer"] = [NSString stringWithFormat:OALocalizedString(@"backup_delete_data_type_description"), _settingsType.title];
    [data addObject:deleteSection];

    NSMutableDictionary *deleteData = [NSMutableDictionary dictionary];
    deleteData[@"key"] = @"delete_cell";
    deleteData[@"type"] = [OAIconTitleValueCell getCellIdentifier];
    deleteData[@"title"] = OALocalizedString(@"shared_string_delete_data");
    [deleteCells addObject:deleteData];

    _data = data;
}

- (NSMutableDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][@"cells"][indexPath.row];
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
    return ((NSArray *) _data[section][@"cells"]).count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *outCell = nil;

    NSDictionary *item = [self getItem:indexPath];
    NSString *cellType = item[@"type"];

    if ([cellType isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAIconTitleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTitleValueCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleValueCell *) nib[0];
            [cell showLeftIcon:NO];
            [cell showRightIcon:NO];
        }
        if (cell)
        {
            BOOL isSize = [item[@"key"] isEqualToString:@"size_cell"];
            cell.selectionStyle = isSize ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleDefault;
            cell.textView.text = item[@"title"];
            cell.textView.font = [UIFont systemFontOfSize:17. weight:isSize ? UIFontWeightRegular : UIFontWeightMedium];
            cell.textView.textColor = isSize ? UIColor.blackColor : UIColorFromRGB(color_support_red);
            cell.descriptionView.text = isSize ? _size : @"";
        }
        outCell = cell;
    }

    [outCell updateConstraintsIfNeeded];
    return outCell;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return _data[section][@"footer"];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"key"] isEqualToString:@"delete_cell"])
    {
        [self dismissViewController];

        if (self.manageTypeDelegate)
            [self.manageTypeDelegate onDeleteTypeData:_settingsType];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
