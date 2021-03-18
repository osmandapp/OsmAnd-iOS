//
//  OASelectFavoriteGroupViewController.m
//  OsmAnd Maps
//
//  Created by nnngrach on 16.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OASelectFavoriteGroupViewController.h"
#import "OAFavoriteItem.h"
#import "OAFavoritesHelper.h"
#import "OAColors.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OASettingsTableViewCell.h"
#import "OATitleRightIconCell.h"
#import "OAMultiIconTextDescCell.h"
#import "OAAddFavoriteGroupViewController.h"
#import "OsmAndApp.h"

#define kCellTypeAction @"OATitleRightIconCell"
#define kMultiIconTextDescCell @"OAMultiIconTextDescCell"
#define kAddNewGroupSection 0
#define kGroupsListSection 1

@interface OASelectFavoriteGroupViewController() <UITableViewDelegate, UITableViewDataSource, OAAddFavoriteGroupDelegate>

@end

@implementation OASelectFavoriteGroupViewController
{
    OsmAndAppInstance _app;
    NSString *_selectedGroupName;
    NSArray<OAFavoriteGroup *> *_groupedFavorites;
    NSArray<NSArray<NSDictionary *> *> *_data;
}

- (instancetype) initWithSelectedGroupName:(NSString *)selectedGroupName;
{
    self = [super initWithNibName:@"OABaseTableViewController" bundle:nil];
    if (self)
    {
        _selectedGroupName = selectedGroupName;
        _app = [OsmAndApp instance];
        [self reloadData];
        [self generateData];
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorColor = UIColorFromRGB(color_tint_gray);
    self.tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:OALocalizedString(@"select_gropu_descr") font:[UIFont systemFontOfSize:15.] textColor:UIColor.blackColor lineSpacing:0. isTitle:NO];
}

- (void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"select_group");
}

- (void) reloadData
{
    _groupedFavorites = [OAFavoritesHelper getFavoriteGroups];
}

- (void) generateData
{
    NSMutableArray *data = [NSMutableArray new];
    [data addObject:@[
        @{
            @"type" : kCellTypeAction,
            @"title" : OALocalizedString(@"fav_add_new_group"),
            @"img" : @"ic_custom_add",
        },
    ]];
    
    NSMutableArray *cellFoldersData = [NSMutableArray new];
    for (OAFavoriteGroup *group in _groupedFavorites)
    {
        NSString *name = group.name;
        if (!name || name.length == 0)
            name = OALocalizedString(@"favorites");
        
        [cellFoldersData addObject:@{
            @"type" : kMultiIconTextDescCell,
            @"header" : OALocalizedString(@"available_groups"),
            @"title" : name,
            @"description" : [NSString stringWithFormat:@"%i", group.points.count],
            @"isSelected" : [NSNumber numberWithBool:[name isEqualToString: _selectedGroupName]],
            @"color" : group.color,
            @"img" : @"ic_custom_folder"
        }];
    }
    
    [data addObject: [NSArray arrayWithArray:cellFoldersData]];
    _data = data;
}

#pragma mark - UITableViewDataSource

- (nonnull UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    
    if ([cellType isEqualToString:kCellTypeAction])
    {
        static NSString* const identifierCell = kCellTypeAction;
        OATitleRightIconCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kCellTypeAction owner:self options:nil];
            cell = (OATitleRightIconCell *)[nib objectAtIndex:0];
            cell.titleView.textColor = UIColorFromRGB(color_primary_purple);
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.titleView.font = [UIFont systemFontOfSize:17. weight:UIFontWeightSemibold];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.titleView.text = item[@"title"];
        [cell.iconView setImage:[[UIImage imageNamed:item[@"img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        return cell;
    }
   
    else if ([cellType isEqualToString:kMultiIconTextDescCell])
    {
        OAMultiIconTextDescCell* cell = (OAMultiIconTextDescCell *)[tableView dequeueReusableCellWithIdentifier:kMultiIconTextDescCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kMultiIconTextDescCell owner:self options:nil];
            cell = (OAMultiIconTextDescCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textView.numberOfLines = 3;
            cell.textView.lineBreakMode = NSLineBreakByTruncatingTail;
            cell.separatorInset = UIEdgeInsetsMake(0, cell.textView.frame.origin.x, 0, 0);
        }
        if (cell)
        {
            [cell.textView setText:item[@"title"]];
            [cell.descView setText:item[@"description"]];
            [cell.iconView setImage:[[UIImage imageNamed:item[@"img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
            cell.iconView.tintColor = item[@"color"];
            
            if ([item[@"isSelected"] boolValue])
            {
                [cell setOverflowVisibility:NO];
                [cell.overflowButton setImage:[[UIImage imageNamed:@"ic_checmark_default"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
            }
            else
            {
                [cell setOverflowVisibility:YES];
            }
            
            [cell updateConstraintsIfNeeded];
        }
        return cell;
    }
    
    return nil;
}

- (NSInteger) tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary *item = ((NSArray *)_data[section]).firstObject;
    return item[@"header"];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kAddNewGroupSection)
    {
        OAAddFavoriteGroupViewController * addGroupVC = [[OAAddFavoriteGroupViewController alloc] init];
        addGroupVC.delegate = self;
        [self presentViewController:addGroupVC animated:YES completion:nil];
    }
    else if (indexPath.section == kGroupsListSection)
    {
        NSDictionary *item = _data[indexPath.section][indexPath.row];
        if (![item[@"isSelected"] boolValue] && _delegate)
            [_delegate onGroupSelected:item[@"title"]];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
        NSDictionary *item = _data[indexPath.section][indexPath.row];
        NSString *cellType = item[@"type"];
        if ([cellType isEqualToString:kMultiIconTextDescCell])
            return 60;
        else
            return UITableViewAutomaticDimension;
}

#pragma mark - OAAddFavoriteGroupDelegate

- (void) onFavoriteGroupAdded:(NSString *)groupName color:(UIColor *)color
{
    if (_delegate)
        [_delegate onNewGroupAdded:groupName color:color];
    
    _selectedGroupName = groupName;
    
    [self reloadData];
    [self generateData];
    [self.tableView reloadData];
}

@end

