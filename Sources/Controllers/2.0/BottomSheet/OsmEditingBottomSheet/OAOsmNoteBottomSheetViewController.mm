//
//  OAOsmNoteBottomSheetViewController.m
//  OsmAnd
//
//  Created by Paul on 4/4/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//


#import "OAOsmNoteBottomSheetViewController.h"
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
#import "OAOsmEditingPlugin.h"
#import "OAOsmNotePoint.h"
#import "OADescrTitleCell.h"
#import "OABottomSheetTwoButtonsViewController.h"
#import "OAOsmBugsRemoteUtil.h"
#import "OAOsmBugsDBHelper.h"
#import "OAOsmBugResult.h"
#import "OAMapLayers.h"

#define kButtonsDividerTag 150
#define kMessageFieldIndex 1

@interface OAOsmNoteBottomSheetScreen () <OAOsmMessageForwardingDelegate>

@end

@implementation OAOsmNoteBottomSheetScreen
{
    OsmAndAppInstance _app;
    OAOsmNoteBottomSheetViewController *vwController;
    NSArray* _data;
    
    NSMutableArray *_floatingTextFieldControllers;
    OAOsmEditingPlugin *_plugin;
    NSArray *_bugPoints;
    
    EOAOSMNoteBottomSheetType _screenType;
    
    BOOL _uploadAnonymously;
    BOOL _uploadImmediately;
}

@synthesize tableData, tblView;

- (id) initWithTable:(UITableView *)tableView viewController:(OAOsmNoteBottomSheetViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        _plugin = param;
        [self initOnConstruct:tableView viewController:viewController];
        _floatingTextFieldControllers = [NSMutableArray new];
        _uploadAnonymously = NO;
        _bugPoints = vwController.osmPoints;
        _screenType = viewController.type;
        _uploadImmediately = NO;
    }
    return self;
}

- (void) initOnConstruct:(UITableView *)tableView viewController:(OAOsmNoteBottomSheetViewController *)viewController
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
    NSString *title = [self getTitle];
    [arr addObject:@{
                     @"type" : @"OABottomSheetHeaderCell",
                     @"title" : title,
                     @"description" : @""
                     }];
    if (_screenType == TYPE_UPLOAD)
    {
        [arr addObject:@{
                         @"type" : @"OADescrTitleCell",
                         @"title" : OALocalizedString(@"osm_note_upload_info"),
                         @"description" : @""
                         }];
    }
    else
    {
        
        [arr addObject:@{
                         @"type" : @"OATextInputFloatingCell",
                         @"name" : @"osm_message",
                         @"cell" : [self getInputCellWithHint:OALocalizedString(@"osm_alert_message") text:((OAOsmNotePoint *)_bugPoints.firstObject).getText roundedCorners:UIRectCornerAllCorners hideUnderline:YES]
                         }];
        
        if (_screenType == TYPE_CREATE)
        {
            [arr addObject:@{
                             @"type" : @"OASwitchCell",
                             @"name" : @"upload_immediately",
                             @"title" : OALocalizedString(@"osm_note_upload_immediately"),
                             @"value" : @(_uploadImmediately)
                             }];
        }
    }
    
    if (_screenType != TYPE_CREATE || _uploadImmediately)
    {
        [arr addObject:@{ @"type" : @"OADividerCell" } ];
        
        [arr addObject:@{
                         @"type" : @"OASwitchCell",
                         @"name" : @"upload_anonymously",
                         @"title" : OALocalizedString(@"osm_note_upload_anonymously"),
                         @"value" : @(_uploadAnonymously)
                         }];
        
        OAAppSettings *settings = [OAAppSettings sharedManager];
        
        [arr addObject:@{
                         @"type" : @"OATextInputFloatingCell",
                         @"name" : @"osm_user",
                         @"cell" : [self getInputCellWithHint:OALocalizedString(@"osm_name") text:settings.osmUserName roundedCorners:UIRectCornerTopLeft | UIRectCornerTopRight hideUnderline:NO]
                         }];
        
        [arr addObject:@{
                         @"type" : @"OATextInputFloatingCell",
                         @"name" : @"osm_pass",
                         @"cell" : [self getInputCellWithHint:OALocalizedString(@"osm_pass") text:settings.osmUserPassword roundedCorners:UIRectCornerBottomLeft | UIRectCornerBottomRight hideUnderline:YES]
                         }];
    }
    
    _data = [NSArray arrayWithArray:arr];
}

- (NSString *) getTitle
{
    NSString *title = OALocalizedString(@"osm_note_create");
    if (_screenType == TYPE_CLOSE)
        title = OALocalizedString(@"osm_note_close");
    else if (_screenType == TYPE_REOPEN)
        title = OALocalizedString(@"osm_note_reopen_title");
    else if (_screenType == TYPE_MODIFY)
        title = OALocalizedString(@"osm_note_comment_title");
    
    return title;
}

- (OATextInputFloatingCell *)getInputCellWithHint:(NSString *)hint text:(NSString *)text roundedCorners:(UIRectCorner)corners hideUnderline:(BOOL)shouldHide
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATextInputFloatingCell" owner:self options:nil];
    OATextInputFloatingCell *resultCell = (OATextInputFloatingCell *)[nib objectAtIndex:0];
    resultCell.backgroundColor = [UIColor clearColor];
    MDCMultilineTextField *textField = resultCell.inputField;
    textField.underline.hidden = shouldHide;
    textField.placeholder = hint;
    [textField.textView setText:text];
    textField.userInteractionEnabled = NO;
    textField.font = [UIFont systemFontOfSize:17.0];
    textField.clearButton.imageView.tintColor = UIColorFromRGB(color_icon_color);
    [textField.clearButton setImage:[[UIImage imageNamed:@"ic_custom_clear_field"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [textField.clearButton setImage:[[UIImage imageNamed:@"ic_custom_clear_field"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateHighlighted];
    if (!_floatingTextFieldControllers)
        _floatingTextFieldControllers = [NSMutableArray new];
    
    MDCTextInputControllerFilled *fieldController = [[MDCTextInputControllerFilled alloc] initWithTextInput:textField];
    fieldController.borderFillColor = [UIColor colorWithRed:0.82 green:0.82 blue:0.84 alpha:1];
    fieldController.roundedCorners = corners;
    fieldController.disabledColor = [UIColor blackColor];
    fieldController.inlinePlaceholderFont = [UIFont systemFontOfSize:16.0];
    fieldController.textInput.textInsetsMode = MDCTextInputTextInsetsModeIfContent;
    [_floatingTextFieldControllers addObject:fieldController];
    
    return resultCell;
}

-(void) doneButtonPressed
{
    OATextInputFloatingCell *cell = _data[kMessageFieldIndex][@"cell"];
    BOOL shouldWarn = _bugPoints.count == 1;
    for (OAOsmNotePoint *p in _bugPoints)
    {
        NSString *comment = _screenType == TYPE_UPLOAD ? p.getText : cell.inputField.text;
        if (shouldWarn && (!comment || comment.length == 0))
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"osm_note_empty_message") preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:nil]];
            [self.vwController presentViewController:alert animated:YES completion:nil];
            return;
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            if (_screenType != TYPE_CREATE || _uploadImmediately)
            {
                OAOsmBugsRemoteUtil *util = (OAOsmBugsRemoteUtil *) [_plugin getRemoteOsmNotesUtil];
                NSString *message = [util commit:p text:comment action:p.getAction anonymous:_uploadAnonymously].warning;
                
                if (!message)
                {
                    [[OAOsmBugsDBHelper sharedDatabase] deleteAllBugModifications:p];
                    [_app.osmEditsChangeObservable notifyEvent];
                }
                else
                {
                    message = message.length == 0 ? OALocalizedString(@"osm_upload_failed_descr") : message;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"osm_upload_failed_title") message:message preferredStyle:UIAlertControllerStyleAlert];
                        
                        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:nil]];
                        [[OARootViewController instance] presentViewController:alert animated:YES completion:nil];
                    });
                }
            }
            else
            {
                id<OAOsmBugsUtilsProtocol> util = [_plugin getLocalOsmNotesUtil];
                if (p.getAction == CREATE)
                    [util commit:p text:comment action:p.getAction];
                else
                    [util modify:p text:comment];
                dispatch_async(dispatch_get_main_queue(), ^{
                    OAOsmNotePoint *note = [[OAOsmNotePoint alloc] init];
                    [note setLatitude:p.getLatitude];
                    [note setLongitude:p.getLongitude];
                    [note setId:p.getId];
                    [note setText:comment];
                    [note setAuthor:@""];
                    [note setAction:p.getAction];
                    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
                    OATargetPoint *newTarget = [mapPanel.mapViewController.mapLayers.osmEditsLayer getTargetPoint:note];
                    [mapPanel showContextMenu:newTarget];
                });
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [vwController.delegate refreshData];
            });
        });
    }
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
        return [OADividerCell cellHeight:0.5 dividerInsets:UIEdgeInsetsMake(6.0, 44.0, 4.0, 0.0)];
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
    else if ([item[@"type"] isEqualToString:@"OADescrTitleCell"])
    {
        return [OADescrTitleCell getHeight:item[@"title"] desc:item[@"description"] cellWidth:DeviceScreenWidth];
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
            cell.dividerInsets = UIEdgeInsetsMake(6.0, 16.0, 4.0, 0.0);
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
            cell.switchView.tintColor = [UIColor whiteColor];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:@"OATextInputFloatingCell"])
    {
        return item[@"cell"];
    }
    else if ([item[@"type"] isEqualToString:@"OADescrTitleCell"])
    {
        OADescrTitleCell* cell;
        cell = (OADescrTitleCell *)[self.tblView dequeueReusableCellWithIdentifier:@"OADescrTitleCell"];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OADescrTitleCell" owner:self options:nil];
            cell = (OADescrTitleCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            cell.descriptionView.text = item[@"title"];
            cell.descriptionView.textColor = UIColorFromRGB(text_color_osm_note_bottom_sheet);
            cell.backgroundColor = [UIColor clearColor];
            cell.textView.hidden = YES;
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
            BOOL isChecked = sw.on;
            if ([name isEqualToString:@"upload_immediately"])
            {
                _uploadImmediately = isChecked;
                [self updatePasswordSection:isChecked];
                OABottomSheetTwoButtonsViewController *controller = (OABottomSheetTwoButtonsViewController *)vwController;
                [controller.doneButton setTitle:_uploadImmediately ?
                    OALocalizedString(@"shared_string_upload") : OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
            }
            else if ([name isEqualToString:@"upload_anonymously"])
                _uploadAnonymously = isChecked;
        }
    }
}

- (void) updatePasswordSection:(BOOL)shouldShow
{
    [self.tblView beginUpdates];
    
    NSMutableArray *indexPaths = [NSMutableArray new];
    [self setupView];
    for (int i = 3; i < 7; i++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:0]];
    }
    if (shouldShow)
        [self.tblView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
    else
        [self.tblView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
    
    [self.tblView endUpdates];
    [self.tblView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:_data.count - 1 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
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
    [(OAOsmNotePoint *) _bugPoints.firstObject setText:text];
    [self.tblView reloadData];
}

- (void) refreshData
{
    [self.tblView reloadData];
}

@end

@interface OAOsmNoteBottomSheetViewController ()

@end

@implementation OAOsmNoteBottomSheetViewController
{
    EOAAction _action;
}

- (id) initWithEditingPlugin:(OAOsmEditingPlugin *)plugin points:(NSArray *)points type:(EOAOSMNoteBottomSheetType)type
{
    _osmPoints = points;
    _type = type;
    return [super initWithParam:plugin];
}

- (OAOsmEditingPlugin *)plugin
{
    return self.customParam;
}

- (void) setupView
{
    if (!self.screenObj)
        self.screenObj = [[OAOsmNoteBottomSheetScreen alloc] initWithTable:self.tableView viewController:self param:self.plugin];
    
    [super setupView];
}
- (void)applyLocalization
{
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.doneButton setTitle:_type != TYPE_CREATE ? OALocalizedString(@"shared_string_upload") : OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
}

@end
