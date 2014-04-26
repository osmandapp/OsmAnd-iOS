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
#import "OAAutoObserverProxy.h"
#import "OAAppData.h"

#include <OsmAndCore/Map/IMapStylesCollection.h>
#include <OsmAndCore/Map/MapStyle.h>
#include <OsmAndCore/Map/MapStylesPresets.h>
#include <OsmAndCore/Map/IOnlineTileSources.h>
#include <OsmAndCore/Map/OnlineTileSources.h>

#include "Localization.h"
#import "OALog.h"

#define Item_MapStyle OAOptionsPanelViewController__Item_MapStyle
@interface Item_MapStyle : NSObject
@property std::shared_ptr<const OsmAnd::MapStyle> mapStyle;
@end
@implementation Item_MapStyle
@end

#define Item_MapStylePreset OAOptionsPanelViewController__Item_MapStylePreset
@interface Item_MapStylePreset : NSObject
@property OAMapSource* mapSource;
@property std::shared_ptr<const OsmAnd::MapStylePreset> mapStylePreset;
@property std::shared_ptr<const OsmAnd::MapStyle> mapStyle;
@end
@implementation Item_MapStylePreset
@end

#define Item_OnlineTileSource OAOptionsPanelViewController__Item_OnlineTileSource
@interface Item_OnlineTileSource : NSObject
@property std::shared_ptr<const OsmAnd::IOnlineTileSources::Source> onlineTileSource;
@end
@implementation Item_OnlineTileSource
@end

typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;

@interface OAOptionsPanelViewController () <UITableViewDelegate, UITableViewDataSource, UIPopoverControllerDelegate>

@end

@implementation OAOptionsPanelViewController
{
    OsmAndAppInstance _app;
    
    OAAutoObserverProxy* _lastMapSourceObserver;

    NSMutableArray* _mapSourceAndVariants;

    NSIndexPath* _lastMenuOriginCellPath;
    UIPopoverController* _lastMenuPopoverController;
}

#define kMapSourceAndVariantsSection 0
#define kLayersSection 1
#define kOptionsSection 2
#define kOptionsSection_SettingsRow 0
#define kOptionsSection_DownloadsRow 1
#define kOptionsSection_MyDataRow 2

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self ctor];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self ctor];
    }
    return self;
}

- (id)initWithStyle:(UITableViewStyle)style
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

    [self selectMapSource:animated];
    /*TODO:
    // Perform selection of proper preset
    OAMapSource* activeMapSource = [_app.data.mapSources mapSourceWithId:_app.data.activeMapSourceId];
    [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:[activeMapSource.presets indexOfPresetWithId:activeMapSource.activePresetId] + 1
                                                            inSection:kMapSourceAndVariantsSection]
                                animated:animated
                          scrollPosition:UITableViewScrollPositionNone];
    */

    // Deselect menu origin cell if reopened (on iPhone/iPod)
    if(_lastMenuOriginCellPath != nil &&
       [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        [self.tableView deselectRowAtIndexPath:_lastMenuOriginCellPath
                                      animated:animated];

        _lastMenuOriginCellPath = nil;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)obtainMapSourceAndVariants
{
    [_mapSourceAndVariants removeAllObjects];

    OAMapSource* mapSource = _app.data.lastMapSource;
    const auto resource = _app.resourcesManager->getResource(QString::fromNSString(mapSource.resourceId));

    // Online tile sources are simple to process:
    if(resource->type == OsmAndResourceType::OnlineTileSources)
    {
        const auto& onlineTileSources = std::static_pointer_cast<const OsmAnd::ResourcesManager::OnlineTileSourcesMetadata>(resource->metadata)->sources;

        Item_OnlineTileSource* item = [[Item_OnlineTileSource alloc] init];
        item.onlineTileSource = onlineTileSources->getSourceByName(QString::fromNSString(mapSource.subresourceId));

        [_mapSourceAndVariants addObject:item];
        return;
    }

    // For map styles, first find root map style
    std::shared_ptr<const OsmAnd::MapStyle> mapStyle;
    if(resource->type == OsmAndResourceType::MapStyle)
    {
        mapStyle = std::static_pointer_cast<const OsmAnd::ResourcesManager::MapStyleMetadata>(resource->metadata)->mapStyle;
    }
    else if(resource->type == OsmAndResourceType::MapStylesPresets)
    {
        const auto& presets = std::static_pointer_cast<const OsmAnd::ResourcesManager::MapStylesPresetsMetadata>(resource->metadata)->presets;
        const auto& preset = *presets->getCollection().begin();

        // Get proper name
        auto name = preset->styleName;
        if(!name.endsWith(QLatin1String(".render.xml")))
            name.append(QLatin1String(".render.xml"));

        // Get map style
        const auto citMapStyle = _app.resourcesManager->mapStylesCollection->getCollection().constFind(name);
        mapStyle = *citMapStyle;
    }

    Item_MapStyle* mapStyleItem = [[Item_MapStyle alloc] init];
    mapStyleItem.mapStyle = mapStyle;
    [_mapSourceAndVariants addObject:mapStyleItem];

    // Then find all presets for it
    QList< std::shared_ptr<const OsmAnd::ResourcesManager::Resource> > mapStylesPresetsResources;
    const auto builtinResources = _app.resourcesManager->getBuiltInResources();
    for(const auto& builtinResource : builtinResources)
    {
        if(builtinResource->type != OsmAndResourceType::MapStylesPresets)
            continue;

        mapStylesPresetsResources.push_back(builtinResource);
    }

    const auto localResources = _app.resourcesManager->getLocalResources();
    for(const auto& localResource : localResources)
    {
        if(localResource->type != OsmAndResourceType::MapStylesPresets)
            continue;

        mapStylesPresetsResources.push_back(localResource);
    }

    for(const auto& resource : mapStylesPresetsResources)
    {
        const auto& presets = std::static_pointer_cast<const OsmAnd::ResourcesManager::MapStylesPresetsMetadata>(resource->metadata)->presets;
        NSString* resourceId = resource->id.toNSString();

        for(const auto& preset : presets->getCollection())
        {
            // Get proper name
            auto styleName = mapStyle->name;
            if(!styleName.endsWith(QLatin1String(".render.xml")))
                styleName.append(QLatin1String(".render.xml"));

            // Skip if not for current map style
            if(styleName != mapStyle->name)
                continue;

            Item_MapStylePreset* item = [[Item_MapStylePreset alloc] init];
            item.mapSource = [[OAMapSource alloc] initWithResource:resourceId
                                                    andSubresource:preset->name.toNSString()];
            item.mapStylePreset = preset;
            item.mapStyle = mapStyle;

            [_mapSourceAndVariants addObject:item];
        }
    }
}

- (void)selectMapSource:(BOOL)animated
{
    if(!self.isViewLoaded)
        return;
}

- (void)onLastMapSourceChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self selectMapSource:YES];
    });
        /*TODO:
    // Change of map-source requires reloading of entire map section,
    // since not only name of active map source have changed, but also
    // set of presets available
    dispatch_async(dispatch_get_main_queue(), ^{
        // Detach from previous active map source
        if(_mapSourceNameObserver.isAttached)
            [_mapSourceNameObserver detach];
        if(_mapSourceActivePresetIdObserver.isAttached)
            [_mapSourceActivePresetIdObserver detach];
        if(_mapSourcePresetsObserver.isAttached)
            [_mapSourcePresetsObserver detach];
        if(_mapSourceAnyPresetChangeObserver.isAttached)
            [_mapSourceAnyPresetChangeObserver detach];

        // Attach to new one
        OAMapSource* activeMapSource = [_app.data.mapSources mapSourceWithId:_app.data.activeMapSourceId];
        [_mapSourceNameObserver observe:activeMapSource.nameChangeObservable];
        [_mapSourceActivePresetIdObserver observe:activeMapSource.activePresetIdChangeObservable];
        [_mapSourcePresetsObserver observe:activeMapSource.presets.collectionChangeObservable];
        [_mapSourceAnyPresetChangeObserver observe:activeMapSource.anyPresetChangeObservable];

        // Reload entire section
        [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:kMapSourceAndVariantsSection]
                      withRowAnimation:UITableViewRowAnimationAutomatic];

        // If current menu origin cell is from this section, maintain selection
        if(_lastMenuOriginCellPath != nil && _lastMenuOriginCellPath.section == kMapSourceAndVariantsSection)
        {
            [self.tableView selectRowAtIndexPath:_lastMenuOriginCellPath
                                        animated:YES
                                  scrollPosition:UITableViewScrollPositionNone];
        }

        // Perform selection of proper preset
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:[activeMapSource.presets indexOfPresetWithId:activeMapSource.activePresetId] + 1
                                                                inSection:kMapSourceAndVariantsSection]
                                    animated:YES
                              scrollPosition:UITableViewScrollPositionNone];
    });
         */
}
/*
- (void)onMapSourceNameChanged
{
    // Reload row with name of map source
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:0 inSection:kMapSourceAndVariantsSection] ]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
    });
}

- (void)onMapSourceActivePresetIdChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        OAMapSource* activeMapSource = [_app.data.mapSources mapSourceWithId:_app.data.activeMapSourceId];
        OAMapSourcePreset* activePreset = [activeMapSource.presets presetWithId:activeMapSource.activePresetId];

        // Get currently selected (if such exists)
        __block NSUUID* uiSelectedPresetId = nil;
        __block NSIndexPath* uiSelectedPresetIndexPath = nil;
        [[self.tableView indexPathsForSelectedRows] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSIndexPath* indexPath = obj;
            if(indexPath.section != kMapSourceAndVariantsSection || indexPath.row == 0)
                return;
            uiSelectedPresetId = [activeMapSource.presets idOfPresetAtIndex:indexPath.row - 1];
            uiSelectedPresetIndexPath = indexPath;
            *stop = YES;
        }];

        // If selection differs, select proper preset
        if(![activePreset.uniqueId isEqual:uiSelectedPresetId])
        {
            // Deselect old
            if(uiSelectedPresetId != nil)
                [self.tableView deselectRowAtIndexPath:uiSelectedPresetIndexPath animated:YES];

            // Select new
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:[activeMapSource.presets indexOfPresetWithId:activeMapSource.activePresetId] + 1
                                                                    inSection:kMapSourceAndVariantsSection]
                                        animated:YES
                                  scrollPosition:UITableViewScrollPositionNone];
        }
    });
}

- (void)onMapSourcePresetsCollectionChanged
{
    // Change of available set of presets for current map-source triggers
    // removal of all previous preset rows and inserting new ones,
    // along with chaning selection
    dispatch_async(dispatch_get_main_queue(), ^{
        OAMapSource* activeMapSource = [_app.data.mapSources mapSourceWithId:_app.data.activeMapSourceId];

        [self.tableView beginUpdates];
        NSInteger numberOfOldRows = [self.tableView numberOfRowsInSection:kMapSourceAndVariantsSection] - 1;
        NSInteger deltaBetweenNumberOfRows = numberOfOldRows - [activeMapSource.presets count];
        if(deltaBetweenNumberOfRows > 0)
        {
            NSMutableArray* affectedRows = [[NSMutableArray alloc] initWithCapacity:deltaBetweenNumberOfRows];
            for(NSInteger rowIdx = 0; rowIdx < deltaBetweenNumberOfRows; rowIdx++)
            {
                [affectedRows addObject:[NSIndexPath indexPathForRow:numberOfOldRows - rowIdx - 1
                                                           inSection:kMapSourceAndVariantsSection]];
            }
            [self.tableView deleteRowsAtIndexPaths:affectedRows
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        else if(deltaBetweenNumberOfRows < 0)
        {
            NSMutableArray* affectedRows = [[NSMutableArray alloc] initWithCapacity:-deltaBetweenNumberOfRows];
            for(NSInteger rowIdx = 0; rowIdx < -deltaBetweenNumberOfRows; rowIdx++)
            {
                [affectedRows addObject:[NSIndexPath indexPathForRow:numberOfOldRows + rowIdx
                                                           inSection:kMapSourceAndVariantsSection]];
            }
            [self.tableView insertRowsAtIndexPaths:affectedRows
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        [self.tableView endUpdates];
        NSMutableArray* affectedRows = [[NSMutableArray alloc] initWithCapacity:[activeMapSource.presets count]];
        for(NSInteger rowIdx = 0; rowIdx < [activeMapSource.presets count]; rowIdx++)
        {
            [affectedRows addObject:[NSIndexPath indexPathForRow:rowIdx
                                                       inSection:kMapSourceAndVariantsSection]];
        }
        [self.tableView reloadRowsAtIndexPaths:affectedRows
                              withRowAnimation:UITableViewRowAnimationAutomatic];

        // Verify selection:

        // Get currently selected (if such exists)
        __block NSUUID* uiSelectedPresetId = nil;
        __block NSIndexPath* uiSelectedPresetIndexPath = nil;
        [[self.tableView indexPathsForSelectedRows] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSIndexPath* indexPath = obj;
            if(indexPath.section != kMapSourceAndVariantsSection || indexPath.row == 0)
                return;
            uiSelectedPresetId = [activeMapSource.presets idOfPresetAtIndex:indexPath.row - 1];
            uiSelectedPresetIndexPath = indexPath;
            *stop = YES;
        }];

        // If selection differs, or selection index differ
        NSInteger actualizedSelectionIndex = [activeMapSource.presets indexOfPresetWithId:activeMapSource.activePresetId];
        if(![activeMapSource.activePresetId isEqual:uiSelectedPresetId] ||
           actualizedSelectionIndex != (uiSelectedPresetIndexPath.row - 1))
        {
            // Deselect old
            if(uiSelectedPresetId != nil)
                [self.tableView deselectRowAtIndexPath:uiSelectedPresetIndexPath animated:YES];

            // Select new
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:actualizedSelectionIndex + 1
                                                                    inSection:kMapSourceAndVariantsSection]
                                        animated:YES
                                  scrollPosition:UITableViewScrollPositionNone];
        }
    });
}

*/

- (void)onLocalResourcesChanged:(const QList<QString>&)ids
{
    [self obtainMapSourceAndVariants];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableIndexSet* indexSet = [NSMutableIndexSet indexSet];
        [indexSet addIndex:kMapSourceAndVariantsSection];
        [indexSet addIndex:kLayersSection];

        [self.tableView reloadSections:indexSet
                      withRowAnimation:UITableViewRowAnimationAutomatic];
    });
}

- (void)openMenu:(UIViewController*)menuViewController forCellAt:(NSIndexPath*)indexPath
{
    _lastMenuOriginCellPath = indexPath;

    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        // For iPhone and iPod, push menu to navigation controller
        [self.navigationController pushViewController:menuViewController
                                             animated:YES];
    }
    else //if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        // For iPad, open menu in a popover with it's own navigation controller
        UINavigationController* popoverNavigationController = [[UINavigationController alloc] initWithRootViewController:menuViewController];
        _lastMenuPopoverController = [[UIPopoverController alloc] initWithContentViewController:popoverNavigationController];
        _lastMenuPopoverController.delegate = self;

        UITableViewCell* originCell = [self.tableView cellForRowAtIndexPath:_lastMenuOriginCellPath];
        [_lastMenuPopoverController presentPopoverFromRect:originCell.frame
                                         inView:self.tableView
                       permittedArrowDirections:UIPopoverArrowDirectionLeft|UIPopoverArrowDirectionRight
                                       animated:YES];
    }
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad &&
       _lastMenuPopoverController == popoverController)
    {
        // Deselect menu item that was origin for this popover
        [self.tableView deselectRowAtIndexPath:_lastMenuOriginCellPath animated:YES];

        _lastMenuOriginCellPath = nil;
        _lastMenuPopoverController = nil;
    }
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
            return 4; //TODO: just a stub
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
    static NSString* const layerCell_Checked = @"layerCell_Checked";
    static NSString* const layerCell_Unchecked = @"layerCell_Unchecked";
    static NSString* const menuItemCell = @"menuItemCell";
    static NSString* const mapSourcePresetCell = @"mapSourcePresetCell";
    
    // Get content for cell and it's type id
    NSString* cellTypeId = nil;
    UIImage* icon = nil;
    NSString* caption = nil;
    switch (indexPath.section)
    {
        case kMapSourceAndVariantsSection:
            if(indexPath.row == 0)
            {
                cellTypeId = submenuCell;

                id item_ = [_mapSourceAndVariants firstObject];
                if([item_ isKindOfClass:[Item_OnlineTileSource class]])
                {
                    Item_OnlineTileSource* item = (Item_OnlineTileSource*)item_;

                    caption = item.onlineTileSource->name.toNSString();
                }
                else if([item_ isKindOfClass:[Item_MapStyle class]])
                {
                    Item_MapStyle* item = (Item_MapStyle*)item_;

                    caption = item.mapStyle->title.toNSString();
                }
            }
            else
            {
                cellTypeId = mapSourcePresetCell;

                id item_ = [_mapSourceAndVariants objectAtIndex:indexPath.row];
                if([item_ isKindOfClass:[Item_MapStylePreset class]])
                {
                    Item_MapStylePreset* item = (Item_MapStylePreset*)item_;

                    caption = item.mapStylePreset->name.toNSString();
                    //TODO: icon
                }
                /*
                OAMapSource* activeMapSource = [_app.data.mapSources mapSourceWithId:_app.data.activeMapSourceId];

                NSUUID* presetId = [activeMapSource.presets idOfPresetAtIndex:indexPath.row - 1];
                OAMapSourcePreset* preset = [activeMapSource.presets presetWithId:presetId];
                
                cellTypeId = mapSourcePresetCell;
                if(preset.iconImageName != nil)
                    icon = [UIImage imageNamed:preset.iconImageName];
                else
                {
                    switch (preset.type)
                    {
                        default:
                        case OAMapSourcePresetTypeUndefined:
                        case OAMapSourcePresetTypeGeneral:
                            icon = [UIImage imageNamed:@"map_source_preset_type_general_icon.png"];
                            break;
                        case OAMapSourcePresetTypeCar:
                            icon = [UIImage imageNamed:@"map_source_preset_type_car_icon.png"];
                            break;
                        case OAMapSourcePresetTypeBicycle:
                            icon = [UIImage imageNamed:@"map_source_preset_type_bicycle_icon.png"];
                            break;
                        case OAMapSourcePresetTypePedestrian:
                            icon = [UIImage imageNamed:@"map_source_preset_type_pedestrian_icon.png"];
                            break;
                    }
                }
                caption = preset.name;
                 */
            }
            break;
        case kLayersSection:
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
                    cellTypeId = submenuCell;
                    caption = OALocalizedString(@"My data");
                    icon = [UIImage imageNamed:@"menu_item_my_data_icon.png"];
                    break;
            }
            break;
    }
    if(cellTypeId == nil)
        cellTypeId = menuItemCell;
    
    // Obtain reusable cell or create one
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellTypeId];
    if(cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellTypeId];
    
    // Fill cell content
    cell.imageView.image = icon;
    cell.textLabel.text = caption;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (NSIndexPath*)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Allow selection only of:
    //  - map-sources menu
    //  - map-source preset set
    //  - layers menu
    //  - options menu
    BOOL selectionAllowed = NO;
    selectionAllowed = selectionAllowed || (indexPath.section == kMapSourceAndVariantsSection && indexPath.row == 0);
    selectionAllowed = selectionAllowed || (indexPath.section == kMapSourceAndVariantsSection && indexPath.row > 0);
    selectionAllowed = selectionAllowed || (indexPath.section == kLayersSection && indexPath.row == 0);
    selectionAllowed = selectionAllowed || (indexPath.section == kOptionsSection);
    if(!selectionAllowed)
        return nil;
    
    // Obtain current selection
    NSArray* currentSelections = [tableView indexPathsForSelectedRows];
    
    // Only one menu is allowed to be selected
    if(((indexPath.section == kMapSourceAndVariantsSection ||
         indexPath.section == kLayersSection) && indexPath.row == 0) ||
       indexPath.section == kOptionsSection)
    {
        for (NSIndexPath* selection in currentSelections)
        {
            if(((selection.section == kMapSourceAndVariantsSection ||
                 selection.section == kLayersSection) && selection.row == 0) ||
               selection.section == kOptionsSection)
            {
                if(![selection isEqual:indexPath])
                    [tableView deselectRowAtIndexPath:selection animated:YES];
            }
        }
    }
    
    // Only one preset is allowed to be selected
    if(indexPath.section == kMapSourceAndVariantsSection && indexPath.row > 0)
    {
        for (NSIndexPath* selection in currentSelections)
        {
            if(selection.section == kMapSourceAndVariantsSection && selection.row > 0 && selection.row != indexPath.row)
                [tableView deselectRowAtIndexPath:selection animated:YES];
        }
    }

    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == kMapSourceAndVariantsSection)
    {
        if(indexPath.row == 0)
        {
            [self openMenu:[[UIStoryboard storyboardWithName:@"MapSources" bundle:nil] instantiateInitialViewController]
                 forCellAt:indexPath];
        }
        else
        {
            /*
            OAMapSource* activeMapSource = [_app.data.mapSources mapSourceWithId:_app.data.activeMapSourceId];

            NSUUID* newPresetId = [activeMapSource.presets idOfPresetAtIndex:indexPath.row - 1];
            activeMapSource.activePresetId = newPresetId;
             */
        }
    }
    else if(indexPath.section == kLayersSection)
    {
        if(indexPath.row == 0)
        {
            //TODO: open menu
            OALog(@"open layers menu");
        }
        else
        {
            OALog(@"activate/deactivate layer");
        }
    }
    else if(indexPath.section == kOptionsSection)
    {
        switch (indexPath.row)
        {
            case kOptionsSection_SettingsRow:
                [self openMenu:[[UIStoryboard storyboardWithName:@"Settings" bundle:nil] instantiateInitialViewController]
                     forCellAt:indexPath];
                break;
            case kOptionsSection_DownloadsRow:
                [self openMenu:[[UIStoryboard storyboardWithName:@"Downloads" bundle:nil] instantiateInitialViewController]
                     forCellAt:indexPath];
                break;
            case kOptionsSection_MyDataRow:
                OALog(@"open my-data menu");
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
