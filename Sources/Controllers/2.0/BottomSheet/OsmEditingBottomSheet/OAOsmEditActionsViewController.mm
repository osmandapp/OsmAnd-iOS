//
//  OAOsmEditActionsViewController.m
//  OsmAnd
//
//  Created by Paul on 4/18/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOsmEditActionsViewController.h"
#import "OAOsmNoteBottomSheetViewController.h"
#import "Localization.h"
#import "OABottomSheetHeaderCell.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "OAPlugin.h"
#import "OAMapPanelViewController.h"
#import "OARootViewController.h"
#import "OASizes.h"
#import "OAAppSettings.h"
#import "OAOsmPoint.h"
#import "OAOpenStreetMapPoint.h"
#import "OAOsmEditsDBHelper.h"
#import "OAOsmEditingPlugin.h"
#import "OAOsmNotePoint.h"
#import "OABottomSheetActionCell.h"
#import "OABottomSheetTwoButtonsViewController.h"
#import "OAOsmEditingBottomSheetViewController.h"
#import "OAOsmBugsRemoteUtil.h"
#import "OAOsmBugsDBHelper.h"
#import "OAOsmBugResult.h"
#import "OAMapLayers.h"
#import "OAOsmEditingViewController.h"

#define kButtonsDividerTag 150
#define kMessageFieldIndex 1

#define kBottomSheetActionCell @"OABottomSheetActionCell"

@interface OAOsmEditActionsBottomSheetScreen ()

@end

@implementation OAOsmEditActionsBottomSheetScreen
{
    OsmAndAppInstance _app;
    OAOsmEditActionsViewController *vwController;
    NSArray* _data;
    
    OAOsmEditingPlugin *_plugin;
    OAOsmPoint *_point;
}

@synthesize tableData, tblView;

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
                     @"type" : @"OABottomSheetHeaderCell",
                     @"title" : _point.getName,
                     @"description" : @""
                     }];
    
    [arr addObject:@{ @"title" : OALocalizedString(@"upload_to_osm"),
                      @"key" : @"upload_to_osm",
                      @"img" : @"ic_custom_upload",
                      @"type" : kBottomSheetActionCell } ];

    [arr addObject:@{ @"title" : OALocalizedString(@"osm_edit_show_on_map"),
                      @"key" : @"osm_edit_show_on_map",
                      @"descr" : OALocalizedString(@"osm_edit_show_on_map_descr"),
                      @"img" : @"ic_custom_show_on_map",
                      @"type" : kBottomSheetActionCell } ];
    
    [arr addObject:@{ @"title" : OALocalizedString(@"modify_edit_short"),
                      @"key" : @"poi_modify",
                      @"img" : @"ic_custom_edit",
                      @"type" : kBottomSheetActionCell }];
    
    [arr addObject:@{ @"title" : OALocalizedString(@"shared_string_delete"),
                      @"key" : @"edit_delete",
                      @"img" : @"ic_custom_remove",
                      @"type" : kBottomSheetActionCell }];
    
    _data = [NSArray arrayWithArray:arr];
}

- (void) initData
{
}

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    NSDictionary *item = _data[indexPath.row];
    
    if ([item[@"type"] isEqualToString:@"OABottomSheetHeaderCell"])
    {
        return [OABottomSheetHeaderCell getHeight:item[@"title"] cellWidth:DeviceScreenWidth];
    }
    else if ([item[@"type"] isEqualToString:kBottomSheetActionCell])
    {
        return [OABottomSheetActionCell getHeight:item[@"title"] value:item[@"descr"] cellWidth:tableView.bounds.size.width];
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
    
    if ([item[@"type"] isEqualToString:@"OABottomSheetHeaderCell"])
    {
        static NSString* const identifierCell = @"OABottomSheetHeaderCell";
        OABottomSheetHeaderCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OABottomSheetHeaderCell" owner:self options:nil];
            cell = (OABottomSheetHeaderCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.titleView.text = item[@"title"];
            cell.sliderView.layer.cornerRadius = 3.0;
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kBottomSheetActionCell])
    {
        static NSString* const identifierCell = kBottomSheetActionCell;
        OABottomSheetActionCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kBottomSheetActionCell owner:self options:nil];
            cell = (OABottomSheetActionCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
        }
        
        if (cell)
        {
            UIImage *img = nil;
            NSString *imgName = item[@"img"];
            if (imgName)
                img = [[UIImage imageNamed:imgName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            
            cell.textView.text = item[@"title"];
            NSString *desc = item[@"descr"];
            cell.descView.text = desc;
            cell.descView.hidden = desc.length == 0;
            [cell.iconView setTintColor:UIColorFromRGB(color_icon_color)];
            cell.iconView.image = img;
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
    return 10.0;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    if (![item[@"type"] isEqualToString:@"OABottomSheetHeaderCell"])
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
            [[OARootViewController instance].mapPanel.navigationController pushViewController:editingScreen animated:YES];
            [self.vwController dismiss];
        }
        else
        {
            OAOsmNoteBottomSheetViewController *noteScreen = [[OAOsmNoteBottomSheetViewController alloc] initWithEditingPlugin:_plugin points:[NSArray arrayWithObject:_point] type:TYPE_CREATE];
            [noteScreen show];
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
    if ([Reachability reachabilityForInternetConnection].currentReachabilityStatus == NotReachable)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"osm_upload_failed_title") message:OALocalizedString(@"osm_upload_no_internet") preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:nil]];
        [[OARootViewController instance] presentViewController:alert animated:YES completion:nil];
        return;
    }
    if (_point.getGroup == POI)
    {
        OAOsmEditingBottomSheetViewController *dialog = [[OAOsmEditingBottomSheetViewController alloc]
                                                         initWithEditingUtils:_plugin.getOnlineModificationUtil
                                                         points:[NSArray arrayWithObject:_point]];
        
        [dialog show];
    }
    else if (_point.getGroup == BUG)
    {
        OAOsmNoteBottomSheetViewController *dialog = [[OAOsmNoteBottomSheetViewController alloc] initWithEditingPlugin:_plugin
                                                                                                                points:[NSArray arrayWithObject:_point]
                                                                                                                type:TYPE_UPLOAD];
        [dialog show];
    }
    [self.vwController dismiss];
}

@synthesize vwController;

@end

@interface OAOsmEditActionsViewController ()

@end

@implementation OAOsmEditActionsViewController

- (id) initWithPoint:(OAOsmPoint *)point
{
    _osmPoint = point;
    return [super initWithParam:(OAOsmEditingPlugin *) [OAPlugin getPlugin:OAOsmEditingPlugin.class]];
}

- (void) commonInit
{
    [super commonInit];
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
