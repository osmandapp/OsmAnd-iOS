//
//  OAOsmandDevelopmentSimulateSpeedSelectorViewController.m
//  OsmAnd Maps
//
//  Created by nnngrach on 02.06.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAOsmandDevelopmentSimulateSpeedSelectorViewController.h"
#import "OAOpenAddTrackViewController.h"
#import "Localization.h"
#import "OAColors.h"

@interface OAOsmandDevelopmentSimulateSpeedSelectorViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAOsmandDevelopmentSimulateSpeedSelectorViewController
{
    NSArray<NSArray *> *_data;
    NSString *_headerDescription;
    NSInteger _selectedSpeedModeIndex;
}

NSString *const kUICellKey = @"kUICellKey";
NSString *const kOriginalSpeedKey = @"kOriginalSpeedKey";
NSString *const kSpeedUpTwoKey = @"kSpeedUpTwoKey";
NSString *const kSpeedUpThreeKey = @"kSpeedUpThreeKey";
NSString *const kSpeedUpFourKey = @"kSpeedUpFourKey";

- (instancetype) init
{
    self = [super initWithNibName:@"OABaseSettingsViewController" bundle:nil];
    if (self)
    {
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 16.0 + OAUtilities.getLeftMargin, 0., 0.);
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self generateData];
    [self.tableView reloadData];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (_speedSelectorDelegate)
        [_speedSelectorDelegate onSpeedSelectorInformationUpdated:_selectedSpeedModeIndex];
}


#pragma mark - Setup data

- (void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"simulate_location_movement_speed");
}

- (void) generateData
{
    _selectedSpeedModeIndex = 0; //TODO: fetch from settings
    
    NSString *footerText;
    if (_selectedSpeedModeIndex == 0)
        footerText = OALocalizedString(@"simulate_location_movement_speed_original_desc");
    else if (_selectedSpeedModeIndex == 1)
        footerText = OALocalizedString(@"simulate_location_movement_speed_x2_desc");
    else if (_selectedSpeedModeIndex == 2)
        footerText = OALocalizedString(@"simulate_location_movement_speed_x3_desc");
    else
        footerText = OALocalizedString(@"simulate_location_movement_speed_x4_desc");
    
    NSMutableArray *tableData = [NSMutableArray array];
    NSMutableArray *speedSection = [NSMutableArray array];
    [speedSection addObject:@{
        @"type" : kUICellKey,
        @"key" : kOriginalSpeedKey,
        @"title" : OALocalizedString(@"simulate_location_movement_speed_original"),
        @"descr" : @"",
        @"selected" : @(_selectedSpeedModeIndex == 0),
        @"hederTitle" : @"",
        @"footerTitle" : footerText,
    }];
    [speedSection addObject:@{
        @"type" : kUICellKey,
        @"key" : kSpeedUpTwoKey,
        @"title" :OALocalizedString(@"simulate_location_movement_speed_x2"),
        @"descr" : @"",
        @"selected" : @(_selectedSpeedModeIndex == 1),
    }];
    [speedSection addObject:@{
        @"type" : kUICellKey,
        @"key" : kSpeedUpThreeKey,
        @"title" : OALocalizedString(@"simulate_location_movement_speed_x3"),
        @"descr" : @"",
        @"selected" : @(_selectedSpeedModeIndex == 2),
    }];
    [speedSection addObject:@{
        @"type" : kUICellKey,
        @"key" : kSpeedUpFourKey,
        @"title" : OALocalizedString(@"simulate_location_movement_speed_x4"),
        @"descr" : @"",
        @"selected" : @(_selectedSpeedModeIndex == 3),
    }];
    [tableData addObject:speedSection];
    
    _data = [NSArray arrayWithArray:tableData];
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}


#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _data[section].count;
}

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = [self getItem:indexPath];
    NSString *cellType = item[@"type"];
    if ([cellType isEqualToString:kUICellKey])
    {
        UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:kUICellKey];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:kUICellKey];
        }
        if ([item[@"selected"] boolValue])
            cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"menu_cell_selected.png"]];
        else
            cell.accessoryView = nil;
        
        NSString *regularText = item[@"title"];
        cell.textLabel.text = regularText;
        return cell;
    }
    return nil;
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSDictionary *item = [self getItem:[NSIndexPath indexPathForRow:0 inSection:section]];
    return item[@"footerTitle"];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *)view;
    [footer.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    NSDictionary *item = [self getItem:indexPath];
    NSString *itemKey = item[@"key"];
    
    if ([itemKey isEqualToString:kOriginalSpeedKey])
        _selectedSpeedModeIndex = 0;
    else if ([itemKey isEqualToString:kSpeedUpTwoKey])
        _selectedSpeedModeIndex = 1;
    else if ([itemKey isEqualToString:kSpeedUpThreeKey])
        _selectedSpeedModeIndex = 2;
    else if ([itemKey isEqualToString:kSpeedUpFourKey])
        _selectedSpeedModeIndex = 3;
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

