//
//  OAOsmandDevelopmentViewController.m
//  OsmAnd Maps
//
//  Created by nnngrach on 01.06.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAOsmandDevelopmentViewController.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAColors.h"
#import "OALocationSimulation.h"
#import "OAValueTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OATableRowData.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OAOsmandDevelopmentSimulateLocationViewController.h"
#import "OAOsmandDevelopmentPlugin.h"
#import "OAPlugin.h"
#import "OAChoosePlanHelper.h"
#import "OAIAPHelper.h"
#import "OAProducts.h"
#import "OARootViewController.h"

#define kCellSwitchIsOnKey @"kCellSwitchIsOnKey"
#define kCellSwitchEnabledKey @"kCellSwitchEnabledKey"
#define kCellSwitchUserInteractionEnabledKey @"kCellSwitchUserInteractionEnabledKey"

#define kGeotiffCacheDir @"GEOTIFF_SQLITE_CACHE_DIR"


@interface OAOsmandDevelopmentViewController () <OAOsmandDevelopmentSimulateLocationDelegate>

@end

@implementation OAOsmandDevelopmentViewController
{
    OsmAndAppInstance _app;
    OATableDataModel* _data;
    NSString *_headerDescription;
    OAOsmandDevelopmentPlugin *_plugin;
}

NSString *const kSimulateLocationKey = @"kSimulateLocationKey";
NSString *const kTestHeightmapKey = @"kTestHeightmapKey";
NSString *const kUse3dReliefHeightmapsKey = @"kUse3dReliefHeightmapsKey";
NSString *const kDisableVertexHillshade = @"kDisableVertexHillshade";
NSString *const kGenerateHillshadeKey = @"kGenerateHillshadeKey";
NSString *const kGenerateSlopeKey = @"kGenerateSlopeKey";

- (void) viewDidLoad
{
    [super viewDidLoad];
    [self applySafeAreaMargins];
    _plugin = (OAOsmandDevelopmentPlugin *) [OAPlugin getPlugin:OAOsmandDevelopmentPlugin.class];
    _app = [OsmAndApp instance];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.estimatedRowHeight = kEstimatedRowHeight;
    self.tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:_headerDescription font:kHeaderDescriptionFont textColor:UIColorFromRGB(color_text_footer) isBigTitle:NO parentViewWidth:self.view.frame.size.width];
    
    [self.backButton setImage:[UIImage rtlImageNamed:@"ic_navbar_chevron"] forState:UIControlStateNormal];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:OAIAPProductPurchasedNotification object:nil];
}

- (void) viewWillAppear:(BOOL)animated
{
    [self applySafeAreaMargins];
    [self reloadData];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:_headerDescription font:kHeaderDescriptionFont textColor:UIColorFromRGB(color_text_footer) isBigTitle:NO parentViewWidth:self.view.frame.size.width];
    } completion:nil];
}

-(UIView *) getTopView
{
    return _navBarView;
}


#pragma mark - Setup data

- (void) applyLocalization
{
    _titleView.text = OALocalizedString(@"debugging_and_development");
    _headerDescription = OALocalizedString(@"osm_editing_settings_descr");
}

- (void) generateData
{
    BOOL isRouteAnimating = [[OsmAndApp instance].locationServices.locationSimulation isRouteAnimating];
    _data = [OATableDataModel model];
    __weak OAOsmandDevelopmentViewController *weakSelf = self;
    OATableSectionData *simulationSection = [OATableSectionData sectionData];
    simulationSection.headerText = OALocalizedString(@"osmand_depelopment_simulate_location_section");
    [simulationSection addRowFromDictionary:@{
        kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
        kCellKeyKey : kSimulateLocationKey,
        kCellTitleKey : OALocalizedString(@"simulate_your_location"),
        kCellDescrKey : isRouteAnimating ? OALocalizedString(@"simulate_in_progress") : @"",
        @"actionBlock" : (^void(){ [weakSelf openSimulateLocationSettings]; })
    }];
    [_data addSection:simulationSection];
    
    OATableSectionData *heightMapSection = [OATableSectionData sectionData];
    heightMapSection.headerText = OALocalizedString(@"download_heightmap_maps");
    BOOL isPluginSwitchesEnabled = [OAIAPHelper isOsmAndProAvailable] && [_plugin.enableHeightmap get];
    
    [heightMapSection addRowFromDictionary:@{
        kCellTypeKey : OASwitchTableViewCell.getCellIdentifier,
        kCellKeyKey : kTestHeightmapKey,
        kCellTitleKey : OALocalizedString(@"test_heightmap"),
        kCellSwitchIsOnKey : [NSNumber numberWithBool:isPluginSwitchesEnabled ? [_plugin.enableHeightmap get] : NO],
        kCellSwitchEnabledKey : [NSNumber numberWithBool:[OAIAPHelper isOsmAndProAvailable]],
        kCellSwitchUserInteractionEnabledKey : [NSNumber numberWithBool:YES],
        @"actionBlock" : (^void(){ [weakSelf openProPlanScreen]; })
    }];
    [heightMapSection addRowFromDictionary:@{
        kCellTypeKey : OASwitchTableViewCell.getCellIdentifier,
        kCellKeyKey : kUse3dReliefHeightmapsKey,
        kCellTitleKey : OALocalizedString(@"use_heightmap_setting"),
        kCellSwitchIsOnKey : [NSNumber numberWithBool:[_plugin.enable3DMaps get]],
        kCellSwitchEnabledKey : [NSNumber numberWithBool:YES],
        kCellSwitchUserInteractionEnabledKey : [NSNumber numberWithBool:isPluginSwitchesEnabled]
    }];
    [heightMapSection addRowFromDictionary:@{
        kCellTypeKey : OASwitchTableViewCell.getCellIdentifier,
        kCellKeyKey : kDisableVertexHillshade,
        kCellTitleKey : OALocalizedString(@"disable_vertex_hillshade_3d"),
        kCellSwitchIsOnKey : [NSNumber numberWithBool:[_plugin.disableVertexHillshade3D get]],
        kCellSwitchEnabledKey : [NSNumber numberWithBool:YES],
        kCellSwitchUserInteractionEnabledKey : [NSNumber numberWithBool:isPluginSwitchesEnabled]
    }];
    [heightMapSection addRowFromDictionary:@{
        kCellTypeKey : OASwitchTableViewCell.getCellIdentifier,
        kCellKeyKey : kGenerateSlopeKey,
        kCellTitleKey : OALocalizedString(@"generate_slope_from_3d_maps"),
        kCellSwitchIsOnKey : [NSNumber numberWithBool:[_plugin.generateSlopeFrom3DMaps get]],
        kCellSwitchEnabledKey : [NSNumber numberWithBool:YES],
        kCellSwitchUserInteractionEnabledKey : [NSNumber numberWithBool:isPluginSwitchesEnabled]
    }];
    [heightMapSection addRowFromDictionary:@{
        kCellTypeKey : OASwitchTableViewCell.getCellIdentifier,
        kCellKeyKey : kGenerateHillshadeKey,
        kCellTitleKey : OALocalizedString(@"generate_hillshade_from_3d_maps"),
        kCellSwitchIsOnKey : [NSNumber numberWithBool:[_plugin.generateHillshadeFrom3DMaps get]],
        kCellSwitchEnabledKey : [NSNumber numberWithBool:YES],
        kCellSwitchUserInteractionEnabledKey : [NSNumber numberWithBool:isPluginSwitchesEnabled]
    }];
    [_data addSection:heightMapSection];
}

- (void) reloadData
{
    [self generateData];
    [self.tableView reloadData];
}

- (void) applyParameter:(UISwitch *)sender
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag & 0x3FF inSection:sender.tag >> 10];
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    
    if ([item.key isEqualToString:kTestHeightmapKey])
    {
        [self createGeotiffCacheFolderIfNeeded];
        [_plugin.enableHeightmap set:sender.isOn];
        [self onEnable3DMapsChanged:sender.isOn];
        [self onDisableVertexHillshade3DChanged:sender.isOn];
        [self onGenerateSlopeFrom3DMapsChanged:sender.isOn];
        [self onGenerateHillshadeFrom3DMapsChanged:sender.isOn];
        [self generateData];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    else if ([item.key isEqualToString:kUse3dReliefHeightmapsKey])
    {
        [_plugin.enable3DMaps set:sender.isOn];
        [self onEnable3DMapsChanged:sender.isOn];
    }
    else if ([item.key isEqualToString:kDisableVertexHillshade])
    {
        [_plugin.disableVertexHillshade3D set:sender.isOn];
        [self onDisableVertexHillshade3DChanged:sender.isOn];
    }
    else if ([item.key isEqualToString:kGenerateSlopeKey])
    {
        [_plugin.generateSlopeFrom3DMaps set:sender.isOn];
        [self onGenerateSlopeFrom3DMapsChanged:sender.isOn];
    }
    else if ([item.key isEqualToString:kGenerateHillshadeKey])
    {
        [_plugin.generateHillshadeFrom3DMaps set:sender.isOn];
        [self onGenerateHillshadeFrom3DMapsChanged:sender.isOn];
    }
}

- (void) createGeotiffCacheFolderIfNeeded
{
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSString *path = [OsmAndApp.instance.documentsPath stringByAppendingPathComponent:kGeotiffCacheDir];
    if (![fileManager fileExistsAtPath:path])
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
}

- (void) onEnable3DMapsChanged:(BOOL)isOn
{
    [OARootViewController.instance.mapPanel.mapViewController recreateHeightmapProvider];
}

- (void) onDisableVertexHillshade3DChanged:(BOOL)isOn
{
    [OARootViewController.instance.mapPanel.mapViewController updateElevationConfiguration];
}

- (void) onGenerateSlopeFrom3DMapsChanged:(BOOL)isOn
{
    [_app.data setTerrainType:_app.data.terrainType];
}

- (void) onGenerateHillshadeFrom3DMapsChanged:(BOOL)isOn
{
    [_app.data setTerrainType:_app.data.terrainType];
}

#pragma mark - Actions

- (void) openSimulateLocationSettings
{
    OAOsmandDevelopmentSimulateLocationViewController *vc = [[OAOsmandDevelopmentSimulateLocationViewController alloc] init];
    vc.simulateLocationDelegate = self;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void) openProPlanScreen
{
    if (![OAIAPHelper isOsmAndProAvailable])
        [OAChoosePlanHelper showChoosePlanScreenWithProduct:[OAIAPHelper sharedInstance].proMonthly navController:self.navigationController];
}

- (void) productPurchased:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self generateData];
        [self.tableView reloadData];
    });
}


#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.sectionCount;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_data rowCount:section];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    NSString *type = item.cellType;
    
    if ([type isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *)[nib objectAtIndex:0];
            [cell descriptionVisibility:NO];
            [cell leftIconVisibility:NO];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
            cell.valueLabel.text = item.descr;
        }
        return cell;
    }
    else if ([type isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            cell.switchView.tintColor = UIColorFromRGB(color_bottom_sheet_secondary);
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.userInteractionEnabled = [item boolForKey:kCellSwitchUserInteractionEnabledKey];
            cell.switchView.userInteractionEnabled = [item boolForKey:kCellSwitchEnabledKey];
            
            cell.titleLabel.textColor = [item boolForKey:kCellSwitchUserInteractionEnabledKey] ? UIColor.blackColor : UIColorFromRGB(color_bottom_sheet_secondary);
            cell.titleLabel.text = item.title;
            cell.switchView.onTintColor = [item boolForKey:kCellSwitchUserInteractionEnabledKey] ? UIColorFromRGB(color_uiswitch_on_day) : UIColorFromRGB(color_footer_icon_gray);
            cell.switchView.on = [item boolForKey:kCellSwitchIsOnKey];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    return nil;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [_data sectionDataForIndex:section].headerText;
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return [_data sectionDataForIndex:section].footerText;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *)view;
    [footer.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    void (^actionBlock)() = [item objForKey:@"actionBlock"];
    if (actionBlock)
        actionBlock();
}


#pragma mark - OAOsmandDevelopmentSimulateLocationDelegate

- (void) onSimulateLocationInformationUpdated
{
    [self reloadData];
}

@end
