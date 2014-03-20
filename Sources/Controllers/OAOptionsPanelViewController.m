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
#import "OAConfiguration.h"
#import "OAMapSourcePresets.h"
#import "OAMapSourcePreset.h"

#include "Localization.h"

@interface OAOptionsPanelViewController ()

@property (weak, nonatomic) IBOutlet UITableView *optionsTableview;

@end

@implementation OAOptionsPanelViewController
{
    OsmAndAppInstance _app;
    
    OAAutoObserverProxy* _configurationObserver;
    
    OAMapSourcePresets* _mapSourcePresets;
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
    
    _configurationObserver = [[OAAutoObserverProxy alloc] initWith:self withHandler:@selector(onConfigurationChanged:withKey:andValue:)];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self refreshCachedData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)onConfigurationChanged:(id)observable withKey:(id)key andValue:(id)value
{
    if([kMapSource isEqualToString:key] || [kMapSourcesPresets isEqualToString:key])
    {
        // Force reload of list content
        dispatch_async(dispatch_get_main_queue(), ^{
            [self refreshCachedData];
            [_optionsTableview reloadData];
        });
    }
}

- (void)refreshCachedData
{
    _mapSourcePresets = [_app.configuration mapSourcePresetsFor:_app.configuration.mapSource];
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
        case kMapSourcesAndPresetsSection:
        {
            NSInteger rowsCount = 1 /* 'Maps' */;
            
            // Append rows to show all available presets for current map source
            if(_mapSourcePresets != nil)
                rowsCount += [_mapSourcePresets.presets count];
            
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
                NSUUID* presetId = [_mapSourcePresets.order objectAtIndex:indexPath.row - 1];
                OAMapSourcePreset* preset = [_mapSourcePresets.presets objectForKey:presetId];
                
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
    
//    NSLog(@"will select %d.%d", indexPath.section, indexPath.row);
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"selected %d.%d", indexPath.section, indexPath.row);
}

- (NSIndexPath*)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"will deselect %d.%d", indexPath.section, indexPath.row);
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"deselected %d.%d", indexPath.section, indexPath.row);
}

- (void)tableView:(UITableView *)tableView didHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"highlighted %d.%d", indexPath.section, indexPath.row);
}

- (void)tableView:(UITableView *)tableView didUnhighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"unhighlighted %d.%d", indexPath.section, indexPath.row);
}

#pragma mark -

@end
