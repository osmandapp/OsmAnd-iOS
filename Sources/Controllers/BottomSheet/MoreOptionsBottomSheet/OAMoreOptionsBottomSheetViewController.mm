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
#import "OADividerCell.h"
#import "OAUtilities.h"
#import "OAIAPHelper.h"
#import "OAProducts.h"
#import "OAMapPanelViewController.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAOsmEditingPlugin.h"
#import "OAPlugin.h"
#import "OAEntity.h"
#import "OAOpenStreetMapLocalUtil.h"
#import "OAOsmBugsLocalUtil.h"
#import "OAOsmNotePoint.h"
#import "OAOpenStreetMapPoint.h"
#import "OAOsmEditingViewController.h"
#import "OAOsmNoteViewController.h"
#import "OAPOI.h"
#import "OAMapLayers.h"
#import "OAContextMenuLayer.h"
#import "OADownloadMapViewController.h"
#import "OAResourcesUIHelper.h"
#import "OASimpleTableViewCell.h"
#import "OASelectedGPXHelper.h"
#import "OAGpxWptItem.h"
#import "OASavingTrackHelper.h"
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import "GeneratedAssetSymbols.h"
#import "OAPluginsHelper.h"
#import "OAMapSource.h"
#import "OsmAnd_Maps-Swift.h"

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
    [arr addObject:@{ @"title" : OALocalizedString(@"context_menu_item_directions_from"),
                      @"key" : @"directions_more_options",
                      @"img" : @"ic_action_directions_from",
                      @"type" : [OASimpleTableViewCell getCellIdentifier] } ];
    // Search nearby
    [arr addObject:@{ @"title" : OALocalizedString(@"search_nearby"),
                      @"key" : @"nearby_search",
                      @"img" : @"ic_custom_search",
                      @"type" : [OASimpleTableViewCell getCellIdentifier] } ];
    // Download/Update online map
    if ([_app.data.lastMapSource.resourceId isEqualToString:@"online_tiles"] || [_app.data.lastMapSource.type isEqualToString:@"sqlitedb"])
    {
        [arr addObject:@{ @"title" : OALocalizedString(@"shared_string_download_map"),
                          @"key" : @"download_map",
                          @"img" : @"ic_custom_download",
                          @"type" : [OASimpleTableViewCell getCellIdentifier] } ];

        [arr addObject:@{ @"title" : OALocalizedString(@"update_tile"),
                          @"key" : @"update_map",
                          @"img" : @"ic_custom_update",
                          @"type" : [OASimpleTableViewCell getCellIdentifier] } ];
    }
    // Change marker position
    if ([OARootViewController.instance.mapPanel.mapViewController.mapLayers.contextMenuLayer isObjectMovable:_targetPoint.targetObj])
    {
        [arr addObject:@{ @"title" : OALocalizedString(@"change_object_posiotion"),
                          @"key" : @"change_object_posiotion",
                          @"img" : @"ic_custom_change_object_position",
                          @"type" : [OASimpleTableViewCell getCellIdentifier] } ];
    }
    // Plugins
    NSInteger addonsCount = _iapHelper.functionalAddons.count;
    if (addonsCount > 0)
    {
        for (OAFunctionalAddon *addon in _iapHelper.functionalAddons)
        {
            if ([addon.addonId isEqualToString:kId_Addon_TrackRecording_Edit_Waypoint]
                && (_targetPoint.type == OATargetWpt) 
                && [_targetPoint.targetObj isKindOfClass:[OAGpxWptItem class]]
                && !((OAGpxWptItem *)_targetPoint.targetObj).routePoint)
            {
                [arr addObject:@{ @"title" : addon.titleShort,
                                  @"key" : @"addon_edit_waypoint",
                                  @"img" : addon.imageName,
                                  @"type" : [OASimpleTableViewCell getCellIdentifier] } ];
            }
            else if ([addon.addonId isEqualToString:kId_Addon_TrackRecording_Add_Waypoint]
                && (_targetPoint.type != OATargetWpt && _targetPoint.type != OATargetGPX)) {
                [arr addObject:@{ @"title" : addon.titleShort,
                                  @"key" : @"addon_add_waypoint",
                                  @"img" : addon.imageName,
                                  @"type" : [OASimpleTableViewCell getCellIdentifier] } ];
            }
            else if ([addon.addonId isEqualToString:kId_Addon_Parking_Set]
                     && _targetPoint.type != OATargetParking
                     && _iapHelper.parking.isActive)
            {
                [arr addObject:@{ @"title" : addon.titleShort,
                                  @"key" : @"addon_add_parking",
                                  @"img" : addon.imageName,
                                  @"type" : [OASimpleTableViewCell getCellIdentifier] } ];
            }
            else if ([addon.addonId isEqualToString:kId_Addon_OsmEditing_Edit_POI])
            {
                _editingAddon = (OAOsmEditingPlugin *) [OAPluginsHelper getPlugin:OAOsmEditingPlugin.class];
                if ([_editingAddon isEnabled])
                {
                    BOOL createNewPoi = (_targetPoint.obfId == 0 && _targetPoint.type != OATargetTransportStop && _targetPoint.type != OATargetOsmEdit) || _targetPoint.type == OATargetOsmNote;
                    [arr addObject:@{ @"title" : createNewPoi ? OALocalizedString(@"context_menu_item_create_poi") : _targetPoint.type == OATargetOsmEdit ?
                                      OALocalizedString(@"poi_context_menu_modify_osm_change") : OALocalizedString(@"poi_context_menu_modify"),
                                      @"key" : @"addon_edit_poi_modify",
                                      @"img" : createNewPoi ? @"ic_action_create_poi" : @"ic_custom_edit",
                                      @"type" : [OASimpleTableViewCell getCellIdentifier] }];
                    
                    BOOL editOsmNote = _targetPoint.type == OATargetOsmNote;
                    [arr addObject:@{ @"title" : editOsmNote ? OALocalizedString(@"edit_osm_note") : OALocalizedString(@"context_menu_item_open_note"),
                                      @"key" : @"addon_edit_poi_create_note",
                                      @"img" : editOsmNote ? @"ic_custom_edit" : @"ic_action_add_osm_note",
                                      @"type" : [OASimpleTableViewCell getCellIdentifier]}];
                }
                
            }
        }
    }
    // Plan route
    [arr addObject:@{ @"title" : OALocalizedString(@"plan_route"),
            @"key" : @"plan_route",
            @"img" : @"ic_custom_route",
            @"type" : [OASimpleTableViewCell getCellIdentifier] } ];
    // Avoid road
    [arr addObject:@{ @"title" : OALocalizedString(@"avoid_road"),
            @"key" : @"avoid_road",
            @"img" : @"ic_custom_road_works",
            @"type" : [OASimpleTableViewCell getCellIdentifier] } ];
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
    if ([item[@"type"] isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
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
    
    if ([item[@"type"] isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            UIImage *img = nil;
            NSString *imgName = item[@"img"];
            if (imgName)
                img = [UIImage templateImageNamed:imgName];
            
            cell.titleLabel.text = item[@"title"];
            NSString *desc = item[@"description"];
            cell.descriptionLabel.text = desc;
            [cell descriptionVisibility:desc.length != 0];
            [cell.leftIconView setTintColor:[UIColor colorNamed:ACColorNameIconColorDefault]];
            cell.leftIconView.image = img;
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
            cell.dividerColor = [UIColor colorNamed:ACColorNameCustomSeparator];
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
    if ([item[@"type"] isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
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
        {
            [vwController.menuViewDelegate targetPointEditWaypoint:_targetPoint.targetObj];
        }
        else if ([key isEqualToString:@"addon_add_waypoint"])
        {
            [vwController.menuViewDelegate targetPointAddWaypoint];
        }
        else if ([key isEqualToString:@"addon_add_parking"])
        {
            [vwController.menuViewDelegate targetPointParking];
        }
        else if ([key isEqualToString:@"nearby_search"])
        {
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
            if ([item[@"title"] isEqualToString:OALocalizedString(@"context_menu_item_create_poi")])
            {
                OAOsmEditingViewController *editingScreen = [[OAOsmEditingViewController alloc] initWithLat:_targetPoint.location.latitude lon:_targetPoint.location.longitude];
                [mapPanel.navigationController pushViewController:editingScreen animated:YES];
            }
            else if ([item[@"title"] isEqualToString:OALocalizedString(@"poi_context_menu_modify")])
            {
                OAMapViewController *mapVC = [OARootViewController instance].mapPanel.mapViewController;
                [mapVC showProgressHUDWithMessage:OALocalizedString(@"osm_editing_loading_poi")];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    id<OAOpenStreetMapUtilsProtocol> poiModificationUtil;
                    if (AFNetworkReachabilityManager.sharedManager.isReachable)
                        poiModificationUtil = [_editingAddon getPoiModificationRemoteUtil];
                    else
                        poiModificationUtil = [_editingAddon getPoiModificationLocalUtil];
                    OAEntity *entity = [poiModificationUtil loadEntity:_targetPoint];
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
            OAOsmNoteViewController *noteScreen = [[OAOsmNoteViewController alloc] initWithEditingPlugin:_editingAddon points:[NSArray arrayWithObject:point] type:EOAOsmNoteViewConrollerModeCreate];
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:noteScreen];
            [mapPanel.navigationController presentViewController:navigationController animated:YES completion:nil];
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
        {
            [vwController.menuViewDelegate targetOpenPlanRoute];
        }
        else if ([key isEqualToString:@"avoid_road"])
        {
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[ThemeManager shared] configureWithAppMode:[OAAppSettings sharedManager].applicationMode.get];
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
