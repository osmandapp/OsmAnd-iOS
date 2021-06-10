//
//  OAMoreOptionsBottomSheetViewController.m
//  OsmAnd
//
//  Created by Paul on 04/10/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAMoreOptionsBottomSheetViewController.h"
#import "Localization.h"
#import "OATargetPoint.h"
#import "OATargetPointsHelper.h"
#import "OAMenuSimpleCell.h"
#import "OADividerCell.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "OAIAPHelper.h"
#import "OAMapPanelViewController.h"
#import "OARootViewController.h"
#import "OAMapRendererView.h"
#import "OASQLiteTileSource.h"
#import "OAOsmEditingPlugin.h"
#import "OAPlugin.h"
#import "OAEntity.h"
#import "OAOpenStreetMapLocalUtil.h"
#import "OAOsmBugsLocalUtil.h"
#import "OAOsmNotePoint.h"
#import "OAOpenStreetMapPoint.h"
#import "OAOsmEditingViewController.h"
#import "OAOsmNoteBottomSheetViewController.h"
#import "OAPOI.h"
#import "OAMapLayers.h"
#import "OAContextMenuLayer.h"
#import "OADownloadMapViewController.h"
#import "OAResourcesUIHelper.h"
#import "OAMenuSimpleCell.h"
#import "OASelectedGPXHelper.h"
#import "OAGpxWptItem.h"
#import "OASavingTrackHelper.h"

#include <OsmAndCore/Utilities.h>

@implementation OAMoreOptionsBottomSheetScreen
{
    OsmAndAppInstance _app;
    OATargetPointsHelper *_targetPointsHelper;
    OAMoreOprionsBottomSheetViewController *vwController;
    OATargetPoint *_targetPoint;
    OAIAPHelper *_iapHelper;
    OAOsmEditingPlugin *_editingAddon;
    NSArray* _data;
}

@synthesize tableData, tblView;

- (id) initWithTable:(UITableView *)tableView viewController:(OAMoreOprionsBottomSheetViewController *)viewController
{
    self = [super init];
    if (self)
    {
        [self initOnConstruct:tableView viewController:viewController];
    }
    return self;
}

- (id) initWithTable:(UITableView *)tableView viewController:(OAMoreOprionsBottomSheetViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        _targetPoint = param;
        [self initOnConstruct:tableView viewController:viewController];
    }
    return self;
}

- (void) initOnConstruct:(UITableView *)tableView viewController:(OAMoreOprionsBottomSheetViewController *)viewController
{
    _app = [OsmAndApp instance];
    _targetPointsHelper = [OATargetPointsHelper sharedInstance];
    _iapHelper = [OAIAPHelper sharedInstance];
    
    vwController = viewController;
    tblView = tableView;
    tblView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self initData];
}

- (void) setupView
{
    [vwController.cancelButton setTitle:OALocalizedString(@"shared_string_close") forState:UIControlStateNormal];
    NSMutableArray *arr = [NSMutableArray array];
    // Directions from here
    [arr addObject:@{ @"title" : OALocalizedString(@"directions_more_options"),
                      @"key" : @"directions_more_options",
                      @"img" : @"ic_action_directions_from",
                      @"type" : [OAMenuSimpleCell getCellIdentifier] } ];
    // Search nearby
    [arr addObject:@{ @"title" : OALocalizedString(@"nearby_search"),
                      @"key" : @"nearby_search",
                      @"img" : @"ic_custom_search",
                      @"type" : [OAMenuSimpleCell getCellIdentifier] } ];
    // Download/Update online map
    if ([_app.data.lastMapSource.resourceId isEqualToString:@"online_tiles"] || [_app.data.lastMapSource.type isEqualToString:@"sqlitedb"])
    {
        [arr addObject:@{ @"title" : OALocalizedString(@"download_map"),
                          @"key" : @"download_map",
                          @"img" : @"ic_custom_download",
                          @"type" : [OAMenuSimpleCell getCellIdentifier] } ];

        [arr addObject:@{ @"title" : OALocalizedString(@"update_map"),
                          @"key" : @"update_map",
                          @"img" : @"ic_custom_update",
                          @"type" : [OAMenuSimpleCell getCellIdentifier] } ];
    }
    // Change marker position
    if ([OARootViewController.instance.mapPanel.mapViewController.mapLayers.contextMenuLayer isObjectMovable:_targetPoint.targetObj])
    {
        [arr addObject:@{ @"title" : OALocalizedString(@"change_object_posiotion"),
                          @"key" : @"change_object_posiotion",
                          @"img" : @"ic_custom_change_object_position",
                          @"type" : [OAMenuSimpleCell getCellIdentifier] } ];
    }
    // Plugins
    NSInteger addonsCount = _iapHelper.functionalAddons.count;
    if (addonsCount > 0)
    {
        for (OAFunctionalAddon *addon in _iapHelper.functionalAddons)
        {
            if ([addon.addonId isEqualToString:kId_Addon_TrackRecording_Edit_Waypoint]
                && (_targetPoint.type == OATargetWpt) && [_targetPoint.targetObj isKindOfClass:[OAGpxWptItem class]] && ([[OASelectedGPXHelper instance] getSelectedGpx:((OAGpxWptItem *)_targetPoint.targetObj).point] != nil || [[OASavingTrackHelper sharedInstance] hasData] || [[OAAppSettings sharedManager] mapSettingTrackRecording])) {
                [arr addObject:@{ @"title" : addon.titleShort,
                                  @"key" : @"addon_edit_waypoint",
                                  @"img" : addon.imageName,
                                  @"type" : [OAMenuSimpleCell getCellIdentifier] } ];
            }
            else if ([addon.addonId isEqualToString:kId_Addon_TrackRecording_Add_Waypoint]
                && (_targetPoint.type != OATargetWpt && _targetPoint.type != OATargetGPX && _targetPoint.type != OATargetGPXEdit)
                && _iapHelper.trackRecording.isActive) {
                [arr addObject:@{ @"title" : addon.titleShort,
                                  @"key" : @"addon_add_waypoint",
                                  @"img" : addon.imageName,
                                  @"type" : [OAMenuSimpleCell getCellIdentifier] } ];
            }
            else if ([addon.addonId isEqualToString:kId_Addon_Parking_Set]
                     && _targetPoint.type != OATargetParking
                     && _iapHelper.parking.isActive)
            {
                [arr addObject:@{ @"title" : addon.titleShort,
                                  @"key" : @"addon_add_parking",
                                  @"img" : addon.imageName,
                                  @"type" : [OAMenuSimpleCell getCellIdentifier] } ];
            }
            else if ([addon.addonId isEqualToString:kId_Addon_OsmEditing_Edit_POI])
            {
                _editingAddon = (OAOsmEditingPlugin *) [OAPlugin getPlugin:OAOsmEditingPlugin.class];
                if (_editingAddon.isActive)
                {
                    BOOL createNewPoi = (_targetPoint.obfId == 0 && _targetPoint.type != OATargetTransportStop && _targetPoint.type != OATargetOsmEdit) || _targetPoint.type == OATargetOsmNote;
                    [arr addObject:@{ @"title" : createNewPoi ? OALocalizedString(@"create_poi_short") : _targetPoint.type == OATargetOsmEdit ?
                                      OALocalizedString(@"modify_edit_short") : OALocalizedString(@"modify_poi_short"),
                                      @"key" : @"addon_edit_poi_modify",
                                      @"img" : createNewPoi ? @"ic_action_create_poi" : @"ic_custom_edit",
                                      @"type" : [OAMenuSimpleCell getCellIdentifier] }];
                    
                    BOOL editOsmNote = _targetPoint.type == OATargetOsmNote;
                    [arr addObject:@{ @"title" : editOsmNote ? OALocalizedString(@"edit_osm_note") : OALocalizedString(@"open_osm_note"),
                                      @"key" : @"addon_edit_poi_create_note",
                                      @"img" : editOsmNote ? @"ic_custom_edit" : @"ic_action_add_osm_note",
                                      @"type" : [OAMenuSimpleCell getCellIdentifier]}];
                }
                
            }
        }
    }
    // Plan route
    [arr addObject:@{ @"title" : OALocalizedString(@"plan_route"),
            @"key" : @"plan_route",
            @"img" : @"ic_action_ruler_line", //ic_custom_plan_route
            @"type" : [OAMenuSimpleCell getCellIdentifier] } ];
    // Avoid road
    [arr addObject:@{ @"title" : OALocalizedString(@"avoid_road"),
            @"key" : @"avoid_road",
            @"img" : @"ic_custom_alert", //ic_custom_road_works
            @"type" : [OAMenuSimpleCell getCellIdentifier] } ];
    if (arr.count > 2)
        [arr insertObject:@{ @"type" : [OADividerCell getCellIdentifier] } atIndex:2];
    _data = [NSArray arrayWithArray:arr];
}

- (void) initData
{
}

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    NSDictionary *item = _data[indexPath.row];
    if ([item[@"type"] isEqualToString:[OAMenuSimpleCell getCellIdentifier]])
    {
        return UITableViewAutomaticDimension;
    }
    else if ([item[@"type"] isEqualToString:[OADividerCell getCellIdentifier]])
    {
        return [OADividerCell cellHeight:0.5 dividerInsets:UIEdgeInsetsMake(6.0, 70.0, 4.0, 0.0)];
    }
    else
    {
        return 44.0;
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    
    if ([item[@"type"] isEqualToString:[OAMenuSimpleCell getCellIdentifier]])
    {
        OAMenuSimpleCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:[OAMenuSimpleCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMenuSimpleCell getCellIdentifier] owner:self options:nil];
            cell = (OAMenuSimpleCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            [cell.descriptionView setEnabled:NO];
        }
        
        if (cell)
        {
            UIImage *img = nil;
            NSString *imgName = item[@"img"];
            if (imgName)
                img = [UIImage templateImageNamed:imgName];
            
            cell.textView.text = item[@"title"];
            NSString *desc = item[@"description"];
            cell.descriptionView.text = desc;
            cell.descriptionView.hidden = desc.length == 0;
            [cell.imgView setTintColor:UIColorFromRGB(color_icon_color)];
            cell.imgView.image = img;
            if ([cell needsUpdateConstraints])
                [cell setNeedsUpdateConstraints];
        }
        
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OADividerCell getCellIdentifier]])
    {
        OADividerCell* cell = [tableView dequeueReusableCellWithIdentifier:[OADividerCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADividerCell getCellIdentifier] owner:self options:nil];
            cell = (OADividerCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.dividerColor = UIColorFromRGB(color_divider_blur);
            CGFloat leftInset = [cell isDirectionRTL] ? 0 : 70.0;
            CGFloat rightInset = [cell isDirectionRTL] ? 70.0 : 0;
            cell.dividerInsets = UIEdgeInsetsMake(6.0, leftInset, 4.0, rightInset);
            cell.dividerHight = 0.5;
        }
        return cell;
    }
    else
    {
        return nil;
    }
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath tableView:tableView];
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.001;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.001;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    if ([item[@"type"] isEqualToString:[OAMenuSimpleCell getCellIdentifier]])
        return indexPath;
    else
        return nil;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    NSString *key = item[@"key"];
    if (_targetPoint)
    {
        CLLocation *menuLocation = [[CLLocation alloc] initWithLatitude:_targetPoint.location.latitude longitude:_targetPoint.location.longitude];
        OAPointDescription *menuName = _targetPoint.pointDescription;
        OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;

        if ([key isEqualToString:@"directions_more_options"])
        {
            [_targetPointsHelper setStartPoint:menuLocation updateRoute:YES name:menuName];
            
            [vwController.menuViewDelegate targetHide];
            [vwController.menuViewDelegate navigateFrom:_targetPoint];
        }

        else if ([key isEqualToString:@"addon_edit_waypoint"])
            [vwController.menuViewDelegate targetPointEditWaypoint:_targetPoint.targetObj];
        else if ([key isEqualToString:@"addon_add_waypoint"])
            [vwController.menuViewDelegate targetPointAddWaypoint];
        
        else if ([key isEqualToString:@"addon_add_parking"])
            [vwController.menuViewDelegate targetPointParking];
        else if ([key isEqualToString:@"nearby_search"]) {
            [vwController.menuViewDelegate targetHide];
            [mapPanel openSearch:OAQuickSearchType::REGULAR location:menuLocation tabIndex:1];
        }
        else if ([key isEqualToString:@"change_object_posiotion"])
        {
            [mapPanel openTargetViewWithMovableTarget:_targetPoint];
        }
        else if ([key isEqualToString:@"addon_edit_poi_modify"] && _editingAddon)
        {
            [mapPanel targetHide];
            if ([item[@"title"] isEqualToString:OALocalizedString(@"create_poi_short")])
            {
                OAOsmEditingViewController *editingScreen = [[OAOsmEditingViewController alloc] initWithLat:_targetPoint.location.latitude lon:_targetPoint.location.longitude];
                [mapPanel.navigationController pushViewController:editingScreen animated:YES];
            }
            else if ([item[@"title"] isEqualToString:OALocalizedString(@"modify_poi_short")])
            {
                OAMapViewController *mapVC = [OARootViewController instance].mapPanel.mapViewController;
                [mapVC showProgressHUDWithMessage:OALocalizedString(@"osm_editing_loading_poi")];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    
                    OAEntity *entity = [[_editingAddon getPoiModificationUtil] loadEntity:_targetPoint];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [mapVC hideProgressHUD];
                        OAOsmEditingViewController *editingScreen = [[OAOsmEditingViewController alloc]
                                                                     initWithEntity:entity];
                        [mapPanel.navigationController pushViewController:editingScreen animated:YES];
                    });
                });
                
            }
            else if (_targetPoint.type == OATargetOsmEdit)
            {
                OAOsmEditingViewController *editingScreen = [[OAOsmEditingViewController alloc] initWithEntity:((OAOpenStreetMapPoint *)_targetPoint.targetObj).getEntity];
                [mapPanel.navigationController pushViewController:editingScreen animated:YES];
            }
        }
        else if ([key isEqualToString:@"addon_edit_poi_create_note"] && _editingAddon)
        {
            [mapPanel targetHide];
            BOOL shouldEdit = _targetPoint.type == OATargetOsmNote;
            OAOsmNotePoint *point = shouldEdit ? _targetPoint.targetObj : [self constructFromTargetPoint:_targetPoint];
            OAOsmNoteBottomSheetViewController *noteScreen = [[OAOsmNoteBottomSheetViewController alloc] initWithEditingPlugin:_editingAddon points:[NSArray arrayWithObject:point] type:TYPE_CREATE];
            [noteScreen show];
        }
        else if ([key isEqualToString:@"download_map"])
        {
            [[OARootViewController instance].mapPanel openTargetViewWithDownloadMapSource:YES];
        }
        else if ([key isEqualToString:@"update_map"])
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"map_update_warning") preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:nil]];
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                OAMapViewController *mapVC = mapPanel.mapViewController;
                float zoom = mapVC.getMapZoom;
                const auto visibleArea = mapVC.mapView.getVisibleBBox31;
                NSDictionary<OAMapSource *, OAResourceItem *> *onlineSources = [OAResourcesUIHelper getOnlineRasterMapSourcesBySource];
                OAResourceItem *resource = onlineSources[_app.data.lastMapSource];
                if (!resource)
                    return;
                [OAResourcesUIHelper clearTilesOf:resource area:visibleArea zoom:zoom onComplete:^{
                    [_app.mapSettingsChangeObservable notifyEvent];
                }];
            }]];
            [OARootViewController.instance presentViewController:alert animated:YES completion:nil];
        }
        else if ([key isEqualToString:@"plan_route"])
            [vwController.menuViewDelegate targetOpenPlanRoute];
        else if ([key isEqualToString:@"avoid_road"]) {
            [vwController.menuViewDelegate targetOpenAvoidRoad];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [vwController dismiss];
}

- (OAOsmNotePoint *) constructFromTargetPoint:(OATargetPoint *)targetPoint
{
    OAOsmNotePoint *point = [[OAOsmNotePoint alloc] init];
    [point setLatitude:_targetPoint.location.latitude];
    [point setLongitude:_targetPoint.location.longitude];
    [point setAuthor:@""];
    [point setAction:CREATE];
    return point;
}

@synthesize vwController;

@end

@interface OAMoreOprionsBottomSheetViewController ()

@end

@implementation OAMoreOprionsBottomSheetViewController

- (instancetype) initWithTargetPoint:(OATargetPoint *)targetPoint targetType:(NSString *)targetType
{
    targetPoint.ctrlTypeStr = targetType;
    return [super initWithParam:targetPoint];
}

- (OATargetPoint *)targetPoint
{
    return self.customParam;
}

- (void) setupView
{
    if (!self.screenObj)
        self.screenObj = [[OAMoreOptionsBottomSheetScreen alloc] initWithTable:self.tableView viewController:self param:self.targetPoint];
    
    [super setupView];
}

@end
