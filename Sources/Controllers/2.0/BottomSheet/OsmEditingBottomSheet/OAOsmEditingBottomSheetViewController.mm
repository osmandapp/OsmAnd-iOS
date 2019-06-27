//
//  OAMoreOptionsBottomSheetViewController.m
//  OsmAnd
//
//  Created by Paul on 04/10/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAOsmEditingBottomSheetViewController.h"
#import "Localization.h"
#import "OATextInputFloatingCell.h"
#import "OABottomSheetHeaderCell.h"
#import "OASettingsTitleTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OADividerCell.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "OAIAPHelper.h"
#import "OAMapPanelViewController.h"
#import "OARootViewController.h"
#import "OATextEditingBottomSheetViewController.h"
#import "OAOsmNoteBottomSheetViewController.h"
#import "OAEntity.h"
#import "OAOpenStreetMapLocalUtil.h"
#import "OAOpenStreetMapRemoteUtil.h"
#import "MaterialTextFields.h"
#import "OAEntity.h"
#import "OAPOI.h"
#import "OAEditPOIData.h"
#import "OASizes.h"
#import "OAAppSettings.h"
#import "OANode.h"
#import "OAWay.h"
#import "OAOsmPoint.h"
#import "OAOpenStreetMapPoint.h"
#import "OAOsmEditsDBHelper.h"
#import "OAPOIType.h"
#import "OAPOICategory.h"
#import "OAPOIBaseType.h"
#import "OAUploadFinishedBottomSheetViewController.h"
#import "OAUploadOsmPointsAsyncTask.h"
#import "OAOsmEditingPlugin.h"
#import "OAPlugin.h"

#define kButtonsDividerTag 150
#define kMessageFieldIndex 1

@interface OAOsmEditingBottomSheetScreen () <OAOsmMessageForwardingDelegate>

@end

@implementation OAOsmEditingBottomSheetScreen
{
    OsmAndAppInstance _app;
    OAOsmEditingBottomSheetViewController *vwController;
    NSArray* _data;
    
    NSMutableArray *_floatingTextFieldControllers;
    id<OAOpenStreetMapUtilsProtocol> _editingUtil;
    NSArray *_osmPoints;
    
    BOOL _closeChangeset;
    
    NSString *_messageText;
}

@synthesize tableData, tblView;

- (id) initWithTable:(UITableView *)tableView viewController:(OAOsmEditingBottomSheetViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        _editingUtil = param;
        [self initOnConstruct:tableView viewController:viewController];
        _floatingTextFieldControllers = [NSMutableArray new];
        _osmPoints = vwController.osmPoints;
        _closeChangeset = NO;
        for (OAOsmPoint *p in _osmPoints)
        {
            if (p.getGroup == POI)
            {
                _closeChangeset = YES;
                break;
            }
        }
        
    }
    return self;
}

- (void) initOnConstruct:(UITableView *)tableView viewController:(OAOsmEditingBottomSheetViewController *)viewController
{
    _app = [OsmAndApp instance];
    
    vwController = viewController;
    tblView = tableView;
    tblView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self initData];
}

- (void) setupView
{
    [_floatingTextFieldControllers removeAllObjects];
    [[self.vwController.buttonsView viewWithTag:kButtonsDividerTag] removeFromSuperview];
    NSMutableArray *arr = [NSMutableArray array];
    BOOL shouldDelete = ((OAOsmPoint *)_osmPoints.firstObject).getAction == DELETE;
    [arr addObject:@{
                     @"type" : @"OABottomSheetHeaderCell",
                     @"title" : shouldDelete ? OALocalizedString(@"osm_confirm_delete") : OALocalizedString(@"osm_confirm_upload"),
                     @"description" : @""
                     }];
    NSString *message = !_messageText || _messageText.length == 0 ? [self generateMessage] : _messageText;
    [arr addObject:@{
                     @"type" : @"OATextInputFloatingCell",
                     @"name" : @"osm_message",
                     @"cell" : [OAOsmNoteBottomSheetViewController getInputCellWithHint:OALocalizedString(@"osm_alert_message") text:message roundedCorners:UIRectCornerAllCorners hideUnderline:YES floatingTextFieldControllers:_floatingTextFieldControllers]
                     }];
    
    [arr addObject:@{
                     @"type" : @"OASwitchCell",
                     @"name" : @"close_changeset",
                     @"title" : OALocalizedString(@"osm_close_changeset"),
                     @"value" : @(_closeChangeset)
                     }];
    
    
    
    [arr addObject:@{ @"type" : @"OADividerCell" } ];
    OAAppSettings *settings = [OAAppSettings sharedManager];
    
    [arr addObject:@{
                     @"type" : @"OATextInputFloatingCell",
                     @"name" : @"osm_user",
                     @"cell" : [OAOsmNoteBottomSheetViewController getInputCellWithHint:OALocalizedString(@"osm_name") text:settings.osmUserName roundedCorners:UIRectCornerTopLeft | UIRectCornerTopRight hideUnderline:NO floatingTextFieldControllers:_floatingTextFieldControllers]
                     }];
    
    [arr addObject:@{
                     @"type" : @"OATextInputFloatingCell",
                     @"name" : @"osm_pass",
                     @"cell" : [OAOsmNoteBottomSheetViewController getPasswordCellWithHint:OALocalizedString(@"osm_pass") text:settings.osmUserPassword roundedCorners:UIRectCornerBottomLeft | UIRectCornerBottomRight hideUnderline:YES floatingTextFieldControllers:_floatingTextFieldControllers]
                     }];
    
    _data = [NSArray arrayWithArray:arr];
}

-(NSString *)generateMessage
{
    NSMutableString *res = [NSMutableString new];
    NSInteger lastIndex = _osmPoints.count - 1;
    for (NSInteger i = 0; i < _osmPoints.count; i++)
    {
        OAOsmPoint *p = _osmPoints[i];
        NSString *action = p.getAction == DELETE ? @"Delete" : p.getAction == CREATE ? @"Add" : @"Edit";
        [res appendString:[NSString stringWithFormat:@"%@ %@",
                           action,
                           [[OAEditPOIData alloc] initWithEntity:((OAOpenStreetMapPoint *) p).getEntity].getCurrentPoiType.nameLocalizedEN]];
        if (i != lastIndex)
            [res appendString:@"; "];
    }
    return [NSString stringWithString:res];
}

-(void) doneButtonPressed
{
    OATextInputFloatingCell *cell = _data[kMessageFieldIndex][@"cell"];
    NSString *comment = cell.inputField.text;
    OAUploadOsmPointsAsyncTask *uploadTask  = [[OAUploadOsmPointsAsyncTask alloc] initWithPlugin:(OAOsmEditingPlugin *)[OAPlugin getPlugin:OAOsmEditingPlugin.class] points:_osmPoints closeChangeset:_closeChangeset anonymous:NO comment:comment bottomSheetDelegate:vwController.delegate];
    [uploadTask uploadPoints];
    [vwController dismiss];
}

- (void) initData
{
}

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    NSDictionary *item = _data[indexPath.row];
    if ([item[@"type"] isEqualToString:@"OADividerCell"])
    {
        return [OADividerCell cellHeight:0.5 dividerInsets:UIEdgeInsetsMake(6.0, 0.0, 16.0, 0.0)];
    }
    else if ([item[@"type"] isEqualToString:@"OABottomSheetHeaderCell"])
    {
        return [OABottomSheetHeaderCell getHeight:item[@"title"] cellWidth:DeviceScreenWidth];
    }
    else if ([item[@"type"] isEqualToString:@"OATextInputFloatingCell"])
    {
        return MAX(((OATextInputFloatingCell *)_data[indexPath.row][@"cell"]).inputField.intrinsicContentSize.height, 60.0);
    }
    else if ([item[@"type"] isEqualToString:@"OASwitchCell"])
    {
        return MAX([OASettingsTitleTableViewCell getHeight:item[@"title"] cellWidth:tableView.bounds.size.width], 60.0);
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
    
    if ([item[@"type"] isEqualToString:@"OADividerCell"])
    {
        static NSString* const identifierCell = @"OADividerCell";
        OADividerCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OADividerCell" owner:self options:nil];
            cell = (OADividerCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.dividerColor = UIColorFromRGB(color_divider_blur);
            cell.dividerInsets = UIEdgeInsetsMake(6.0, 0.0, 16.0, 0.0);
            cell.dividerHight = 0.5;
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:@"OABottomSheetHeaderCell"])
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
    else if ([item[@"type"] isEqualToString:@"OASwitchCell"])
    {
        static NSString* const identifierCell = @"OASwitchTableViewCell";
        OASwitchTableViewCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASwitchCell" owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
            cell.textView.numberOfLines = 0;
        }
        
        if (cell)
        {
            cell.backgroundColor = [UIColor clearColor];
            [cell.textView setText: item[@"title"]];
            cell.switchView.on = [item[@"value"] boolValue];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
            cell.switchView.tintColor = UIColorFromRGB(bottomSheetSecondaryColor);
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:@"OATextInputFloatingCell"])
    {
        return item[@"cell"];
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

- (void) applyParameter:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        UISwitch *sw = (UISwitch *) sender;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
        NSDictionary *item = [self getItem:indexPath];
        NSString *name = item[@"name"];
        if (name)
        {
            BOOL isChecked = ((UISwitch *) sender).on;
            if ([name isEqualToString:@"close_changeset"])
                _closeChangeset = isChecked;
        }
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
    return 10.0;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    if (![item[@"type"] isEqualToString:@"OASwitchCell"])
        return indexPath;
    else
        return nil;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    if ([item[@"type"] isEqualToString:@"OATextInputFloatingCell"])
    {
        OATextInputFloatingCell *cell = item[@"cell"];
        EOATextInputBottomSheetType type = [item[@"name"] isEqualToString:@"osm_message"] ?
            MESSAGE_INPUT : [item[@"name"] isEqualToString:@"osm_user"] ? USERNAME_INPUT : PASSWORD_INPUT;
        OATextEditingBottomSheetViewController *ctrl = [[OATextEditingBottomSheetViewController alloc] initWithTitle:cell.inputField.text placeholder:cell.inputField.placeholder type:type];
        ctrl.messageDelegate = self;
        [ctrl show];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:true];
}

@synthesize vwController;

# pragma mark OAOsmMessageForwardingDelegate

- (void)setMessageText:(NSString *)text {
    _messageText = text;
    [self.tblView reloadData];
}

- (void) refreshData
{
    [self.tblView reloadData];
}

@end

@interface OAOsmEditingBottomSheetViewController ()

@end

@implementation OAOsmEditingBottomSheetViewController

- (id) initWithEditingUtils:(id<OAOpenStreetMapUtilsProtocol>)editingUtil points:(NSArray *)points
{
    _osmPoints = points;
    return [super initWithParam:editingUtil];
}

- (id<OAOpenStreetMapUtilsProtocol>)editingUtil
{
    return self.customParam;
}

- (void) setupView
{
    if (!self.screenObj)
        self.screenObj = [[OAOsmEditingBottomSheetScreen alloc] initWithTable:self.tableView viewController:self param:self.editingUtil];
    
    [super setupView];
}

- (void)applyLocalization
{
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.doneButton setTitle:((OAOsmPoint *)_osmPoints.firstObject).getAction == DELETE ? OALocalizedString(@"shared_string_delete") : OALocalizedString(@"shared_string_upload") forState:UIControlStateNormal];
}

@end
