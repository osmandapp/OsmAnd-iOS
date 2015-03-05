//
//  OAMapSettingsOverlayUnderlayScreen.m
//  OsmAnd
//
//  Created by Alexey Kulish on 05/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAMapSettingsOverlayUnderlayScreen.h"
#include "Localization.h"

#include <QSet>

#include <OsmAndCore/Map/IMapStylesCollection.h>
#include <OsmAndCore/Map/UnresolvedMapStyle.h>
#include <OsmAndCore/Map/MapStylePreset.h>
#include <OsmAndCore/Map/IMapStylesPresetsCollection.h>
#include <OsmAndCore/Map/IOnlineTileSources.h>
#include <OsmAndCore/Map/OnlineTileSources.h>

#define _(name) OAMapSourcesOverlayUnderlayScreen__##name
#define commonInit _(commonInit)
#define deinit _(deinit)

#define Item _(Item)
@interface Item : NSObject
@property OAMapSource* mapSource;
@property std::shared_ptr<const OsmAnd::ResourcesManager::Resource> resource;
@end
@implementation Item
@end

#define Item_MapStyle _(Item_MapStyle)
@interface Item_MapStyle : Item
@property std::shared_ptr<const OsmAnd::UnresolvedMapStyle> mapStyle;
@property int sortIndex;
@end
@implementation Item_MapStyle
@end

#define Item_OnlineTileSource _(Item_OnlineTileSource)
@interface Item_OnlineTileSource : Item
@property std::shared_ptr<const OsmAnd::IOnlineTileSources::Source> onlineTileSource;
@end
@implementation Item_OnlineTileSource
@end

typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;


@implementation OAMapSettingsOverlayUnderlayScreen
{
    NSMutableArray* _onlineMapSources;
}

@synthesize settingsScreen, app, tableData, vwController, tblView, settings, title, isOnlineMapSource;


-(id)initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController
{
    self = [super init];
    if (self) {
        app = [OsmAndApp instance];
        settings = [OAAppSettings sharedManager];
        title = @"Map Type";
        
        settingsScreen = EMapSettingsScreenMapType;
        
        vwController = viewController;
        tblView = tableView;
        
        [self commonInit];
        [self initData];
    }
    return self;
}

- (void)dealloc
{
    [self deinit];
}

- (void)commonInit
{
    _onlineMapSources = [NSMutableArray array];
}

- (void)deinit
{
}

- (void)setupView
{
    [_onlineMapSources removeAllObjects];
    
    // Collect all needed resources
    QList< std::shared_ptr<const OsmAnd::ResourcesManager::Resource> > onlineTileSourcesResources;
    
    // Process online tile sources resources
    for(const auto& resource : onlineTileSourcesResources)
    {
        const auto& onlineTileSources = std::static_pointer_cast<const OsmAnd::ResourcesManager::OnlineTileSourcesMetadata>(resource->metadata)->sources;
        NSString* resourceId = resource->id.toNSString();
        
        for(const auto& onlineTileSource : onlineTileSources->getCollection())
        {
            Item_OnlineTileSource* item = [[Item_OnlineTileSource alloc] init];
            
            NSString *caption = onlineTileSource->title.toNSString();
            
            item.mapSource = [[OAMapSource alloc] initWithResource:resourceId
                                                        andVariant:onlineTileSource->name.toNSString() name:caption];
            item.resource = resource;
            item.onlineTileSource = onlineTileSource;
            
            [_onlineMapSources addObject:item];
        }
    }
    
    
    NSArray *arr = [_onlineMapSources sortedArrayUsingComparator:^NSComparisonResult(Item_OnlineTileSource* obj1, Item_OnlineTileSource* obj2) {
        NSString *caption1 = obj1.onlineTileSource->title.toNSString();
        NSString *caption2 = obj2.onlineTileSource->title.toNSString();
        return [caption2 compare:caption1];
    }];
    
    [_onlineMapSources setArray:arr];

}


-(void)initData
{
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return [_onlineMapSources count];
            
        default:
            return 0;
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return OALocalizedString(@"Online Maps");
            
        default:
            return nil;
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const mapSourceItemCell = @"mapSourceItemCell";
    
    // Get content for cell and it's type id
    NSString* caption = nil;
    NSString* description = nil;
    
    Item* someItem = [_onlineMapSources objectAtIndex:indexPath.row];
    
    if (someItem.resource->type == OsmAndResourceType::OnlineTileSources)
    {
        Item_OnlineTileSource* item = (Item_OnlineTileSource*)someItem;
        
        caption = item.mapSource.name;
        description = nil;
#if defined(OSMAND_IOS_DEV)
        description = item.resource->id.toNSString();
#endif // defined(OSMAND_IOS_DEV)
    }
    
    // Obtain reusable cell or create one
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:mapSourceItemCell];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:mapSourceItemCell];
    
    // Fill cell content
    cell.textLabel.text = caption;
    cell.detailTextLabel.text = description;
    
    if ([app.data.lastMapSource isEqual:someItem.mapSource]) {
        cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"menu_cell_selected.png"]];
    } else {
        cell.accessoryView = nil;
    }
    
    return cell;
}


#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 34.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Item* item = [_onlineMapSources objectAtIndex:indexPath.row];
    app.data.lastMapSource = item.mapSource;
    
    [tableView reloadData];
}



@end
