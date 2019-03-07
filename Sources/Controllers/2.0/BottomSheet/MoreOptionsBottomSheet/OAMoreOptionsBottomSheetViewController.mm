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
#import "OAWaypointHeaderCell.h"
#import "OADividerCell.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "OAIAPHelper.h"
#import "OAMapPanelViewController.h"
#import "OARootViewController.h"
#import "OAOsmEditingPlugin.h"
#import "OAPlugin.h"
#import "OAEntity.h"
#import "OAOpenStreetMapLocalUtil.h"
#import "OAOsmBugsLocalUtil.h"
#import "OAOsmNotePoint.h"
#import "OAOsmEditingViewController.h"
#import "OAPOI.h"

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
                      @"type" : @"OAMenuSimpleCell" } ];
    // Search nearby
    [arr addObject:@{ @"title" : OALocalizedString(@"nearby_search"),
                      @"key" : @"nearby_search",
                      @"img" : @"ic_custom_search",
                      @"type" : @"OAMenuSimpleCell" } ];
    // Plugins
    NSInteger addonsCount = _iapHelper.functionalAddons.count;
    if (addonsCount > 0)
    {
        [arr addObject:@{ @"type" : @"OADividerCell" } ];
        for (OAFunctionalAddon *addon in _iapHelper.functionalAddons)
        {
            if (_targetPoint.type == OATargetParking && [addon.addonId isEqualToString:kId_Addon_Parking_Set])
                continue;
            if (_targetPoint.type == OATargetWpt && [addon.addonId isEqualToString:kId_Addon_TrackRecording_Add_Waypoint])
                continue;
            
            if ((_targetPoint.type == OATargetGPX || _targetPoint.type == OATargetGPXEdit) &&
                [addon.addonId isEqualToString:kId_Addon_TrackRecording_Add_Waypoint])
                continue;
            
            if ([addon.addonId isEqualToString:kId_Addon_TrackRecording_Add_Waypoint]) {
                [arr addObject:@{ @"title" : addon.titleShort,
                                  @"key" : @"addon_add_waypoint",
                                  @"img" : addon.imageName,
                                  @"type" : @"OAMenuSimpleCell" } ];
            }
            else if ([addon.addonId isEqualToString:kId_Addon_Parking_Set])
            {
                [arr addObject:@{ @"title" : addon.titleShort,
                                  @"key" : @"addon_add_parking",
                                  @"img" : addon.imageName,
                                  @"type" : @"OAMenuSimpleCell" } ];
            }
            else if ([addon.addonId isEqualToString:kId_Addon_OsmEditing_Edit_POI])
            {
                _editingAddon = (OAOsmEditingPlugin *) [OAPlugin getPlugin:OAOsmEditingPlugin.class];
                
                BOOL createNewPoi = _targetPoint.obfId == 0 && _targetPoint.type != OATargetTransportStop;
                [arr addObject:@{ @"title" : createNewPoi ? OALocalizedString(@"create_poi_short") : OALocalizedString(@"modify_poi_short"),
                                  @"key" : @"addon_edit_poi_modify",
                                  @"img" : createNewPoi ? @"ic_action_create_poi" : @"ic_custom_edit",
                                  @"type" : @"OAMenuSimpleCell" }];

                BOOL editOsmNote = _targetPoint.type == OATargetOsmNote;
                [arr addObject:@{ @"title" : editOsmNote ? OALocalizedString(@"edit_osm_note") : OALocalizedString(@"open_osm_note"),
                                  @"key" : @"addon_edit_poi_create_note",
                                  @"img" : editOsmNote ? @"ic_custom_edit" : @"ic_action_add_osm_note",
                                  @"type" : @"OAMenuSimpleCell" }];
            }
        }
    }
    _data = [NSArray arrayWithArray:arr];
}

- (void) initData
{
}

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    NSDictionary *item = _data[indexPath.row];
    if ([item[@"type"] isEqualToString:@"OAMenuSimpleCell"])
    {
        return [OAMenuSimpleCell getHeight:item[@"title"] desc:item[@"description"] cellWidth:tableView.bounds.size.width];
    }
    else if ([item[@"type"] isEqualToString:@"OADividerCell"])
    {
        return [OADividerCell cellHeight:0.5 dividerInsets:UIEdgeInsetsMake(6.0, 44.0, 4.0, 0.0)];
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
    
    if ([item[@"type"] isEqualToString:@"OAMenuSimpleCell"])
    {
        static NSString* const identifierCell = @"OAMenuSimpleCell";
        OAMenuSimpleCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAMenuSimpleCell" owner:self options:nil];
            cell = (OAMenuSimpleCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            [cell.descriptionView setEnabled:NO];
        }
        
        if (cell)
        {
            UIImage *img = nil;
            NSString *imgName = item[@"img"];
            if (imgName)
                img = [[UIImage imageNamed:imgName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            
            cell.textView.text = item[@"title"];
            NSString *desc = item[@"description"];
            cell.descriptionView.text = desc;
            cell.descriptionView.hidden = desc.length == 0;
            [cell.imgView setTintColor:UIColorFromRGB(color_icon_color)];
            cell.imgView.image = img;
        }
        
        return cell;
    }
    else if ([item[@"type"] isEqualToString:@"OADividerCell"])
    {
        static NSString* const identifierCell = @"OADividerCell";
        OADividerCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OADividerCell" owner:self options:nil];
            cell = (OADividerCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.dividerColor = UIColorFromRGB(color_divider_blur);
            cell.dividerInsets = UIEdgeInsetsMake(6.0, 44.0, 4.0, 0.0);
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
    return 1;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    if ([item[@"type"] isEqualToString:@"OAMenuSimpleCell"])
        return indexPath;
    else
        return nil;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    NSString *key = item[@"key"];
    BOOL dismissBottomSheet = YES;
    if (_targetPoint)
    {
        CLLocation *menuLocation = [[CLLocation alloc] initWithLatitude:_targetPoint.location.latitude longitude:_targetPoint.location.longitude];
        OAPointDescription *menuName = _targetPoint.pointDescription;

        if ([key isEqualToString:@"directions_more_options"])
        {
            [_targetPointsHelper setStartPoint:menuLocation updateRoute:YES name:menuName];
            
            [vwController.menuViewDelegate targetHide];
            [vwController.menuViewDelegate navigateFrom:_targetPoint];
        }
        else if ([key isEqualToString:@"addon_add_waypoint"])
            [vwController.menuViewDelegate targetPointAddWaypoint];
        
        else if ([key isEqualToString:@"addon_add_parking"])
            [vwController.menuViewDelegate targetPointParking];
        else if ([key isEqualToString:@"nearby_search"]) {
            [vwController.menuViewDelegate targetHide];
            OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
            [mapPanel openSearch:OAQuickSearchType::REGULAR location:menuLocation tabIndex:1];
        }
        else if ([key isEqualToString:@"addon_edit_poi_modify"] && _editingAddon)
        {
            if ([item[@"title"] isEqualToString:OALocalizedString(@"create_poi_short")])
            {
                OAOsmEditingViewController *editingScreen = [[OAOsmEditingViewController alloc] initWithLat:_targetPoint.location.latitude lon:_targetPoint.location.longitude];
                [[OARootViewController instance].navigationController pushViewController:editingScreen animated:YES];
            }
            else if ([item[@"title"] isEqualToString:OALocalizedString(@"modify_poi_short")])
            {
                OAOsmEditingViewController *editingScreen = [[OAOsmEditingViewController alloc]
                                                             initWithEntity:[[_editingAddon getPoiModificationUtil] loadEntity:_targetPoint]];
                [[OARootViewController instance].navigationController pushViewController:editingScreen animated:YES];
            }
            
        }
        else if ([key isEqualToString:@"addon_edit_poi_create_note"] && _editingAddon)
        {
            dismissBottomSheet = NO;
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"osm_alert_title") message:OALocalizedString(@"osm_alert_message") preferredStyle:UIAlertControllerStyleAlert];
            [alert.textFields.firstObject sizeToFit];
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                [vwController dismiss];
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"osm_alert_button_ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSString* message = alert.textFields.firstObject.text;
                if (_editingAddon) {
                    OAOsmNotePoint *p = [[OAOsmNotePoint alloc] init];
                    [p setLatitude:_targetPoint.location.latitude];
                    [p setLongitude:_targetPoint.location.longitude];
                    // TODO add autor credentials
                    [p setAuthor:@""];
                    [[_editingAddon getOsmNotesUtil] commit:p text:message action:CREATE];
                    [vwController dismiss];
                }
            }]];
            [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                textField.placeholder = @"Please specify the message";
                textField.keyboardType = UIKeyboardTypeEmailAddress;
            }];
            [vwController presentViewController:alert animated:YES completion:nil];
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (dismissBottomSheet)
        [vwController dismiss];
}

@synthesize vwController;

@end

@interface OAMoreOprionsBottomSheetViewController ()

@end

@implementation OAMoreOprionsBottomSheetViewController

- (instancetype) initWithTargetPoint:(OATargetPoint *)targetPoint
{
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
