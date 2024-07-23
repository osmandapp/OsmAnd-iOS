//
//  OAEditGroupViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 08/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAEditGroupViewController.h"
#import "OASimpleTableViewCell.h"
#import "OAInputTableViewCell.h"
#import "OAFavoritesHelper.h"
#import "OAUtilities.h"
#import "OsmAndApp.h"

#import "Localization.h"

@implementation OAEditGroupViewController
{
    NSArray* _groups;
}

#pragma mark - Initialization

- (instancetype)initWithGroupName:(NSString *)groupName groups:(NSArray *)groups
{
    self = [super init];
    if (self) {
        self.groupName = groupName;
        _groups = [groups sortedArrayUsingComparator:^NSComparisonResult(NSString* obj1, NSString* obj2) {
            return [obj1 localizedCaseInsensitiveCompare:obj2];
        }];
    }
    return self;
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"shared_string_groups");
}

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    return @[[self createRightNavbarButton:OALocalizedString(@"shared_string_save")
                                  iconName:nil
                                    action:@selector(onRightNavbarButtonPressed)
                                      menu:nil]];
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeOrange;
}

#pragma mark - Table data

- (NSInteger)sectionsCount
{
    return 2;
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    return [@[OALocalizedString(@"shared_string_groups"), OALocalizedString(@"fav_create_group")] objectAtIndex:section];
}

- (NSInteger)rowsCount:(NSInteger)section
{
    if (section == 0)
        return _groups.count;
    else
        return 1;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *)[nib objectAtIndex:0];
            [cell descriptionVisibility:NO];
            [cell leftIconVisibility:NO];
        }
        if (cell)
        {
            NSString *item = [_groups objectAtIndex:indexPath.row];
            [cell.titleLabel setText:[OAFavoriteGroup getDisplayName:item]];
            cell.accessoryType = UITableViewCellAccessoryNone;
            if ([[OAFavoriteGroup getDisplayName:item] isEqualToString:[OAFavoriteGroup getDisplayName:self.groupName]])
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        return cell;
    }
    else
    {
        OAInputTableViewCell *cell = (OAInputTableViewCell *) [self.tableView dequeueReusableCellWithIdentifier:[OAInputTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAInputTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAInputTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell titleVisibility:NO];
            [cell clearButtonVisibility:NO];
            cell.inputField.textAlignment = NSTextAlignmentNatural;
            cell.inputField.placeholder = OALocalizedString(@"fav_enter_group_name");
        }
        if (cell)
        {
            cell.inputField.delegate = self;
            [cell.inputField removeTarget:self action:NULL forControlEvents:UIControlEventEditingChanged];
            [cell.inputField addTarget:self action:@selector(editGroupName:) forControlEvents:UIControlEventEditingChanged];
        }
        return cell;
    }
    return nil;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        NSString *groupName = [_groups objectAtIndex:indexPath.row];
        if ([groupName isEqualToString:OALocalizedString(kDefaultCategoryKey)])
            self.groupName = @"";
        else
            self.groupName = groupName;
        
        [self.tableView reloadData];
    }
    else
    {
        [self.tableView reloadData];
    }
}

#pragma mark - Additions

- (void)editGroupName:(id)sender
{
    self.groupName = [((UITextField*)sender) text];
}

#pragma mark - Selectors

- (void)onRightNavbarButtonPressed
{
    _saveChanges = YES;

    if (self.delegate && [self.delegate respondsToSelector:@selector(groupChanged)])
        [self.delegate groupChanged];

    [self dismissViewController];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)sender
{
    [sender resignFirstResponder];
    return YES;
}

@end
