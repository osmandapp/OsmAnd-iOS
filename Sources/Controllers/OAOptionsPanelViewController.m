//
//  OAOptionsPanelViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/20/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OAOptionsPanelViewController.h"

#import "OsmAndApp.h"
#import "UIViewController+OARootVC.h"
#import "OAAutoObserverProxy.h"
#import "OAAppData.h"
#import "OAMapSourcePreset.h"

#include "Localization.h"

@interface OAOptionsPanelViewController ()

@property (weak, nonatomic) IBOutlet UITableView *optionsTableview;

@end

@implementation OAOptionsPanelViewController
{
    OsmAndAppInstance _app;
    
    OAAutoObserverProxy* _activeMapSourceIdObserver;
    OAAutoObserverProxy* _mapSourceActivePresetIdObserver;
    OAAutoObserverProxy* _mapSourcePresetsObserver;
}

#define kMapSourcesAndPresetsSection 0
#define kLayersSection 1
#define kSettingsSection 2

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

- (void)ctor
{
    _app = [OsmAndApp instance];
    
    _activeMapSourceIdObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                           withHandler:@selector(onActiveMapSourceIdChanged)
                                                            andObserve:_app.data.activeMapSourceIdChangeObservable];
    OAMapSource* activeMapSource = [_app.data.mapSources mapSourceWithId:_app.data.activeMapSourceId];
    _mapSourceActivePresetIdObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                 withHandler:@selector(onMapSourceActivePresetIdChanged)
                                                                  andObserve:activeMapSource.activePresetIdChangeObservable];
    _mapSourcePresetsObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                          withHandler:@selector(onMapSourcePresetsCollectionChanged)
                                                           andObserve:activeMapSource.presets.collectionChangeObservable];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Perform selection of proper preset
    [_optionsTableview selectRowAtIndexPath:[NSIndexPath indexPathForRow:[_app.data.mapSources indexOfMapSourceWithId:_app.data.activeMapSourceId] + 1
                                                               inSection:kMapSourcesAndPresetsSection]
                                   animated:animated
                             scrollPosition:UITableViewScrollPositionNone];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onActiveMapSourceIdChanged
{
    // Change of map-source requires reloading of entire map section,
    // since not only name of active map source have changed, but also
    // set of presets available
    dispatch_async(dispatch_get_main_queue(), ^{
        // Detach from previous active map source
        [_mapSourceActivePresetIdObserver detach];
        [_mapSourcePresetsObserver detach];

        // Attach to new one
        OAMapSource* activeMapSource = [_app.data.mapSources mapSourceWithId:_app.data.activeMapSourceId];
        _mapSourceActivePresetIdObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                     withHandler:@selector(onMapSourceActivePresetIdChanged)
                                                                      andObserve:activeMapSource.activePresetIdChangeObservable];
        _mapSourcePresetsObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                              withHandler:@selector(onMapSourcePresetsCollectionChanged)
                                                               andObserve:activeMapSource.presets.collectionChangeObservable];

        // Reload entire section
        [_optionsTableview reloadSections:[[NSIndexSet alloc] initWithIndex:kMapSourcesAndPresetsSection]
                         withRowAnimation:UITableViewRowAnimationAutomatic];

        // Perform selection of proper preset
        [_optionsTableview selectRowAtIndexPath:[NSIndexPath indexPathForRow:[activeMapSource.presets indexOfPresetWithId:activeMapSource.activePresetId] + 1
                                                                   inSection:kMapSourcesAndPresetsSection]
                                       animated:YES
                                 scrollPosition:UITableViewScrollPositionNone];
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
        [[_optionsTableview indexPathsForSelectedRows] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSIndexPath* indexPath = obj;
            if(indexPath.section != kMapSourcesAndPresetsSection || indexPath.row == 0)
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
                [_optionsTableview deselectRowAtIndexPath:uiSelectedPresetIndexPath animated:YES];

            // Select new
            [_optionsTableview selectRowAtIndexPath:[NSIndexPath indexPathForRow:[activeMapSource.presets indexOfPresetWithId:activeMapSource.activePresetId] + 1
                                                                       inSection:kMapSourcesAndPresetsSection]
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

        [_optionsTableview beginUpdates];
        NSInteger numberOfOldRows = [_optionsTableview numberOfRowsInSection:kMapSourcesAndPresetsSection] - 1;
        NSInteger deltaBetweenNumberOfRows = numberOfOldRows - [activeMapSource.presets count];
        if(deltaBetweenNumberOfRows > 0)
        {
            NSMutableArray* affectedRows = [[NSMutableArray alloc] initWithCapacity:deltaBetweenNumberOfRows];
            for(NSInteger rowIdx = 0; rowIdx < deltaBetweenNumberOfRows; rowIdx++)
            {
                [affectedRows addObject:[NSIndexPath indexPathForRow:numberOfOldRows - rowIdx - 1
                                                           inSection:kMapSourcesAndPresetsSection]];
            }
            [_optionsTableview deleteRowsAtIndexPaths:affectedRows
                                     withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        else if(deltaBetweenNumberOfRows < 0)
        {
            NSMutableArray* affectedRows = [[NSMutableArray alloc] initWithCapacity:-deltaBetweenNumberOfRows];
            for(NSInteger rowIdx = 0; rowIdx < -deltaBetweenNumberOfRows; rowIdx++)
            {
                [affectedRows addObject:[NSIndexPath indexPathForRow:numberOfOldRows + rowIdx
                                                           inSection:kMapSourcesAndPresetsSection]];
            }
            [_optionsTableview insertRowsAtIndexPaths:affectedRows
                                     withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        [_optionsTableview endUpdates];
        NSMutableArray* affectedRows = [[NSMutableArray alloc] initWithCapacity:[activeMapSource.presets count]];
        for(NSInteger rowIdx = 0; rowIdx < [activeMapSource.presets count]; rowIdx++)
        {
            [affectedRows addObject:[NSIndexPath indexPathForRow:rowIdx
                                                       inSection:kMapSourcesAndPresetsSection]];
        }
        [_optionsTableview reloadRowsAtIndexPaths:affectedRows
                                 withRowAnimation:UITableViewRowAnimationAutomatic];

        // Verify selection:

        // Get currently selected (if such exists)
        __block NSUUID* uiSelectedPresetId = nil;
        __block NSIndexPath* uiSelectedPresetIndexPath = nil;
        [[_optionsTableview indexPathsForSelectedRows] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSIndexPath* indexPath = obj;
            if(indexPath.section != kMapSourcesAndPresetsSection || indexPath.row == 0)
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
                [_optionsTableview deselectRowAtIndexPath:uiSelectedPresetIndexPath animated:YES];

            // Select new
            [_optionsTableview selectRowAtIndexPath:[NSIndexPath indexPathForRow:actualizedSelectionIndex + 1
                                                                       inSection:kMapSourcesAndPresetsSection]
                                           animated:YES
                                     scrollPosition:UITableViewScrollPositionNone];
        }
    });
}

//- (void)updateMapSourcesAnd

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3 /* Maps section, Layers section, Settings section */;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case kMapSourcesAndPresetsSection:
        {
            NSInteger rowsCount = 1 /* 'Maps' */;
            
            // Append rows to show all available presets for current map source
            OAMapSource* activeMapSource = [_app.data.mapSources mapSourceWithId:_app.data.activeMapSourceId];
            if(activeMapSource != nil)
                rowsCount += [activeMapSource.presets count];

            return rowsCount;
        } break;
        case kLayersSection:
            return 10;
        case kSettingsSection:
            return 1;
            
        default:
            return 0;
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
        case kMapSourcesAndPresetsSection:
            if(indexPath.row == 0)
            {
                cellTypeId = submenuCell;
                caption = OALocalizedString(@"Maps");
            }
            else
            {
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
            }
            break;
        case kLayersSection:
            break;
        case kSettingsSection:
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
    //  - settings menu
    BOOL selectionAllowed = NO;
    selectionAllowed = selectionAllowed || (indexPath.section == kMapSourcesAndPresetsSection && indexPath.row == 0);
    selectionAllowed = selectionAllowed || (indexPath.section == kMapSourcesAndPresetsSection && indexPath.row > 0);
    selectionAllowed = selectionAllowed || (indexPath.section == kLayersSection && indexPath.row == 0);
    selectionAllowed = selectionAllowed || (indexPath.section == kSettingsSection && indexPath.row == 0);
    if(!selectionAllowed)
        return nil;
    
    // Obtain current selection
    NSArray* currentSelections = [tableView indexPathsForSelectedRows];
    
    // Only one menu is allowed to be selected
    if((indexPath.section == kMapSourcesAndPresetsSection ||
        indexPath.section == kLayersSection ||
        indexPath.section == kSettingsSection) && indexPath.row == 0 )
    {
        for (NSIndexPath* selection in currentSelections)
        {
            if((selection.section == kMapSourcesAndPresetsSection ||
                selection.section == kLayersSection ||
                selection.section == kSettingsSection) && selection.row == 0)
            {
                if(selection.section != indexPath.section)
                    [tableView deselectRowAtIndexPath:selection animated:YES];
            }
        }
    }
    
    // Only one preset is allowed to be selected
    if(indexPath.section == kMapSourcesAndPresetsSection && indexPath.row > 0)
    {
        for (NSIndexPath* selection in currentSelections)
        {
            if(selection.section == kMapSourcesAndPresetsSection && selection.row > 0 && selection.row != indexPath.row)
                [tableView deselectRowAtIndexPath:selection animated:YES];
        }
    }

    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == kMapSourcesAndPresetsSection && indexPath.row == 0)
    {
        //TODO: open menu
    }
    else if(indexPath.section == kMapSourcesAndPresetsSection && indexPath.row > 0)
    {
        OAMapSource* activeMapSource = [_app.data.mapSources mapSourceWithId:_app.data.activeMapSourceId];

        NSUUID* newPresetId = [activeMapSource.presets idOfPresetAtIndex:indexPath.row - 1];
        activeMapSource.activePresetId = newPresetId;
    }
}

- (NSIndexPath*)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Disallow deselection completely
    //NOTE: maybe eventually allow to hide slide-out menus by deselection
    return nil;
}

#pragma mark -

@end
