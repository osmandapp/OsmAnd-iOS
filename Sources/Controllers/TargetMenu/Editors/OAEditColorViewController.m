//
//  OAEditColorViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 08/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAEditColorViewController.h"
#import "OASimpleTableViewCell.h"
#import "OADefaultFavorite.h"
#import "OAUtilities.h"
#import "OsmAndApp.h"

#import "Localization.h"

@implementation OAEditColorViewController

#pragma mark - Initialization

- (instancetype)initWithColor:(UIColor *)color
{
    self = [super init];
    if (self)
    {
        OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
        self.colorIndex = [[OADefaultFavorite builtinColors] indexOfObject:favCol];
    }
    return self;
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"shared_string_color");
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
    return 1;
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    return OALocalizedString(@"fav_colors");
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return [[OADefaultFavorite builtinColors] count];
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OASimpleTableViewCell *)[nib objectAtIndex:0];
        [cell descriptionVisibility:NO];
        cell.leftIconView.layer.cornerRadius = cell.leftIconView.frame.size.width / 2;
    }
    
    if (cell)
    {
        OAFavoriteColor *favCol = [OADefaultFavorite builtinColors][indexPath.row];
        [cell.titleLabel setText:favCol.name];
        [cell.leftIconView setBackgroundColor:favCol.color];
        cell.accessoryType = indexPath.row != self.colorIndex ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark;
    }
    return cell;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    self.colorIndex = indexPath.row;
    [self.tableView reloadData];
}

#pragma mark - Selectors

- (void)onRightNavbarButtonPressed
{
    _saveChanges = YES;

    if (self.delegate && [self.delegate respondsToSelector:@selector(colorChanged)])
        [self.delegate colorChanged];

    [self dismissViewController];
}

@end
