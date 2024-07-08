//
//  OAActionAddProfileViewController.m
//  OsmAnd
//
//  Created by nnngrach on 24.12.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAActionAddProfileViewController.h"
#import "Localization.h"
#import "OASimpleTableViewCell.h"
#import "OsmAndApp.h"
#import "OAProfileDataObject.h"
#import "OAProfileDataUtils.h"
#import "OAApplicationMode.h"

@interface OAActionAddProfileViewController () <UITextFieldDelegate>

@end

@implementation OAActionAddProfileViewController
{
    NSMutableArray<NSString *> *_initialValues;
    NSArray<OAProfileDataObject *> *_data;
}

#pragma mark - Initialization

- (instancetype)initWithNames:(NSMutableArray<NSString *> *)names
{
    self = [super init];
    if (self)
    {
        _initialValues = names;
    }
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    [self.tableView setEditing:YES];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"select_application_profile");
}

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    return @[[self createRightNavbarButton:OALocalizedString(@"shared_string_done")
                                  iconName:nil
                                    action:@selector(onRightNavbarButtonPressed)
                                      menu:nil]];
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeOrange;
}

#pragma mark - Table data

- (void)generateData
{
    _data = [OAProfileDataUtils getDataObjects:[OAApplicationMode allPossibleValues]];
}

- (NSInteger)sectionsCount
{
    return 1;
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    return OALocalizedString(@"application_profiles");
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data.count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OAProfileDataObject *item = _data[indexPath.row];
    OASimpleTableViewCell *cell = nil;
    
    cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OASimpleTableViewCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        cell.titleLabel.text = item.name;
        cell.descriptionLabel.text = item.descr;
        cell.leftIconView.image = [UIImage templateImageNamed:item.iconName].imageFlippedForRightToLeftLayoutDirection;
        cell.leftIconView.tintColor = UIColorFromRGB(item.iconColor);
        if ([_initialValues containsObject:item.stringKey])
        {
            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            [_initialValues removeObject:item.stringKey];
        }
    }
    return cell;
}

#pragma mark - Selectors

- (void)onRightNavbarButtonPressed
{
    NSArray *selectedItems = [self.tableView indexPathsForSelectedRows];
    NSMutableArray *arr = [NSMutableArray new];
    for (NSIndexPath *path in selectedItems)
    {
        OAProfileDataObject *profile = _data[path.row];
        [arr addObject:@{@"name" : profile.name, @"stringKey" : profile.stringKey, @"img" : profile.iconName, @"iconColor" : [NSNumber numberWithInt:profile.iconColor]}];
    }
    if (self.delegate)
        [self.delegate onProfileSelected:[NSArray arrayWithArray:arr]];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
