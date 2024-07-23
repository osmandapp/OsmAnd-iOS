//
//  OAActionAddMapStyleViewController.m
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAActionAddMapStyleViewController.h"
#import "Localization.h"
#import "OASimpleTableViewCell.h"
#import "OsmAndApp.h"
#import "OAIAPHelper.h"
#import "OAProducts.h"
#import "OARendererRegistry.h"
#import "OAResourcesUIHelper.h"
#import "OAIndexConstants.h"
#import "OAMapSource.h"
#import "OAAppSettings.h"
#import "OAAppData.h"
#import "OAApplicationMode.h"

#include <OsmAndCore/Map/UnresolvedMapStyle.h>

@interface OAActionAddMapStyleViewController () <UITextFieldDelegate>

@end

@implementation OAActionAddMapStyleViewController
{
    NSArray *_data;
    NSMutableArray<NSString *> *_initialValues;
}

#pragma mark - Initialization

- (instancetype)initWithNames:(NSMutableArray<NSString *> *)names
{
    self = [super init];
    if (self) {
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
    return OALocalizedString(@"select_map_style");
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
    NSMutableArray *offlineMapSources = [NSMutableArray new];
    QList< std::shared_ptr<const OsmAnd::ResourcesManager::Resource> > mapStylesResources;
    const auto localResources = [OsmAndApp instance].resourcesManager->getLocalResources();
    for(const auto& localResource : localResources)
    {
        if (localResource->type == OsmAnd::ResourcesManager::ResourceType::MapStyle)
            mapStylesResources.push_back(localResource);
    }
    OAApplicationMode *mode = [OAAppSettings sharedManager].applicationMode.get;
    
    for(const auto& resource : mapStylesResources)
    {
        const auto& mapStyle = std::static_pointer_cast<const OsmAnd::ResourcesManager::MapStyleMetadata>(resource->metadata)->mapStyle;

        NSString* resourceId = resource->id.toNSString();
        NSDictionary *mapStyleInfo = [OARendererRegistry getMapStyleInfo:mapStyle->title.toNSString()];

        OAMapStyleResourceItem* item = [[OAMapStyleResourceItem alloc] init];
        item.mapSource = [[OsmAndApp instance].data lastMapSourceByResourceId:resourceId];
        if (!item.mapSource)
        {
            item.mapSource = [[OAMapSource alloc] initWithResource:[[mapStyleInfo[@"id"] lowercaseString] stringByAppendingString:RENDERER_INDEX_EXT]
                                                        andVariant:mode.variantKey
                                                              name:mapStyleInfo[@"title"]];
        }
        else if (![item.mapSource.name isEqualToString:mapStyleInfo[@"title"]])
        {
            item.mapSource.name = mapStyleInfo[@"title"];
        }

        OAIAPHelper *iapHelper = [OAIAPHelper sharedInstance];
        if ([mapStyleInfo[@"title"] isEqualToString:WINTER_SKI_RENDER] && ![iapHelper.skiMap isActive])
            continue;
        if ([mapStyleInfo[@"title"] isEqualToString:NAUTICAL_RENDER] && ![iapHelper.nautical isActive])
            continue;

        item.resourceType = OsmAndResourceType::MapStyle;
        item.resource = resource;
        item.mapStyle = mapStyle;
        item.sortIndex = [mapStyleInfo[@"sort_index"] intValue];
        
        [offlineMapSources addObject:item];
    }
    NSArray *res = [offlineMapSources sortedArrayUsingComparator:^NSComparisonResult(OAMapStyleResourceItem* obj1, OAMapStyleResourceItem* obj2) {
        if (obj1.sortIndex < obj2.sortIndex)
            return NSOrderedAscending;
        if (obj1.sortIndex > obj2.sortIndex)
            return NSOrderedDescending;
        return NSOrderedSame;
    }];
    
    _data = res;
}

- (OAMapStyleResourceItem *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.row];
}

- (NSInteger)sectionsCount
{
    return 1;
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    return OALocalizedString(@"available_map_styles");
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data.count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OAMapStyleResourceItem* item = [self getItem:indexPath];
    
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
        NSString *imgName = [NSString stringWithFormat:@"img_mapstyle_%@", [item.mapSource.resourceId stringByReplacingOccurrencesOfString:RENDERER_INDEX_EXT withString:@""]];
        if (imgName)
            img = [UIImage imageNamed:imgName];
        
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
        OAMapStyleResourceItem* style = [self getItem:path];
        NSString *imgName = [NSString stringWithFormat:@"img_mapstyle_%@", [style.mapSource.resourceId stringByReplacingOccurrencesOfString:RENDERER_INDEX_EXT withString:@""]];
        [arr addObject:@{@"name" : style.mapSource.name, @"img" : imgName ? imgName : @"ic_custom_show_on_map"}];
    }
    if (self.delegate)
        [self.delegate onMapStylesSelected:[NSArray arrayWithArray:arr]];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
