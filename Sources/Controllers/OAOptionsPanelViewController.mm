//
//  OAOptionsPanelViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/20/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OAOptionsPanelViewController.h"

#import "OsmAndApp.h"
#import "UIViewController+OARootViewController.h"
#import "OAMenuOriginViewControllerProtocol.h"
#import "OAMyDataViewController.h"
#import "OAFavoritesLayerViewController.h"
#import "OAAutoObserverProxy.h"
#import "OAAppData.h"
#include "Localization.h"
#import "OALog.h"

#include <OsmAndCore/Map/IMapStylesCollection.h>
#include <OsmAndCore/Map/MapStyle.h>
#include <OsmAndCore/Map/MapStylePreset.h>
#include <OsmAndCore/Map/IMapStylesPresetsCollection.h>
#include <OsmAndCore/Map/IOnlineTileSources.h>
#include <OsmAndCore/Map/OnlineTileSources.h>

#define _(name) OAOptionsPanelViewController__##name
#define ctor _(ctor)
#define dtor _(dtor)

#define Item_MapStyle _(Item_MapStyle)
@interface Item_MapStyle : NSObject
@property std::shared_ptr<const OsmAnd::MapStyle> mapStyle;
@end
@implementation Item_MapStyle
@end

#define Item_MapStylePreset _(Item_MapStylePreset)
@interface Item_MapStylePreset : NSObject
@property OAMapSource* mapSource;
@property std::shared_ptr<const OsmAnd::MapStylePreset> mapStylePreset;
@property std::shared_ptr<const OsmAnd::MapStyle> mapStyle;
@end
@implementation Item_MapStylePreset
@end

#define Item_OnlineTileSource _(Item_OnlineTileSource)
@interface Item_OnlineTileSource : NSObject
@property std::shared_ptr<const OsmAnd::IOnlineTileSources::Source> onlineTileSource;
@end
@implementation Item_OnlineTileSource
@end

typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;

@interface OAOptionsPanelViewController () <UITableViewDelegate, UITableViewDataSource, OAMenuOriginViewControllerProtocol>
@end

@implementation OAOptionsPanelViewController
{
    OsmAndAppInstance _app;
    
    OAAutoObserverProxy* _lastMapSourceObserver;
    NSMutableArray* _mapSourceAndVariants;

    OAAutoObserverProxy* _layersConfigurationObserver;

    NSIndexPath* _lastMenuOriginCellPath;
}

#define kMapSourceAndVariantsSection 0
#define kLayersSection 1
#define kLayersSection_Favorites 0
#define kOptionsSection 2
#define kOptionsSection_SettingsRow 0
#define kOptionsSection_DownloadsRow 1
#define kOptionsSection_MyDataRow 2

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self ctor];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self ctor];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        [self ctor];
    }
    return self;
}

- (void)dealloc
{
    [self dtor];
}

- (void)ctor
{
    _app = [OsmAndApp instance];

    _mapSourceAndVariants = [[NSMutableArray alloc] init];
    _lastMapSourceObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                       withHandler:@selector(onLastMapSourceChanged)
                                                        andObserve:_app.data.lastMapSourceChangeObservable];
    _app.resourcesManager->localResourcesChangeObservable.attach((__bridge const void*)self,
                                                                 [self]
                                                                 (const OsmAnd::ResourcesManager* const resourcesManager,
                                                                  const QList< QString >& added,
                                                                  const QList< QString >& removed,
                                                                  const QList< QString >& updated)
                                                                 {
                                                                     QList< QString > merged;
                                                                     merged << added << removed << updated;
                                                                     [self onLocalResourcesChanged:merged];
                                                                 });

    _layersConfigurationObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onLayersConfigurationChanged)
                                                              andObserve:_app.data.mapLayersConfiguration.changeObservable];
}

- (void)dtor
{
    _app.resourcesManager->localResourcesChangeObservable.detach((__bridge const void*)self);
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self obtainMapSourceAndVariants];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // Deselect menu origin cell if reopened (on iPhone/iPod)
    if (_lastMenuOriginCellPath != nil)
    {
        [self.tableView deselectRowAtIndexPath:_lastMenuOriginCellPath
                                      animated:animated];

        _lastMenuOriginCellPath = nil;
    }
}

- (void)obtainMapSourceAndVariants
{
    [_mapSourceAndVariants removeAllObjects];

    OAMapSource* mapSource = _app.data.lastMapSource;
    const auto resource = _app.resourcesManager->getResource(QString::fromNSString(mapSource.resourceId));

    // Online tile sources are simple to process:
    if (resource->type == OsmAndResourceType::OnlineTileSources)
    {
        const auto& onlineTileSources = std::static_pointer_cast<const OsmAnd::ResourcesManager::OnlineTileSourcesMetadata>(resource->metadata)->sources;

        Item_OnlineTileSource* item = [[Item_OnlineTileSource alloc] init];
        item.onlineTileSource = onlineTileSources->getSourceByName(QString::fromNSString(mapSource.variant));

        [_mapSourceAndVariants addObject:item];
    }
    else if (resource->type == OsmAndResourceType::MapStyle)
    {
        NSString* resourceId = resource->id.toNSString();

        // Get the style
        const auto& mapStyle = std::static_pointer_cast<const OsmAnd::ResourcesManager::MapStyleMetadata>(resource->metadata)->mapStyle;
        Item_MapStyle* mapStyleItem = [[Item_MapStyle alloc] init];
        mapStyleItem.mapStyle = mapStyle;
        [_mapSourceAndVariants addObject:mapStyleItem];

        const auto& presets = _app.resourcesManager->mapStylesPresetsCollection->getCollectionFor(mapStyle->name);
        for(const auto& preset : presets)
        {
            Item_MapStylePreset* item = [[Item_MapStylePreset alloc] init];
            item.mapSource = [[OAMapSource alloc] initWithResource:resourceId
                                                        andVariant:preset->name.toNSString()];
            item.mapStylePreset = preset;
            item.mapStyle = mapStyle;

            [_mapSourceAndVariants addObject:item];
        }
    }
}

- (void)onLastMapSourceChanged
{
    [self obtainMapSourceAndVariants];
    dispatch_async(dispatch_get_main_queue(), ^{
        // Reload entire section
        [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:kMapSourceAndVariantsSection]
                      withRowAnimation:UITableViewRowAnimationAutomatic];
    });
}

- (void)onLocalResourcesChanged:(const QList<QString>&)ids
{
    [self obtainMapSourceAndVariants];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableIndexSet* indexSet = [NSMutableIndexSet indexSet];
        [indexSet addIndex:kMapSourceAndVariantsSection];

        [self.tableView reloadSections:indexSet
                      withRowAnimation:UITableViewRowAnimationAutomatic];
    });
}

- (void)onLayersConfigurationChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded)
            return;

        [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:kLayersSection]
                      withRowAnimation:UITableViewRowAnimationAutomatic];
    });
}

- (void)openMenu:(UIViewController*)menuViewController forCellAt:(NSIndexPath*)indexPath
{
    _lastMenuOriginCellPath = indexPath;

    UITableViewCell* originCell = [self.tableView cellForRowAtIndexPath:_lastMenuOriginCellPath];
    [self.rootViewController openMenu:menuViewController
                             fromRect:originCell.frame
                               inView:self.tableView
                             ofParent:self
                             animated:YES];
}

- (void)dismissLastOpenedMenuAnimated:(BOOL)animated
{
    [self.rootViewController closeMenuAnimated:animated];
}

#pragma marg - OAMenuViewOriginControllerProtocol

- (void)notifyMenuClosed
{
    // Deselect menu item that was origin for this popover
    [self.tableView deselectRowAtIndexPath:_lastMenuOriginCellPath animated:YES];
    _lastMenuOriginCellPath = nil;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3 /* Maps section, Layers section, Settings section */;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case kMapSourceAndVariantsSection:
            return [_mapSourceAndVariants count];
        case kLayersSection:
            return 1; /* 'Favorites' */
        case kOptionsSection:
            return 3; /* 'Settings', 'Downloads', 'My data' */
            
        default:
            return 0;
    }
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section)
    {
        case kMapSourceAndVariantsSection:
            return OALocalizedString(@"Map");
        case kLayersSection:
            return OALocalizedString(@"Layers");
        case kOptionsSection:
            return OALocalizedString(@"Options");

        default:
            return nil;
    }
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const submenuCell = @"submenuCell";
    static NSString* const submenuWithDetailsCell = @"submenuWithDetailsCell";
    static NSString* const mapSourceActivePresetCell = @"mapSourceActivePresetCell";
    static NSString* const mapSourceInactivePresetCell = @"mapSourceInactivePresetCell";
    static NSString* const inactiveLayerCell = @"inactiveLayerCell";
    static NSString* const activeLayerCell = @"activeLayerCell";
    static NSString* const submenuLayerCell = @"submenuLayerCell";
    
    // Get content for cell and it's type id
    NSString* cellTypeId = nil;
    UIImage* icon = nil;
    NSString* caption = nil;
    NSString* details = nil;
    switch (indexPath.section)
    {
        case kMapSourceAndVariantsSection:
            if (indexPath.row == 0)
            {
                cellTypeId = submenuCell;

                id item_ = [_mapSourceAndVariants firstObject];
                if ([item_ isKindOfClass:[Item_OnlineTileSource class]])
                {
                    Item_OnlineTileSource* item = (Item_OnlineTileSource*)item_;

                    caption = item.onlineTileSource->name.toNSString();
                }
                else if ([item_ isKindOfClass:[Item_MapStyle class]])
                {
                    Item_MapStyle* item = (Item_MapStyle*)item_;

                    caption = item.mapStyle->title.toNSString();
                }
            }
            else
            {
                Item_MapStylePreset* item = (Item_MapStylePreset*)[_mapSourceAndVariants objectAtIndex:indexPath.row];
                if ([item.mapSource isEqual:_app.data.lastMapSource])
                    cellTypeId = mapSourceActivePresetCell;
                else
                    cellTypeId = mapSourceInactivePresetCell;

                id item_ = [_mapSourceAndVariants objectAtIndex:indexPath.row];
                if ([item_ isKindOfClass:[Item_MapStylePreset class]])
                {
                    Item_MapStylePreset* item = (Item_MapStylePreset*)item_;

                    // Get icon and caption
                    switch (item.mapStylePreset->type)
                    {
                        default:
                        case OsmAnd::MapStylePreset::Type::Custom:
                            caption = item.mapStylePreset->name.toNSString();
                            icon = [UIImage imageNamed:@"map_source_preset_type_general_icon.png"];
                            break;
                        case OsmAnd::MapStylePreset::Type::General:
                            caption = OALocalizedString(@"General");
                            icon = [UIImage imageNamed:@"map_source_preset_type_general_icon.png"];
                            break;
                        case OsmAnd::MapStylePreset::Type::Car:
                            caption = OALocalizedString(@"Car");
                            icon = [UIImage imageNamed:@"map_source_preset_type_car_icon.png"];
                            break;
                        case OsmAnd::MapStylePreset::Type::Bicycle:
                            caption = OALocalizedString(@"Bicycle");
                            icon = [UIImage imageNamed:@"map_source_preset_type_bicycle_icon.png"];
                            break;
                        case OsmAnd::MapStylePreset::Type::Pedestrian:
                            caption = OALocalizedString(@"Pedestrian");
                            icon = [UIImage imageNamed:@"map_source_preset_type_pedestrian_icon.png"];
                            break;
                    }
                }
            }
            break;
        case kLayersSection:
            switch(indexPath.row)
            {
                case kLayersSection_Favorites:
                    cellTypeId = submenuLayerCell;
                    caption = OALocalizedString(@"Favorites");
                    break;
            }
            break;
        case kOptionsSection:
            switch(indexPath.row)
            {
                case kOptionsSection_SettingsRow:
                    cellTypeId = submenuCell;
                    caption = OALocalizedString(@"Settings");
                    icon = [UIImage imageNamed:@"menu_item_settings_icon.png"];
                    break;
                case kOptionsSection_DownloadsRow:
                    cellTypeId = submenuCell;
                    caption = OALocalizedString(@"Downloads");
                    icon = [UIImage imageNamed:@"menu_item_downloads_icon.png"];
                    break;
                case kOptionsSection_MyDataRow:
                    cellTypeId = submenuWithDetailsCell;
                    caption = OALocalizedString(@"My data");
                    details = OALocalizedString(@"Favorites, tracks, etc.");
                    icon = [UIImage imageNamed:@"menu_item_my_data_icon.png"];
                    break;
            }
            break;
    }
    
    // Obtain reusable cell or create one
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellTypeId];
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellTypeId];
    
    // Fill cell content
    cell.imageView.image = icon;
    cell.textLabel.text = caption;
    cell.detailTextLabel.text = details;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kMapSourceAndVariantsSection)
    {
        if (indexPath.row == 0)
        {
            [self openMenu:[[UIStoryboard storyboardWithName:@"MapSources" bundle:nil] instantiateInitialViewController]
                 forCellAt:indexPath];
        }
        else
        {
            id item_ = [_mapSourceAndVariants objectAtIndex:indexPath.row];
            if ([item_ isKindOfClass:[Item_MapStylePreset class]])
            {
                Item_MapStylePreset* item = (Item_MapStylePreset*)item_;

                _app.data.lastMapSource = item.mapSource;
            }
        }
    }
    else if (indexPath.section == kLayersSection)
    {
        switch (indexPath.row)
        {
            case kLayersSection_Favorites:
                [self openMenu:[[OAFavoritesLayerViewController alloc] init]
                     forCellAt:indexPath];
                break;
        }
    }
    else if (indexPath.section == kOptionsSection)
    {
        switch (indexPath.row)
        {
            case kOptionsSection_SettingsRow:
                OALog(@"open settings menu");
                break;
            case kOptionsSection_DownloadsRow:
                [self openMenu:[[UIStoryboard storyboardWithName:@"Downloads" bundle:nil] instantiateInitialViewController]
                     forCellAt:indexPath];
                break;
            case kOptionsSection_MyDataRow:
                [self openMenu:[[OAMyDataViewController alloc] init]
                     forCellAt:indexPath];
                break;
        }
    }
}

- (NSIndexPath*)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Disallow deselection completely
    return nil;
}

#pragma mark -

@end
