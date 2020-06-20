//
//  OAMapSettingsOverlayUnderlayScreen.m
//  OsmAnd
//
//  Created by Alexey Kulish on 05/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAMapSettingsOverlayUnderlayScreen.h"
#import "OAMapSettingsViewController.h"
#import "Localization.h"
#import "OASliderCell.h"
#import "OASwitchTableViewCell.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapCreatorHelper.h"
#import "OAMapStyleSettings.h"
#import "OASettingSwitchCell.h"
#import "OATitleSliderTableViewCell.h"
#import "OAIconTextDescButtonTableViewCell.h"
#import "OAButtonCell.h"
#import "OAColors.h"
#import "OALocalResourceInformationViewController.h"
#import "OASQLiteTileSource.h"
#import "OAOnlineTilesEditingViewController.h"
#import "OAMapCreatorHelper.h"
#import "OAAutoObserverProxy.h"

#include <QSet>

#include <OsmAndCore/Map/IMapStylesCollection.h>
#include <OsmAndCore/Map/UnresolvedMapStyle.h>
#include <OsmAndCore/Map/IOnlineTileSources.h>
#include <OsmAndCore/Map/OnlineTileSources.h>

#define kCellTypeTitleSlider @"title_slider_cell"
#define kCellTypeSwitch @"switch_cell"
#define kCellTypeButton @"button_cell"
#define kCellTypeIconSwitch @"icon_switch_cell"
#define kCellTypeMap @"icon_text_desc_button_cell"

#define _(name) OAMapSourcesOverlayUnderlayScreen__##name
#define commonInit _(commonInit)
#define deinit _(deinit)

#define Item _(Item)
@interface Item : NSObject
@property OAMapSource* mapSource;
@property std::shared_ptr<const OsmAnd::ResourcesManager::Resource> resource;
@property NSString *path;
@end
@implementation Item
@end

#define Item_OnlineTileSource _(Item_OnlineTileSource)
@interface Item_OnlineTileSource : Item
@property std::shared_ptr<const OsmAnd::IOnlineTileSources::Source> onlineTileSource;
@end
@implementation Item_OnlineTileSource
@end

#define Item_SqliteDbTileSource _(Item_SqliteDbTileSource)
@interface Item_SqliteDbTileSource : Item
@property uint64_t size;
@property BOOL isOnline;
@end
@implementation Item_SqliteDbTileSource
@end

typedef OsmAnd::ResourcesManager::ResourceType OsmAndResourceType;

typedef enum
{
    EMapSettingOverlay = 0,
    EMapSettingUnderlay,
    
} EMapSettingType;

static NSInteger kMapVisibilitySection = 1;
static NSInteger kAvailableLayersSection = 2;
static NSInteger kButtonsSection;

@interface OAMapSettingsOverlayUnderlayScreen () <OAIconTextDescButtonCellDelegate, OATilesEditingViewControllerDelegate>

@end

@implementation OAMapSettingsOverlayUnderlayScreen
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;

    NSMutableArray* _onlineMapSources;
    EMapSettingType _mapSettingType;
    NSArray *_data;
    BOOL _isEnabled;
    
    OAMapStyleSettings *_styleSettings;
    OAMapStyleParameter *_hidePolygonsParameter;
    OAAutoObserverProxy *_sqlitedbResourcesChangedObserver;
}

@synthesize settingsScreen, tableData, vwController, tblView, title, isOnlineMapSource;


- (id) initWithTable:(UITableView *)tableView viewController:(OAMapSettingsViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        
        if ([param isEqualToString:@"overlay"]) {
            _mapSettingType = EMapSettingOverlay;
            title = OALocalizedString(@"map_settings_over");
            settingsScreen = EMapSettingsScreenOverlay;

        } else {
            _mapSettingType = EMapSettingUnderlay;
            title = OALocalizedString(@"map_settings_under");
            settingsScreen = EMapSettingsScreenUnderlay;
        }
        
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
    _styleSettings = [OAMapStyleSettings sharedInstance];
    _hidePolygonsParameter = [_styleSettings getParameter:@"noPolygons"];

    _sqlitedbResourcesChangedObserver = [[OAAutoObserverProxy alloc] initWith:self withHandler:@selector(onSqlitedbResourcesChanged:) andObserve:[OAMapCreatorHelper sharedInstance].sqlitedbResourcesChangedObservable];
    
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
    const auto localResources = _app.resourcesManager->getLocalResources();
    for(const auto& localResource : localResources)
        if (localResource->type == OsmAndResourceType::OnlineTileSources)
            onlineTileSourcesResources.push_back(localResource);
    
    // Process online tile sources resources
    for(const auto& resource : onlineTileSourcesResources)
    {
        const auto& onlineTileSources = std::static_pointer_cast<const OsmAnd::ResourcesManager::OnlineTileSourcesMetadata>(resource->metadata)->sources;
        NSString* resourceId = resource->id.toNSString();
        
        for(const auto& onlineTileSource : onlineTileSources->getCollection())
        {
            Item_OnlineTileSource* item = [[Item_OnlineTileSource alloc] init];
            
            NSString *caption = onlineTileSource->name.toNSString();
            
            item.mapSource = [[OAMapSource alloc] initWithResource:resourceId
                                                        andVariant:onlineTileSource->name.toNSString() name:caption];
            item.resource = resource;
            item.onlineTileSource = onlineTileSource;
            item.path = [_app.cachePath stringByAppendingPathComponent:caption];
            [_onlineMapSources addObject:item];
        }
    }
    
    NSArray *arr = [_onlineMapSources sortedArrayUsingComparator:^NSComparisonResult(Item_OnlineTileSource* obj1, Item_OnlineTileSource* obj2) {
        NSString *caption1 = obj1.onlineTileSource->name.toNSString();
        NSString *caption2 = obj2.onlineTileSource->name.toNSString();
        return [caption2 compare:caption1];
    }];
    
    [_onlineMapSources setArray:arr];

    
    NSMutableArray *sqlitedbArr = [NSMutableArray array];
    for (NSString *fileName in [OAMapCreatorHelper sharedInstance].files.allKeys)
    {
        Item_SqliteDbTileSource* item = [[Item_SqliteDbTileSource alloc] init];
        item.mapSource = [[OAMapSource alloc] initWithResource:fileName andVariant:@"" name:@"sqlitedb"];
        item.path = [OAMapCreatorHelper sharedInstance].files[fileName];
        item.size = [[[NSFileManager defaultManager] attributesOfItemAtPath:item.path error:nil] fileSize];
        item.isOnline = [OASQLiteTileSource isOnlineTileSource:item.path];
        [sqlitedbArr addObject:item];
    }
    
    [sqlitedbArr sortUsingComparator:^NSComparisonResult(Item_SqliteDbTileSource *obj1, Item_SqliteDbTileSource *obj2) {
        return [obj1.mapSource.resourceId caseInsensitiveCompare:obj2.mapSource.resourceId];
    }];
    
    [_onlineMapSources addObjectsFromArray:sqlitedbArr];
    
    
    NSMutableArray *sliderArr = [NSMutableArray new];
    [sliderArr addObject:@{
                        @"type" : kCellTypeTitleSlider,
                        @"title" : _mapSettingType == EMapSettingOverlay ? OALocalizedString(@"map_settings_transp")
                                                                        : OALocalizedString(@"map_settings_base_transp"),
                         }];
    [sliderArr addObject:@{
                        @"type" : kCellTypeSwitch,
                        @"title": OALocalizedString(@"map_settings_show_slider_map")
                         }];
    
    NSMutableArray *availableLayersArr = [NSMutableArray new];
    for (Item* source in _onlineMapSources)
    {
        [availableLayersArr addObject:@{
                        @"type" : kCellTypeMap,
                        @"source": source
                        }];
    }
    [availableLayersArr addObject:@{
                        @"type" : kCellTypeButton,
                        @"title": OALocalizedString(@"map_settings_install_more")
                         }];
    
    NSMutableArray *buttonsArray = [NSMutableArray new];
    [buttonsArray addObject:@{
                        @"type" : kCellTypeButton,
                        @"title" : OALocalizedString(@"map_settings_add_online_source"),
                         }];
    [buttonsArray addObject:@{
                        @"type" : kCellTypeButton,
                        @"title": OALocalizedString(@"import_from_docs")
                         }];
    
    NSMutableArray *tableData = [NSMutableArray new];
    [tableData addObject:@{
        @"type" : kCellTypeIconSwitch,
    }];
    [tableData addObject: sliderArr];
    [tableData addObject: availableLayersArr];
    if (_mapSettingType == EMapSettingUnderlay)
    {
        [tableData addObject:@{
            @"type" : kCellTypeSwitch,
            @"title": OALocalizedString(@"map_settings_hide_polygons")
        }];
    }
    [tableData addObject: buttonsArray];
    _data = [NSArray arrayWithArray:tableData];
    
    tblView.estimatedRowHeight = kEstimatedRowHeight;
    tblView.rowHeight = UITableViewAutomaticDimension;

    if (_mapSettingType == EMapSettingOverlay)
        _isEnabled = _app.data.overlayMapSource != nil;
    else if (_mapSettingType == EMapSettingUnderlay)
        _isEnabled = _app.data.underlayMapSource != nil;
    else
        _isEnabled = NO;

    kButtonsSection = _mapSettingType == EMapSettingOverlay ? 3 : 4;
}

- (void) onSqlitedbResourcesChanged:(id)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupView];
        [tblView reloadData];
    });
}

-(void) initData
{
}


- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0)
    {
        return _data[indexPath.section];
    }
    else if (indexPath.section == 1)
    {
        return _data[indexPath.section][indexPath.row];
    }
    else if (indexPath.section == 2)
    {
        if (indexPath.row < _onlineMapSources.count)
            return _data[indexPath.section][indexPath.row];
        else if (indexPath.row == _onlineMapSources.count)
            return _data[indexPath.section][_onlineMapSources.count];
    }
    else if ((_mapSettingType == EMapSettingOverlay && indexPath.section == 3) || (_mapSettingType == EMapSettingUnderlay && indexPath.section == 4))
    {
        return _data[indexPath.section][indexPath.row];
    }
    else if (_mapSettingType == EMapSettingUnderlay && indexPath.section == 3)
    {
        return _data[indexPath.section];
    }
    return nil;
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _isEnabled ? _data.count : 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section)
    {
        case 0:
            return 1;
        case 1:
            return 2;
        case 2:
            return [_onlineMapSources count] + 1;
        case 3:
            return _mapSettingType == EMapSettingOverlay ? 2 : 1;
        case 4:
            return 2;
        default:
            return 0;
    }
}

- (NSString*) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return section == kAvailableLayersSection ? OALocalizedString(@"map_settings_avail_lay") : @"";
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if ((_mapSettingType == EMapSettingOverlay && section == 3) || (_mapSettingType == EMapSettingUnderlay && section == 4))
        return OALocalizedString(@"map_settings_add_maps_desc");
    else if (_mapSettingType == EMapSettingUnderlay && section == 3 )
        return OALocalizedString(@"map_settings_hide_polygons_desc");
    else
        return @"";
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item =  [self getItem:indexPath];

    if ([item[@"type"] isEqualToString:kCellTypeIconSwitch])
    {
        static NSString* const identifierCell = @"OASettingSwitchCell";
        OASettingSwitchCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingSwitchCell" owner:self options:nil];
            cell = (OASettingSwitchCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.descriptionView.hidden = YES;
        }
        if (cell)
        {
            cell.textView.text = _isEnabled ? OALocalizedString(@"shared_string_enabled") : OALocalizedString(@"rendering_value_disabled_name");
            NSString *imgName = _isEnabled ? @"ic_custom_show.png" : @"ic_custom_hide.png";
            cell.imgView.image = [[UIImage imageNamed:imgName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.imgView.tintColor = _isEnabled ? UIColorFromRGB(color_dialog_buttons_dark) : UIColorFromRGB(color_tint_gray);
            
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView setOn:_isEnabled];
            [cell.switchView addTarget:self action:@selector(turnLayerOnOff:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeMap])
    {
        static NSString* const identifierCell = @"OAIconTextDescButtonCell";
        OAIconTextDescButtonCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
           NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextDescButtonTableViewCell" owner:self options:nil];
           cell = (OAIconTextDescButtonCell *)[nib objectAtIndex:0];
        }
        
        NSString *caption = nil;
        NSString *description = nil;
        NSString *size = nil;
        Item* someItem = nil;
        
        someItem = item[@"source"];
        
        if ([someItem isKindOfClass:[Item_OnlineTileSource class]])
        {
            if (someItem.resource->type == OsmAndResourceType::OnlineTileSources)
            {
                Item_OnlineTileSource* item = (Item_OnlineTileSource*)someItem;
                caption = item.mapSource.name;
                description = OALocalizedString(@"online_map");
                cell.leftIconView.image = [[UIImage imageNamed:@"ic_custom_map_online"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                cell.leftIconView.tintColor = UIColorFromRGB(color_chart_orange);
            }
        }
        
        else if ([someItem isKindOfClass:[Item_SqliteDbTileSource class]])
        {
            caption = [[someItem.mapSource.resourceId stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
            Item_SqliteDbTileSource *sqlite = (Item_SqliteDbTileSource *)someItem;
            description = sqlite.isOnline ? OALocalizedString(@"online_raster_map") : OALocalizedString(@"offline_raster_map");
            size = [NSByteCountFormatter stringFromByteCount:sqlite.size countStyle:NSByteCountFormatterCountStyleFile];
            cell.leftIconView.image = [[UIImage imageNamed:@"ic_custom_map"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.leftIconView.tintColor = UIColorFromRGB(color_chart_orange);
        }
        
        cell.titleLabel.text = caption;
        if (size)
            cell.descLabel.text = [[description stringByAppendingString:@" • "] stringByAppendingString:size];
        else
            cell.descLabel.text = description;
        
        OAMapSource* mapSource;
        if (_mapSettingType == EMapSettingOverlay)
            mapSource = _app.data.overlayMapSource;
        else if (_mapSettingType == EMapSettingUnderlay)
            mapSource = _app.data.underlayMapSource;

        if ([mapSource isEqual:someItem.mapSource])
            [cell.checkButton setImage:[UIImage imageNamed:@"menu_cell_selected.png"] forState:UIControlStateNormal];
        else
            [cell.checkButton setImage:nil forState:UIControlStateNormal];
        cell.delegate = self;
        cell.checkButton.tag = indexPath.row;
        return cell;
    }
    
    else if ([item[@"type"] isEqualToString:kCellTypeSwitch])
    {
        static NSString* const identifierCell = @"OASwitchTableViewCell";
        OASwitchTableViewCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASwitchCell" owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            [cell.textView setText:item[@"title"]];
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            if (indexPath.section == kMapVisibilitySection)
            {
                [cell.switchView setOn: [self isOpacitySliderVisible]];
                [cell.switchView addTarget:self action:@selector(onShowSwitchChanged:) forControlEvents:UIControlEventValueChanged];
            }
            else
            {
                [cell.switchView setOn:[_hidePolygonsParameter.value isEqualToString:@"true"]];
                [cell.switchView addTarget:self action:@selector(onPolygonsChanged:) forControlEvents:UIControlEventValueChanged];
            }
        }
        return cell;
    }
    
    else if ([item[@"type"] isEqualToString:kCellTypeTitleSlider])
    {
        static NSString* const identifierCell = @"OATitleSliderTableViewCell";
        OATitleSliderTableViewCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATitleSliderCell" owner:self options:nil];
            cell = (OATitleSliderTableViewCell *)[nib objectAtIndex:0];
            [cell.sliderView addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        }
        
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            if (_mapSettingType == EMapSettingOverlay)
                cell.sliderView.value = _app.data.overlayAlpha;
            else if (_mapSettingType == EMapSettingUnderlay)
                cell.sliderView.value = _app.data.underlayAlpha;
            cell.valueLabel.textColor = UIColorFromRGB(color_text_footer);
            cell.valueLabel.text = [NSString stringWithFormat:@"%.0f%@", cell.sliderView.value * 100, @"%"];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeButton])
    {
        static NSString* const identifierCell = @"OAButtonCell";
        OAButtonCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAButtonCell" owner:self options:nil];
            cell = (OAButtonCell *)[nib objectAtIndex:0];
            [cell showImage:NO];
            [cell.button setTitleColor:[UIColor colorWithRed:87.0/255.0 green:20.0/255.0 blue:204.0/255.0 alpha:1] forState:UIControlStateNormal];
        }
        if (cell)
        {
            [cell.button setTitle:item[@"title"] forState:UIControlStateNormal];
            [cell.button removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            if (indexPath.section == kAvailableLayersSection)
                [cell.button addTarget:self action:@selector(installMorePressed) forControlEvents:UIControlEventTouchUpInside];
            else
            {
                if (indexPath.row == 0)
                    [cell.button addTarget:self action:@selector(addPressed) forControlEvents:UIControlEventTouchUpInside];
                else if (indexPath.row == 1)
                    [cell.button addTarget:self action:@selector(importPressed) forControlEvents:UIControlEventTouchUpInside];
            }
        }
        return cell;
    }
    return nil;
}

- (void) installMorePressed
{
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus != NotReachable)
    {
        OAMapSettingsViewController *mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenOnlineSources];
        [mapSettingsViewController show:vwController.parentViewController parentViewController:vwController animated:YES];
    }
    else
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"osm_upload_no_internet") preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
        [self.vwController presentViewController:alert animated:YES completion:nil];
    }
}

- (void) addPressed
{
    OAOnlineTilesEditingViewController *editTileSourceController = [[OAOnlineTilesEditingViewController alloc] initWithEmptyItem];
    editTileSourceController.delegate = self;
    [OARootViewController.instance.mapPanel.navigationController pushViewController:editTileSourceController animated:YES];
}

- (void) importPressed
{
    [[OAMapCreatorHelper sharedInstance] fetchSQLiteDBFiles:YES];
}

- (void) sliderValueChanged:(id)sender
{
    UISlider *slider = sender;
    if (_mapSettingType == EMapSettingOverlay)
        _app.data.overlayAlpha = slider.value;
    else if (_mapSettingType == EMapSettingUnderlay)
        _app.data.underlayAlpha = slider.value;
}

- (void) turnLayerOnOff:(id)sender
{
    UISwitch *switchView = (UISwitch *)sender;
    if (switchView)
    {
        _isEnabled = switchView.isOn;
        if (switchView.isOn)
        {
            if (_mapSettingType == EMapSettingOverlay)
            {
                _app.data.overlayMapSource = _app.data.lastOverlayMapSource;
            }
            else if (_mapSettingType == EMapSettingUnderlay)
            {
                [self hidePolygons:YES];
                _app.data.underlayMapSource = _app.data.lastUnderlayMapSource;
            }
            [tblView beginUpdates];
            [tblView insertSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, _data.count - 1)] withRowAnimation:UITableViewRowAnimationFade];
            [tblView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            [tblView endUpdates];
        }
        else
        {
            if (_mapSettingType == EMapSettingOverlay)
            {
                _app.data.overlayMapSource = nil;
            }
            else if (_mapSettingType == EMapSettingUnderlay)
            {
                [self hidePolygons:NO];
                _app.data.underlayMapSource = nil;
            }
            [tblView beginUpdates];
            [tblView deleteSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, _data.count - 1)] withRowAnimation:UITableViewRowAnimationFade];
            [tblView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            [tblView endUpdates];
        }
    }
}

- (void) onPolygonsChanged:(id)sender
{
     UISwitch *switchView = (UISwitch*)sender;
     if (switchView)
         [self hidePolygons:switchView.isOn];
}

- (void) onShowSwitchChanged:(id)sender
{
    UISwitch *switchView = (UISwitch*)sender;
    if (switchView)
    {
        [self setOpacitySliderVisibility:switchView.isOn];
        [[OARootViewController instance].mapPanel updateOverlayUnderlayView];
    }
}

- (void) hidePolygons:(BOOL)hide
{
    NSString *newValue = hide ? @"true" : @"false";
    if (![_hidePolygonsParameter.value isEqualToString:newValue])
    {
        _hidePolygonsParameter.value = hide ? @"true" : @"false";
        [_styleSettings save:_hidePolygonsParameter];
    }
}

- (void) switchLayer:(NSInteger)number
{
    Item* item = [_onlineMapSources objectAtIndex:number];
    if (_mapSettingType == EMapSettingOverlay)
    {
        _app.data.overlayMapSource = item.mapSource;
        _app.data.lastOverlayMapSource = item.mapSource;
    }
    else if (_mapSettingType == EMapSettingUnderlay)
    {
        [self hidePolygons:YES];
        _app.data.underlayMapSource = item.mapSource;
        _app.data.lastUnderlayMapSource = item.mapSource;
    }
    [tblView reloadData];
}

- (BOOL) isOpacitySliderVisible
{
    if (_mapSettingType == EMapSettingOverlay)
    {
        return [_settings mapSettingShowOverlayOpacitySlider];
    }
    else if (_mapSettingType == EMapSettingUnderlay)
    {
        return [_settings mapSettingShowUnderlayOpacitySlider];
    }
}

- (void) setOpacitySliderVisibility: (BOOL)show
{
    if (_mapSettingType == EMapSettingOverlay)
    {
        _settings.mapSettingShowOverlayOpacitySlider = show;
    }
    else if (_mapSettingType == EMapSettingUnderlay)
    {
        _settings.mapSettingShowUnderlayOpacitySlider = show;
    }
}


#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForHeaderInSection:(NSInteger)section
{
    return 34.0;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return 0.0;
    else if (section == kAvailableLayersSection)
        return 56.0;
    else
        return 36.0;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kAvailableLayersSection)
    {
        [self switchLayer:indexPath.row];
    }
}

#pragma mark - OAIconTextDescButtonCellDelegate

- (void) onButtonPressed:(NSInteger)tag
{
    [self switchLayer:tag];
}

#pragma mark - OATilesEditingViewControllerDelegate

- (void) onTileSourceSaved:(LocalResourceItem *)item
{
    [self setupView];
    [tblView reloadData];
}


@end
