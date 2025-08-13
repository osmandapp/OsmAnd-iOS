//
//  OAActionAddMapSourceViewController.m
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAActionAddMapSourceViewController.h"
#import "OAActionConfigurationViewController.h"
#import "Localization.h"
#import "OASimpleTableViewCell.h"
#import "OsmAndApp.h"
#import "OAIAPHelper.h"
#import "OAMapSource.h"
#import "OAApplicationMode.h"
#import "OAAppSettings.h"
#import "OAMapCreatorHelper.h"
#import "OAResourcesUIHelper.h"

#include <OsmAndCore/ResourcesManager.h>
#include <OsmAndCore/Map/IOnlineTileSources.h>
#include <OsmAndCore/Map/OnlineTileSources.h>

@interface OAActionAddMapSourceViewController () <UITextFieldDelegate>

@end

@implementation OAActionAddMapSourceViewController
{
    EOAMapSourceType _type;
    NSArray *_data;
    NSMutableArray<NSString *> *_initialValues;
    OsmAndAppInstance _app;
}

#pragma mark - Initialization

- (instancetype)initWithNames:(NSMutableArray<NSString *> *)names type:(EOAMapSourceType)type
{
    self = [super init];
    if (self)
    {
        _initialValues = names;
        _type = type;
    }
    return self;
}

- (void)commonInit
{
    _app = [OsmAndApp instance];
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
    switch (_type)
    {
        case EOAMapSourceTypePrimary:
            return OALocalizedString(@"select_map_source");
        case EOAMapSourceTypeOverlay:
            return OALocalizedString(@"select_overlay");
        case EOAMapSourceTypeUnderlay:
            return OALocalizedString(@"select_underlay");
        default:
            return @"";
    }
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
    _data = [OAResourcesUIHelper getSortedRasterMapSources:YES];
    OAOnlineTilesResourceItem* itemNone = [[OAOnlineTilesResourceItem alloc] init];
    itemNone.mapSource = [[OAMapSource alloc] initWithResource:nil andVariant:[self getNoSourceItemId] name:[self getNoSourceName]];
    _data = [_data arrayByAddingObject:itemNone];
}

- (NSString *)getNoSourceItemId
{
    switch (_type) {
        case EOAMapSourceTypePrimary:
            return @"LAYER_OSM_VECTOR";
        case EOAMapSourceTypeOverlay:
            return @"no_overlay";
        case EOAMapSourceTypeUnderlay:
            return @"no_underlay";
        default:
            return @"";
    }
}

- (NSString *)getNoSourceName
{
    switch (_type) {
        case EOAMapSourceTypePrimary:
            return OALocalizedString(@"vector_data");
        case EOAMapSourceTypeOverlay:
            return OALocalizedString(@"no_overlay");
        case EOAMapSourceTypeUnderlay:
            return OALocalizedString(@"no_underlay");
        default:
            return @"";
    }
}

- (OAOnlineTilesResourceItem *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.row];
}

- (NSInteger)sectionsCount
{
    return 1;
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    return OALocalizedString(@"available_map_sources");
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data.count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OAOnlineTilesResourceItem* item = [self getItem:indexPath];
    OASimpleTableViewCell* cell = nil;
    
    cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OASimpleTableViewCell *)[nib objectAtIndex:0];
        [cell descriptionVisibility:NO];
    }
    if (cell)
    {
        UIImage *img = nil;
        img = [UIImage imageNamed:@"ic_custom_map_style"];
        
        cell.titleLabel.text = item.mapSource.name;
        cell.leftIconView.image = img;
        if ([_initialValues containsObject:item.mapSource.name])
        {
            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            [_initialValues removeObject:item.mapSource.name];
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
        OAOnlineTilesResourceItem* source = [self getItem:path];
        [arr addObject:@[source.mapSource.variant ,source.mapSource.name]];
    }
    if (self.delegate)
        [self.delegate onMapSourceSelected:[NSArray arrayWithArray:arr]];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
