//
//  OASelectFavoriteGroupViewController.m
//  OsmAnd Maps
//
//  Created by nnngrach on 16.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OASelectFavoriteGroupViewController.h"
#import "OAFavoriteGroupEditorViewController.h"
#import "OAFavoriteItem.h"
#import "OAFavoritesHelper.h"
#import "OAColors.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OADefaultFavorite.h"
#import "OATitleRightIconCell.h"
#import "OASimpleTableViewCell.h"
#import "OsmAndApp.h"

#define kAddNewGroupSection 0
#define kGroupsListSection 1

@interface OASelectFavoriteGroupViewController() <UITableViewDelegate, UITableViewDataSource, OAEditorDelegate>

@end

@implementation OASelectFavoriteGroupViewController
{
    NSString *_selectedGroupName;
    NSArray<OAFavoriteGroup *> *_groupedFavorites;
    NSArray<NSDictionary<NSString *, NSString *> *> *_groupedGpxWpts;
    NSArray<NSArray<NSDictionary *> *> *_data;
}

- (instancetype) initWithSelectedGroupName:(NSString *)selectedGroupName;
{
    self = [super initWithNibName:@"OABaseTableViewController" bundle:nil];
    if (self)
    {
        _selectedGroupName = selectedGroupName;
        [self reloadData:[OAFavoritesHelper getFavoriteGroups] isFavorite:YES];
        [self generateData];
    }
    return self;
}

- (instancetype) initWithSelectedGroupName:(NSString *)selectedGroupName gpxWptGroups:(NSArray *)gpxWptGroups;
{
    self = [super initWithNibName:@"OABaseTableViewController" bundle:nil];
    if (self)
    {
        _selectedGroupName = selectedGroupName;
        [self reloadData:gpxWptGroups isFavorite:NO];
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
    self.tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:OALocalizedString(@"select_group_descr") font:kHeaderDescriptionFont textColor:UIColor.blackColor isBigTitle:NO parentViewWidth:self.view.frame.size.width];
    self.tableView.tintColor = UIColorFromRGB(color_primary_purple);
}

- (void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"select_group");
}

- (void) reloadData:(NSArray *)data isFavorite:(BOOL)isFavorite
{
    _groupedFavorites = isFavorite ? data : nil;
    _groupedGpxWpts = isFavorite ? nil : data;
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

    if (_groupedFavorites)
    {
        if (![[OAFavoritesHelper getGroups].allKeys containsObject:@""])
        {
            [cellFoldersData addObject:@{
                    @"type" : [OASimpleTableViewCell getCellIdentifier],
                    @"header" : OALocalizedString(@"available_groups"),
                    @"title" : OALocalizedString(@"favorites_item"),
                    @"description" :@"0",
                    @"isSelected" : @([@"" isEqualToString:_selectedGroupName]),
                    @"color" : [OADefaultFavorite getDefaultColor],
                    @"img" : @"ic_custom_folder"
            }];
        }

        for (OAFavoriteGroup *group in _groupedFavorites)
        {
            NSString *name = [OAFavoriteGroup getDisplayName:group.name];

            [cellFoldersData addObject:@{
                    @"type": [OASimpleTableViewCell getCellIdentifier],
                    @"header": OALocalizedString(@"available_groups"),
                    @"title": name,
                    @"description": [NSString stringWithFormat:@"%ld", (unsigned long) group.points.count],
                    @"isSelected": @([name isEqualToString:_selectedGroupName]),
                    @"color": group.color,
                    @"img": @"ic_custom_folder"
            }];
        }
    }
    else if (_groupedGpxWpts)
    {
        for (NSDictionary<NSString *, NSString *> *group in _groupedGpxWpts)
        {
            [cellFoldersData addObject:@{
                    @"type": [OASimpleTableViewCell getCellIdentifier],
                    @"header": OALocalizedString(@"available_groups"),
                    @"title": group[@"title"],
                    @"description": [NSString stringWithFormat:@"%i", group[@"count"].intValue],
                    @"isSelected": @([group[@"title"] isEqualToString:_selectedGroupName]),
                    @"color": group[@"color"] ? group[@"color"] : UIColorFromRGB(color_primary_purple).toHexString,
                    @"img": @"ic_custom_folder"
            }];
        }
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
            cell = nib[0];
            cell.titleView.textColor = UIColorFromRGB(color_primary_purple);
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.titleView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.titleView.text = item[@"title"];
        [cell.iconView setImage:[UIImage templateImageNamed:item[@"img"]]];
        return cell;
    }
   
    else if ([cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.titleLabel.numberOfLines = 3;
            cell.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        }
        if (cell)
        {
            [cell.titleLabel setText:item[@"title"]];
            [cell.descriptionLabel setText:item[@"description"]];
            [cell.leftIconView setImage:[UIImage templateImageNamed:item[@"img"]]];
            UIColor *color;
            if (item[@"color"])
                color = [item[@"color"] isKindOfClass:NSString.class] ? [UIColor colorFromString:item[@"color"]] : item[@"color"];
            cell.leftIconView.tintColor = color ? color : UIColorFromRGB(color_primary_purple);
            
            if ([item[@"isSelected"] boolValue])
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            else
                cell.accessoryType = UITableViewCellAccessoryNone;
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
        OAFavoriteGroupEditorViewController *groupEditor = [[OAFavoriteGroupEditorViewController alloc] initWithNew];
        groupEditor.delegate = self;
        [self showModalViewController:groupEditor];
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
        if ([cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
            return 60;
        else
            return UITableViewAutomaticDimension;
}

#pragma mark - OAEditorDelegate

- (void)addNewItemWithName:(NSString *)name
                  iconName:(NSString *)iconName
                     color:(UIColor *)color
        backgroundIconName:(NSString *)backgroundIconName;
{
    [self dismissViewController];
    if (_delegate)
    {
        [_delegate onNewGroupAdded:name
                          iconName:iconName
                             color:color
                backgroundIconName:backgroundIconName];
    }
}

- (void)onEditorUpdated
{
}

- (void)onFavoriteGroupColorsRefresh
{
    if (_delegate)
        [_delegate onFavoriteGroupColorsRefresh];
}

@end

