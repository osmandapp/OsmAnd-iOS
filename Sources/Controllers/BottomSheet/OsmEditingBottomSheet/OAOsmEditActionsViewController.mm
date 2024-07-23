//
//  OAOsmEditActionsViewController.m
//  OsmAnd
//
//  Created by Paul on 4/18/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOsmEditActionsViewController.h"
#import "OAOsmNoteViewController.h"
#import "Localization.h"
#import "OABottomSheetHeaderCell.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "OAPlugin.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OARootViewController.h"
#import "OASizes.h"
#import "OAAppSettings.h"
#import "OAOsmPoint.h"
#import "OAOpenStreetMapPoint.h"
#import "OAObservable.h"
#import "OAOsmEditsDBHelper.h"
#import "OAOsmEditingPlugin.h"
#import "OAOsmNotePoint.h"
#import "OASimpleTableViewCell.h"
#import "OABottomSheetTwoButtonsViewController.h"
#import "OAOsmUploadPOIViewController.h"
#import "OAOsmBugsRemoteUtil.h"
#import "OAOsmBugsDBHelper.h"
#import "OAOsmBugResult.h"
#import "OAMapLayers.h"
#import "OAOsmEditingViewController.h"
#import "OAPluginsHelper.h"

#define kButtonsDividerTag 150
#define kMessageFieldIndex 1

@interface OAOsmEditActionsBottomSheetScreen ()

@end

@implementation OAOsmEditActionsBottomSheetScreen
{
    OsmAndAppInstance _app;
    NSArray* _data;
    
    OAOsmEditingPlugin *_plugin;
    OAOsmPoint *_point;
}

@synthesize tableData, tblView, vwController;

- (id) initWithTable:(UITableView *)tableView viewController:(OAOsmEditActionsViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        _plugin = param;
        [self initOnConstruct:tableView viewController:viewController];
        _point = vwController.osmPoint;
    }
    return self;
}

- (void) initOnConstruct:(UITableView *)tableView viewController:(OAOsmEditActionsViewController *)viewController
{
    _app = [OsmAndApp instance];
    
    vwController = viewController;
    tblView = tableView;
    tblView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self initData];
}

- (void) setupView
{
    [[self.vwController.buttonsView viewWithTag:kButtonsDividerTag] removeFromSuperview];
    NSMutableArray *arr = [NSMutableArray array];
    [arr addObject:@{
                     @"type" : [OABottomSheetHeaderCell getCellIdentifier],
                     @"title" : _point.getName,
                     @"description" : @""
                     }];
    
    [arr addObject:@{ @"title" : OALocalizedString(@"upload_to_osm"),
                      @"key" : @"upload_to_osm",
                      @"img" : @"ic_custom_upload",
                      @"type" : [OASimpleTableViewCell getCellIdentifier] } ];

    [arr addObject:@{ @"title" : OALocalizedString(@"osm_edit_show_on_map"),
                      @"key" : @"osm_edit_show_on_map",
                      @"descr" : OALocalizedString(@"osm_edit_show_on_map_descr"),
                      @"img" : @"ic_custom_show_on_map",
                      @"type" : [OASimpleTableViewCell getCellIdentifier] } ];
    
    [arr addObject:@{ @"title" : OALocalizedString(@"poi_context_menu_modify_osm_change"),
                      @"key" : @"poi_modify",
                      @"img" : @"ic_custom_edit",
                      @"type" : [OASimpleTableViewCell getCellIdentifier] }];
    
    [arr addObject:@{ @"title" : OALocalizedString(@"shared_string_delete"),
                      @"key" : @"edit_delete",
                      @"img" : @"ic_custom_remove",
                      @"type" : [OASimpleTableViewCell getCellIdentifier] }];
    
    _data = [NSArray arrayWithArray:arr];
}

- (void) initData
{
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
    
    if ([item[@"type"] isEqualToString:[OABottomSheetHeaderCell getCellIdentifier]])
    {
        OABottomSheetHeaderCell* cell = [tableView dequeueReusableCellWithIdentifier:[OABottomSheetHeaderCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OABottomSheetHeaderCell getCellIdentifier] owner:self options:nil];
            cell = (OABottomSheetHeaderCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsMake(0., DBL_MAX, 0., 0.);
        }
        if (cell)
        {
            cell.titleView.text = item[@"title"];
            cell.sliderView.layer.cornerRadius = 3.0;
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
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
            NSString *desc = item[@"descr"];
            cell.descriptionLabel.text = desc;
            [cell descriptionVisibility:desc.length != 0];
            [cell.leftIconView setTintColor:UIColorFromRGB(color_icon_color)];
            cell.leftIconView.image = img;
        }
        
        return cell;
    }
    else
    {
        return nil;
    }
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.row];
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.001;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 10.0;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    view.hidden = YES;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    if (![item[@"type"] isEqualToString:[OABottomSheetHeaderCell getCellIdentifier]])
        return indexPath;
    else
        return nil;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    if ([item[@"key"] isEqualToString:@"upload_to_osm"])
    {
        [self uploadPoint];
    }
    else if ([item[@"key"] isEqualToString:@"osm_edit_show_on_map"])
    {
        OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
        OATargetPoint *newTarget = [mapPanel.mapViewController.mapLayers.osmEditsLayer getTargetPoint:_point];
        newTarget.centerMap = YES;
        [mapPanel showContextMenu:newTarget];
        [self.vwController dismiss];
        [[OARootViewController instance].mapPanel.navigationController popToRootViewControllerAnimated:YES];
    }
    else if ([item[@"key"] isEqualToString:@"poi_modify"])
    {
        if (_point.getGroup == POI)
        {
            OAOsmEditingViewController *editingScreen = [[OAOsmEditingViewController alloc] initWithEntity:((OAOpenStreetMapPoint *)_point).getEntity];
            editingScreen.delegate = vwController.delegate;
            [[OARootViewController instance].mapPanel.navigationController pushViewController:editingScreen animated:YES];
            [self.vwController dismiss];
        }
        else
        {
            OAOsmNoteViewController *noteScreen = [[OAOsmNoteViewController alloc] initWithEditingPlugin:_plugin points:[NSArray arrayWithObject:_point] type:EOAOsmNoteViewConrollerModeCreate];
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:noteScreen];
            noteScreen.delegate = vwController.delegate;
            [[OARootViewController instance].mapPanel.navigationController presentViewController:navigationController animated:YES completion:nil];
            [self.vwController dismiss];
        }
    }
    else if ([item[@"key"] isEqualToString:@"edit_delete"])
    {
        if (_point.getGroup == POI)
            [[OAOsmEditsDBHelper sharedDatabase] deletePOI:(OAOpenStreetMapPoint *)_point];
        else
            [[OAOsmBugsDBHelper sharedDatabase] deleteAllBugModifications:(OAOsmNotePoint *)_point];
        
        [vwController.delegate refreshData];
        [self.vwController dismiss];
        [_app.osmEditsChangeObservable notifyEvent];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:true];
}

-(void)uploadPoint
{
    if (_point.getGroup == POI)
    {
        OAOsmUploadPOIViewController *dialog = [[OAOsmUploadPOIViewController alloc] initWithPOIItems:[NSArray arrayWithObject:_point]];
        dialog.delegate = vwController.delegate;
        [[OARootViewController instance].mapPanel.navigationController pushViewController:dialog animated:YES];
    }
    else if (_point.getGroup == BUG)
    {
        OAOsmNoteViewController *dialog = [[OAOsmNoteViewController alloc] initWithEditingPlugin:_plugin points:[NSArray arrayWithObject:_point] type:EOAOsmNoteViewConrollerModeUpload];
        dialog.delegate = vwController.delegate;
        [[OARootViewController instance].mapPanel.navigationController pushViewController:dialog animated:YES];
    }
    [self.vwController dismiss];
}

@end

@interface OAOsmEditActionsViewController ()

@end

@implementation OAOsmEditActionsViewController

- (id) initWithPoint:(OAOsmPoint *)point
{
    _osmPoint = point;
    return [super initWithParam:(OAOsmEditingPlugin *) [OAPluginsHelper getPlugin:OAOsmEditingPlugin.class]];
}

- (void)additionalSetup
{
    [super additionalSetup];
    [super hideDoneButton];
}

- (OAOsmEditingPlugin *)plugin
{
    return self.customParam;
}

- (void) setupView
{
    if (!self.screenObj)
        self.screenObj = [[OAOsmEditActionsBottomSheetScreen alloc] initWithTable:self.tableView viewController:self param:self.plugin];
    
    [super setupView];
}
- (void)applyLocalization
{
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
}

@end
