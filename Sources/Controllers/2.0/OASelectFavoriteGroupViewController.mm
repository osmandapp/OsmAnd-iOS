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
#import "OADefaultFavorite.h"
#import "OATitleRightIconCell.h"
#import "OAMultiIconTextDescCell.h"
#import "OAAddFavoriteGroupViewController.h"
#import "OsmAndApp.h"

#define kAddNewGroupSection 0
#define kGroupsListSection 1

@interface OASelectFavoriteGroupViewController() <UITableViewDelegate, UITableViewDataSource, OAAddFavoriteGroupDelegate>

@end

@implementation OASelectFavoriteGroupViewController
{
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
    self.tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:OALocalizedString(@"select_group_descr") font:[UIFont systemFontOfSize:15.] textColor:UIColor.blackColor lineSpacing:0. isTitle:NO];
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
            @"type" : [OATitleRightIconCell getCellIdentifier],
            @"title" : OALocalizedString(@"fav_add_new_group"),
            @"img" : @"ic_custom_add",
        },
    ]];
    
    NSMutableArray *cellFoldersData = [NSMutableArray new];
    
    if (![[OAFavoritesHelper getGroups].allKeys containsObject:@""])
    {
        [cellFoldersData addObject:@{
            @"type" : [OAMultiIconTextDescCell getCellIdentifier],
            @"header" : OALocalizedString(@"available_groups"),
            @"title" : OALocalizedString(@"favorites"),
            @"description" :@"0",
            @"isSelected" : [NSNumber numberWithBool:[@"" isEqualToString: _selectedGroupName]],
            @"color" : [OADefaultFavorite getDefaultColor],
            @"img" : @"ic_custom_folder"
        }];
    }
    
    for (OAFavoriteGroup *group in _groupedFavorites)
    {
        NSString *name = [OAFavoriteGroup getDisplayName:group.name];
        
        [cellFoldersData addObject:@{
            @"type" : [OAMultiIconTextDescCell getCellIdentifier],
            @"header" : OALocalizedString(@"available_groups"),
            @"title" : name,
            @"description" : [NSString stringWithFormat:@"%ld", (unsigned long)group.points.count],
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
    
    if ([cellType isEqualToString:[OATitleRightIconCell getCellIdentifier]])
    {
        OATitleRightIconCell* cell = [tableView dequeueReusableCellWithIdentifier:[OATitleRightIconCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleRightIconCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleRightIconCell *)[nib objectAtIndex:0];
            cell.titleView.textColor = UIColorFromRGB(color_primary_purple);
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.titleView.font = [UIFont systemFontOfSize:17. weight:UIFontWeightSemibold];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.titleView.text = item[@"title"];
        [cell.iconView setImage:[UIImage templateImageNamed:item[@"img"]]];
        return cell;
    }
   
    else if ([cellType isEqualToString:[OAMultiIconTextDescCell getCellIdentifier]])
    {
        OAMultiIconTextDescCell* cell = (OAMultiIconTextDescCell *)[tableView dequeueReusableCellWithIdentifier:[OAMultiIconTextDescCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMultiIconTextDescCell getCellIdentifier] owner:self options:nil];
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
            [cell.iconView setImage:[UIImage templateImageNamed:item[@"img"]]];
            cell.iconView.tintColor = item[@"color"];
            
            if ([item[@"isSelected"] boolValue])
            {
                [cell setOverflowVisibility:NO];
                [cell.overflowButton setImage:[UIImage templateImageNamed:@"ic_checmark_default"] forState:UIControlStateNormal];
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
    NSDictionary *item = _data[section].firstObject;
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
        if ([cellType isEqualToString:[OAMultiIconTextDescCell getCellIdentifier]])
            return 60;
        else
            return UITableViewAutomaticDimension;
}

#pragma mark - OAAddFavoriteGroupDelegate

- (void) onFavoriteGroupAdded:(NSString *)groupName color:(UIColor *)color
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_delegate)
            [_delegate onNewGroupAdded:groupName color:color];
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

@end

