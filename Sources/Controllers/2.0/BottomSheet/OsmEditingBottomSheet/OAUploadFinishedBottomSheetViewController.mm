//
//  OAMoreOptionsBottomSheetViewController.m
//  OsmAnd
//
//  Created by Paul on 20/06/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAUploadFinishedBottomSheetViewController.h"
#import "Localization.h"
#import "OABottomSheetHeaderCell.h"
#import "OABottomSheetHeaderIconCell.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "OAMapPanelViewController.h"
#import "OARootViewController.h"
#import "OASizes.h"
#import "OAAppSettings.h"
#import "OADescrTitleCell.h"
#import "OADividerCell.h"
#import "OARootViewController.h"
#import "OAMapWidgetRegistry.h"
#import "OAProducts.h"
#import "OAMapWidgetRegInfo.h"
#import "OASettingSwitchCell.h"
#import "OAOsmEditingPlugin.h"
#import "MaterialTextFields.h"
#import "OATextInputFloatingCell.h"
#import "OAOsmNoteBottomSheetViewController.h"
#import "OATextEditingBottomSheetViewController.h"
#import "OAAppSettings.h"

#define kButtonsDividerTag 150

@interface OAUploadFinishedBottomSheetScreen () <OAOsmMessageForwardingDelegate>

@end

@implementation OAUploadFinishedBottomSheetScreen
{
    OsmAndAppInstance _app;
    OAUploadFinishedBottomSheetViewController *vwController;
    NSArray* _data;
    
    NSArray<OAOsmPoint *> *_failedPoints;
    BOOL _hasFailedPoints;
    
    NSMutableArray *_floatingTextFieldControllers;
    
}

@synthesize tableData, tblView;

- (id) initWithTable:(UITableView *)tableView viewController:(OAUploadFinishedBottomSheetViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        [self initOnConstruct:tableView viewController:viewController];
        _failedPoints = vwController.customParam;
        _hasFailedPoints = _failedPoints.count > 0;
        _floatingTextFieldControllers = [NSMutableArray new];
    }
    return self;
}

- (void) initOnConstruct:(UITableView *)tableView viewController:(OAUploadFinishedBottomSheetViewController *)viewController
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
    
    if (_hasFailedPoints)
    {
        [arr addObject:@{
                         @"type" : [OABottomSheetHeaderIconCell getCellIdentifier],
                         @"title" : OALocalizedString(@"osm_upload_failed_title"),
                         @"description" : @"",
                         @"img" : @"ic_custom_failure"
                         }];
    }

    if (!_hasFailedPoints)
    {
        [arr addObject:@{
                         @"type" : [OASettingSwitchCell getCellIdentifier],
                         @"title" : OALocalizedString(@"osm_upload_complete"),
                         @"description" : @"",
                         @"img" : @"ic_custom_success"
                         }];
    }
    else if (vwController.successfulUploadsCount > 0)
    {
        NSString *value = [NSString stringWithFormat:@"%@: %zd\n%@: %zd", OALocalizedString(@"osm_succsessful_uploads"),
                           vwController.successfulUploadsCount,
                           OALocalizedString(@"osm_failed_uploads"),
                           _failedPoints.count];
        NSMutableString *names = [NSMutableString string];
        for (NSInteger i = 0; i < _failedPoints.count; i++)
        {
            OAOsmPoint * p = _failedPoints[i];
            if (p.getGroup == POI)
            {
                NSString *name = p.getName;
                name = name.length == 0 ? [OAOsmEditingPlugin getCategory:p] : name;
                [names appendString:name];
                if (i < _failedPoints.count - 1)
                    [names appendString:@", "];
            }
        }
        if (names.length > 0)
            value = [NSString stringWithFormat:@"%@ (%@)", value, names];
        [arr addObject:@{
                         @"type" : [OADescrTitleCell getCellIdentifier],
                         @"title" : value,
                         @"description" : @""
                         }];
        
        [arr addObject:@{ @"type" : [OADividerCell getCellIdentifier] } ];
        
        [arr addObject:@{
                         @"type" : [OADescrTitleCell getCellIdentifier],
                         @"title" : OALocalizedString(@"osm_upload_no_internet"),
                         @"description" : @""
                         }];
    }
    else
    {
        [arr addObject:@{
                         @"type" : [OADescrTitleCell getCellIdentifier],
                         @"title" : OALocalizedString(@"osm_upload_failed_descr"),
                         @"description" : @""
                         }];
        
        [arr addObject:@{ @"type" : [OADividerCell getCellIdentifier] } ];
        
        OAAppSettings *settings = [OAAppSettings sharedManager];
        [arr addObject:@{
                         @"type" : [OATextInputFloatingCell getCellIdentifier],
                         @"name" : @"osm_user",
                         @"cell" : [OAOsmNoteBottomSheetViewController getInputCellWithHint:OALocalizedString(@"osm_name") text:settings.osmUserName roundedCorners:UIRectCornerTopLeft | UIRectCornerTopRight hideUnderline:NO floatingTextFieldControllers:_floatingTextFieldControllers]
                         }];
        
        [arr addObject:@{
                         @"type" : [OATextInputFloatingCell getCellIdentifier],
                         @"name" : @"osm_pass",
                         @"cell" : [OAOsmNoteBottomSheetViewController getPasswordCellWithHint:OALocalizedString(@"osm_pass") text:settings.osmUserPassword roundedCorners:UIRectCornerBottomLeft | UIRectCornerBottomRight hideUnderline:YES floatingTextFieldControllers:_floatingTextFieldControllers]
                         }];
    }
    
    
    _data = [NSArray arrayWithArray:arr];
}

- (void) initData
{
}

- (void) doneButtonPressed
{
    [vwController.delegate retryUpload];
    [self.vwController dismiss];
}

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    NSDictionary *item = _data[indexPath.row];
    if ([item[@"type"] isEqualToString:[OADividerCell getCellIdentifier]])
    {
        return [OADividerCell cellHeight:0.5 dividerInsets:UIEdgeInsetsMake(6.0, 0.0, 16.0, 0.0)];
    }
    else if ([item[@"type"] isEqualToString:[OATextInputFloatingCell getCellIdentifier]])
    {
        return MAX(((OATextInputFloatingCell *)_data[indexPath.row][@"cell"]).inputField.intrinsicContentSize.height, 60.0);
    }
    else
    {
        return UITableViewAutomaticDimension;
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
    
    
    if ([item[@"type"] isEqualToString:[OABottomSheetHeaderCell getCellIdentifier]])
    {
        OABottomSheetHeaderCell* cell = [tableView dequeueReusableCellWithIdentifier:[OABottomSheetHeaderCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OABottomSheetHeaderCell getCellIdentifier] owner:self options:nil];
            cell = (OABottomSheetHeaderCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.sliderView.layer.cornerRadius = 3.0;
            cell.separatorInset = UIEdgeInsetsMake(0., DBL_MAX, 0., 0.);
        }
        if (cell)
            cell.titleView.text = item[@"title"];
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OABottomSheetHeaderIconCell getCellIdentifier]])
    {
        OABottomSheetHeaderIconCell* cell = [tableView dequeueReusableCellWithIdentifier:[OABottomSheetHeaderIconCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OABottomSheetHeaderIconCell getCellIdentifier] owner:self options:nil];
            cell = (OABottomSheetHeaderIconCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.titleView.text = item[@"title"];
            cell.iconView.image = [UIImage imageNamed:item[@"img"]];
            cell.iconView.hidden = !cell.iconView.image;
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OASettingSwitchCell getCellIdentifier]])
    {
        OASettingSwitchCell* cell = [tableView dequeueReusableCellWithIdentifier:[OASettingSwitchCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingSwitchCell getCellIdentifier] owner:self options:nil];
            cell = (OASettingSwitchCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            cell.backgroundColor = UIColor.clearColor;
            [cell.switchView setHidden:YES];
        
            cell.textView.text = item[@"title"];
            cell.descriptionView.hidden = YES;
            [cell setSecondaryImage:nil];
            cell.imgView.image = [UIImage imageNamed:item[@"img"]];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell setNeedsUpdateConstraints];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OADescrTitleCell getCellIdentifier]])
    {
        OADescrTitleCell* cell;
        cell = (OADescrTitleCell *)[self.tblView dequeueReusableCellWithIdentifier:[OADescrTitleCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADescrTitleCell getCellIdentifier] owner:self options:nil];
            cell = (OADescrTitleCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            cell.descriptionView.text = item[@"title"];
            cell.descriptionView.textColor = [UIColor blackColor];
            cell.backgroundColor = [UIColor clearColor];
            cell.textView.hidden = YES;
            cell.textViewZeroHeightConstraint.priority = 1000;
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
            cell.dividerInsets = UIEdgeInsetsMake(6.0, 0.0, 16.0, 0.0);
            cell.dividerHight = 0.5;
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OATextInputFloatingCell getCellIdentifier]])
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
    return _hasFailedPoints ? 16.0 : 32.0;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    view.hidden = YES;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.row];
    if ([item[@"type"] isEqualToString:[OATextInputFloatingCell getCellIdentifier]])
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

- (void) refreshData
{
    [self.tblView reloadData];
}

- (void) setMessageText:(NSString *)text
{
}

@end

@interface OAUploadFinishedBottomSheetViewController ()

@end

@implementation OAUploadFinishedBottomSheetViewController

- (id) initWithFailedPoints:(NSArray<OAOsmPoint *> *)points successfulUploads:(NSInteger)successfulUploads
{
    _successfulUploadsCount = successfulUploads;
    return [super initWithParam:points];
}

- (void) setupView
{
    if (!self.screenObj)
        self.screenObj = [[OAUploadFinishedBottomSheetScreen alloc] initWithTable:self.tableView viewController:self param:self.customParam];
    
    [super setupView];
}

- (void)additionalSetup
{
    [super additionalSetup];
    if (((NSArray *) self.customParam).count == 0)
    [super hideDoneButton];
}

- (void)applyLocalization
{
    BOOL isSuccessful = ((NSArray *) self.customParam).count == 0;
    [self.cancelButton setTitle:isSuccessful ? OALocalizedString(@"shared_string_close") : OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    if (!isSuccessful)
        [self.doneButton setTitle:OALocalizedString(@"shared_string_retry") forState:UIControlStateNormal];
}

@end
