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
#import "OsmAnd_Maps-Swift.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OADefaultFavorite.h"
#import "OARightIconTableViewCell.h"
#import "OASimpleTableViewCell.h"
#import "OsmAndApp.h"
#import "GeneratedAssetSymbols.h"

#define kAddNewGroupSection 0
#define kGroupsListSection 1

@interface OASelectFavoriteGroupViewController() <OAEditorDelegate>

@end

@implementation OASelectFavoriteGroupViewController
{
    NSString *_selectedGroupName;
    NSArray<OAFavoriteGroup *> *_groupedFavorites;
    NSArray<NSDictionary<NSString *, NSString *> *> *_groupedGpxWpts;
    NSArray<NSArray<NSDictionary *> *> *_data;
}

#pragma mark - Initialization

- (instancetype)initWithSelectedGroupName:(NSString *)selectedGroupName;
{
    self = [super init];
    if (self)
    {
        _selectedGroupName = selectedGroupName;
        [self reloadData:[OAFavoritesHelper getFavoriteGroups] isFavorite:YES];
    }
    return self;
}

- (instancetype)initWithSelectedGroupName:(NSString *)selectedGroupName gpxWptGroups:(NSArray *)gpxWptGroups;
{
    self = [super init];
    if (self)
    {
        _selectedGroupName = selectedGroupName;
        [self reloadData:gpxWptGroups isFavorite:NO];
    }
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.separatorColor = [UIColor colorNamed:ACColorNameCustomSeparator];
    self.tableView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"select_group");
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

- (NSString *)getTableHeaderDescription
{
    return OALocalizedString(@"select_group_descr");
}

- (BOOL)hideFirstHeader
{
    return YES;
}

#pragma mark - Table data

- (void)generateData
{
    NSMutableArray *data = [NSMutableArray new];
    [data addObject:@[
        @{
            @"type" : [OARightIconTableViewCell getCellIdentifier],
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
                @"color": group[@"color"] ? group[@"color"] : [UIColor colorNamed:ACColorNameIconColorActive].toHexString,
                @"img": @"ic_custom_folder"
            }];
        }
    }

    [data addObject: [NSArray arrayWithArray:cellFoldersData]];
    _data = data;
}

- (void)reloadData:(NSArray *)data isFavorite:(BOOL)isFavorite
{
    _groupedFavorites = isFavorite ? data : nil;
    _groupedGpxWpts = isFavorite ? nil : data;
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    NSDictionary *item = _data[section].firstObject;
    return item[@"header"];
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = item[@"type"];
    
    if ([cellType isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
    {
        OARightIconTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameTextColorActive];
            cell.rightIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
            cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            [cell.rightIconView setImage:[UIImage templateImageNamed:item[@"img"]]];
        }
        return cell;
    }
   
    else if ([cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
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
            cell.leftIconView.tintColor = color ? color : [UIColor colorNamed:ACColorNameIconColorActive];
            
            if ([item[@"isSelected"] boolValue])
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            else
                cell.accessoryType = UITableViewCellAccessoryNone;
        }
        return cell;
    }
    
    return nil;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
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

#pragma mark - OAEditorDelegate

- (void)addNewItemWithName:(NSString *)name
                  iconName:(NSString *)iconName
                     color:(UIColor *)color
        backgroundIconName:(NSString *)backgroundIconName;
{
    [self dismissViewController];
    if (_delegate)
    {
        [_delegate addNewGroupWithName:name
                              iconName:iconName
                                 color:color
                    backgroundIconName:backgroundIconName];
    }
}

- (void)onEditorUpdated
{
}

- (void)selectColorItem:(OAColorItem *)colorItem
{
    if (self.delegate)
        [self.delegate selectColorItem:colorItem];
}

- (OAColorItem *)addAndGetNewColorItem:(UIColor *)color
{
    if (self.delegate)
        return [self.delegate addAndGetNewColorItem:color];
    return nil;
}

- (void)changeColorItem:(OAColorItem *)colorItem withColor:(UIColor *)color
{
    if (self.delegate)
        [self.delegate changeColorItem:colorItem withColor:color];
}

- (OAColorItem *)duplicateColorItem:(OAColorItem *)colorItem
{
    if (self.delegate)
        return [self.delegate duplicateColorItem:colorItem];
    return nil;
}

- (void)deleteColorItem:(OAColorItem *)colorItem
{
    if (self.delegate)
        [self.delegate deleteColorItem:colorItem];
}


@end
