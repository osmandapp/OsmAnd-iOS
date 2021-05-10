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
#import "OASwitchTableViewCell.h"
#import "OAPasswordInputFieldCell.h"
#import "OADividerCell.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "OAIAPHelper.h"
#import "OAMapPanelViewController.h"
#import "OARootViewController.h"
#import "OATextEditingBottomSheetViewController.h"
#import "OAUploadFinishedBottomSheetViewController.h"
#import "OAEntity.h"
#import "OAOpenStreetMapLocalUtil.h"
#import "OAOpenStreetMapRemoteUtil.h"
#import "MaterialTextFields.h"
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
#import "OAUploadOsmPointsAsyncTask.h"

#define kButtonsDividerTag 150

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
    [_floatingTextFieldControllers removeAllObjects];
    [[self.vwController.buttonsView viewWithTag:kButtonsDividerTag] removeFromSuperview];
    NSMutableArray *arr = [NSMutableArray array];
    NSString *title = [self getTitle];
    [arr addObject:@{
                     @"type" : [OABottomSheetHeaderCell getCellIdentifier],
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
                         @"cell" : [OAOsmNoteBottomSheetViewController getInputCellWithHint:OALocalizedString(@"osm_alert_message") text:((OAOsmNotePoint *)_bugPoints.firstObject).getText roundedCorners:UIRectCornerAllCorners hideUnderline:YES floatingTextFieldControllers:_floatingTextFieldControllers]
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
                         @"cell" : [OAOsmNoteBottomSheetViewController getInputCellWithHint:OALocalizedString(@"osm_name") text:settings.osmUserName roundedCorners:UIRectCornerTopLeft | UIRectCornerTopRight hideUnderline:NO floatingTextFieldControllers:_floatingTextFieldControllers]
                         }];
        
        [arr addObject:@{
                         @"type" : @"OATextInputFloatingCell",
                         @"name" : @"osm_pass",
                         @"cell" : [OAOsmNoteBottomSheetViewController getPasswordCellWithHint:OALocalizedString(@"osm_pass") text:settings.osmUserPassword roundedCorners:UIRectCornerBottomLeft | UIRectCornerBottomRight hideUnderline:YES floatingTextFieldControllers:_floatingTextFieldControllers]
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

-(void) doneButtonPressed
{
    BOOL shouldWarn = _screenType != TYPE_UPLOAD;
    BOOL shouldUpload = _screenType != TYPE_CREATE || _uploadImmediately;
    if (shouldWarn)
    {
        OAOsmNotePoint *p = _bugPoints.firstObject;
        NSString *comment = p.getText;
        if (!comment || comment.length == 0)
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"osm_note_empty_message") preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:nil]];
            [self.vwController presentViewController:alert animated:YES completion:nil];
            return;
        }
    }
    if (shouldUpload)
    {
        OAUploadOsmPointsAsyncTask *task = [[OAUploadOsmPointsAsyncTask alloc] initWithPlugin:_plugin points:_bugPoints closeChangeset:NO anonymous:_uploadAnonymously comment:nil bottomSheetDelegate:vwController.delegate];
        [task uploadPoints];
    }
    else
        [self saveNote];
    
    [vwController dismiss];
    if ([vwController.delegate respondsToSelector:@selector(dismissEditingScreen)])
        [vwController.delegate dismissEditingScreen];
}

- (void) saveNote
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        id<OAOsmBugsUtilsProtocol> util = [_plugin getLocalOsmNotesUtil];
        OAOsmNotePoint *p = _bugPoints.firstObject;
        if (!p)
            return;
        
        if (p.getAction == CREATE)
            [util commit:p text:p.getText action:p.getAction];
        else
            [util modify:p text:p.getText];
        
        OAOsmNotePoint *note = [[OAOsmNotePoint alloc] init];
        [note setLatitude:p.getLatitude];
        [note setLongitude:p.getLongitude];
        [note setId:p.getId];
        [note setText:p.getText];
        [note setAuthor:@""];
        [note setAction:p.getAction];
        dispatch_async(dispatch_get_main_queue(), ^{
            OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
            OATargetPoint *newTarget = [mapPanel.mapViewController.mapLayers.osmEditsLayer getTargetPoint:note];
            [mapPanel showContextMenu:newTarget];
            [vwController.delegate refreshData];
        });
    });
}

- (void) initData
{
}

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    NSDictionary *item = _data[indexPath.row];
    if ([item[@"type"] isEqualToString:@"OADividerCell"])
    {
        return [OADividerCell cellHeight:0.5 dividerInsets:UIEdgeInsetsMake(6.0, 16.0, 5.0, 0.0)];
    }
    else if ([item[@"type"] isEqualToString:@"OATextInputFloatingCell"])
    {
        return MAX(((OATextInputFloatingCell *)_data[indexPath.row][@"cell"]).inputField.intrinsicContentSize.height, 60.0);
    }
    else if ([item[@"type"] isEqualToString:@"OASwitchCell"] || [item[@"type"] isEqualToString:[OABottomSheetHeaderCell getCellIdentifier]] || [item[@"type"] isEqualToString:@"OADescrTitleCell"])
    {
        return UITableViewAutomaticDimension;
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
            cell.dividerInsets = UIEdgeInsetsMake(6.0, 16.0, 5.0, 0.0);
            cell.dividerHight = 0.5;
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OABottomSheetHeaderCell getCellIdentifier]])
    {
        static NSString* const identifierCell = [OABottomSheetHeaderCell getCellIdentifier];
        OABottomSheetHeaderCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
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
            cell.switchView.tintColor = UIColorFromRGB(color_bottom_sheet_secondary);
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
            cell.descriptionView.textColor = UIColorFromRGB(color_text_footer);
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
    return kEstimatedRowHeight;
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
    return 10.0;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    view.hidden = YES;
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

+ (OATextInputFloatingCell *)getInputCellWithHint:(NSString *)hint text:(NSString *)text roundedCorners:(UIRectCorner)corners hideUnderline:(BOOL)shouldHide floatingTextFieldControllers:(NSMutableArray *)floatingControllers
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
    
    MDCTextInputControllerFilled *fieldController = [[MDCTextInputControllerFilled alloc] initWithTextInput:textField];
    fieldController.borderFillColor = UIColorFromRGB(color_osm_editing_text_field);
    fieldController.roundedCorners = corners;
    fieldController.inlinePlaceholderFont = [UIFont systemFontOfSize:16.0];
    fieldController.textInput.textInsetsMode = MDCTextInputTextInsetsModeIfContent;
    [floatingControllers addObject:fieldController];
    
    return resultCell;
}

+ (OAPasswordInputFieldCell *)getPasswordCellWithHint:(NSString *)hint text:(NSString *)text roundedCorners:(UIRectCorner)corners hideUnderline:(BOOL)shouldHide floatingTextFieldControllers:(NSMutableArray *)floatingControllers
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAPasswordInputFieldCell" owner:self options:nil];
    OAPasswordInputFieldCell *resultCell = (OAPasswordInputFieldCell *)[nib objectAtIndex:0];
    resultCell.backgroundColor = [UIColor clearColor];
    MDCTextField *textField = resultCell.inputField;
    textField.rightView = [[UIView alloc] initWithFrame:CGRectMake(0., 0., 30., 30.)];
    textField.rightViewMode = UITextFieldViewModeAlways;
    [textField.rightView addConstraint:[NSLayoutConstraint constraintWithItem:textField.rightView
                                                                    attribute:NSLayoutAttributeWidth
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:nil
                                                                    attribute: NSLayoutAttributeNotAnAttribute
                                                                   multiplier:1
                                                                     constant:30]];
    [textField.rightView addConstraint:[NSLayoutConstraint constraintWithItem:textField.rightView
                                                                    attribute:NSLayoutAttributeHeight
                                                                    relatedBy:NSLayoutRelationEqual
                                                                       toItem:nil
                                                                    attribute: NSLayoutAttributeNotAnAttribute
                                                                   multiplier:1
                                                                     constant:30]];
    textField.underline.hidden = shouldHide;
    textField.placeholder = hint;
    [textField setText:text];
    [textField setSecureTextEntry:YES];
    textField.userInteractionEnabled = NO;
    textField.font = [UIFont systemFontOfSize:17.0];
    textField.clearButtonMode = UITextFieldViewModeNever;
    textField.placeholderLabel.backgroundColor = [UIColor clearColor];
    [resultCell setupPasswordButton];
    
    MDCTextInputControllerFilled *fieldController = [[MDCTextInputControllerFilled alloc] initWithTextInput:textField];
    fieldController.borderFillColor = UIColorFromRGB(color_osm_editing_text_field);
    fieldController.roundedCorners = corners;
    fieldController.disabledColor = [UIColor blackColor];
    fieldController.inlinePlaceholderFont = [UIFont systemFontOfSize:16.0];
    fieldController.textInput.textInsetsMode = MDCTextInputTextInsetsModeIfContent;
    [floatingControllers addObject:fieldController];
    
    return resultCell;
}

@end
