//
//  OAMoreOptionsBottomSheetViewController.m
//  OsmAnd
//
//  Created by Paul on 04/10/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OATextEditingBottomSheetViewController.h"
#import "Localization.h"
#import "OATextInputFloatingCell.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "OAIAPHelper.h"
#import "OAMapPanelViewController.h"
#import "OARootViewController.h"
#import "OAEntity.h"
#import "OAOpenStreetMapLocalUtil.h"
#import "MaterialTextFields.h"
#import "OAPOI.h"
#import "OAEditPOIData.h"
#import "OASizes.h"
#import "OAAppSettings.h"

#define kButtonsDividerTag 150

@interface OATextEditingBottomSheetScreen () <UITextViewDelegate, MDCMultilineTextInputLayoutDelegate>

@end

@implementation OATextEditingBottomSheetScreen
{
    OsmAndAppInstance _app;
    OATextEditingBottomSheetViewController *vwController;
    NSArray* _data;
    
    NSMutableArray *_floatingTextFieldControllers;
    
    NSDictionary *_selectedCellData;
    
    EOATextInputBottomSheetType _inputType;
}

@synthesize tableData, tblView;

- (id) initWithTable:(UITableView *)tableView viewController:(OATextEditingBottomSheetViewController *)viewController param:(id)param
{
    self = [super init];
    if (self)
    {
        _selectedCellData = param;
        _inputType = viewController.inputType;
        [self initOnConstruct:tableView viewController:viewController];
        _floatingTextFieldControllers = [NSMutableArray new];
    }
    return self;
}

- (void) initOnConstruct:(UITableView *)tableView viewController:(OATextEditingBottomSheetViewController *)viewController
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
    _data = [NSArray arrayWithObject:@{
                                       @"type" : @"OATextInputFloatingCell",
                                       @"cell" : [self getInputCellWithHint:_selectedCellData[@"placeholder"] text:_selectedCellData[@"title"]]
                                       }];
}

- (OATextInputFloatingCell *)getInputCellWithHint:(NSString *)hint text:(NSString *)text
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATextInputFloatingCell" owner:self options:nil];
    OATextInputFloatingCell *resultCell = (OATextInputFloatingCell *)[nib objectAtIndex:0];
    resultCell.backgroundColor = [UIColor clearColor];
    MDCMultilineTextField *textField = resultCell.inputField;
    [textField becomeFirstResponder];
    textField.placeholder = hint;
    [textField.textView setText:text];
    textField.underline.hidden = YES;
    textField.textView.delegate = self;
    textField.layoutDelegate = self;
    textField.font = [UIFont systemFontOfSize:17.0];
    textField.clearButton.imageView.tintColor = UIColorFromRGB(color_icon_color);
    [textField.clearButton setImage:[[UIImage imageNamed:@"ic_custom_clear_field"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [textField.clearButton setImage:[[UIImage imageNamed:@"ic_custom_clear_field"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateHighlighted];
    if (_inputType == USERNAME_INPUT || _inputType == PASSWORD_INPUT)
        textField.textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
    if (!_floatingTextFieldControllers)
        _floatingTextFieldControllers = [NSMutableArray new];
    
    MDCTextInputControllerUnderline *fieldController = [[MDCTextInputControllerUnderline alloc] initWithTextInput:textField];
    fieldController.inlinePlaceholderFont = [UIFont systemFontOfSize:16.0];
    fieldController.textInput.textInsetsMode = MDCTextInputTextInsetsModeIfContent;
    [_floatingTextFieldControllers addObject:fieldController];
    
    return resultCell;
}

-(BOOL) cancelButtonPressed
{
    [vwController.messageDelegate refreshData];
    return YES;
}

-(void) doneButtonPressed
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    OATextInputFloatingCell *cell = _data.firstObject[@"cell"];
    [cell.inputField resignFirstResponder];
    switch (_inputType) {
        case USERNAME_INPUT:
            [settings setOsmUserName:cell.inputField.text];
            [vwController.messageDelegate refreshData];
            [vwController dismiss];
            break;
        case PASSWORD_INPUT:
            [settings setOsmUserPassword:cell.inputField.text];
            [vwController.messageDelegate refreshData];
            [vwController dismiss];
            break;
        case MESSAGE_INPUT:
            [vwController.messageDelegate setMessageText:cell.inputField.text];
            [vwController dismiss];
            break;
        default:
            break;
    }
}

- (void) initData
{
}

- (CGFloat) heightForRow:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    NSDictionary *item = _data[indexPath.row];
    if ([item[@"type"] isEqualToString:@"OATextInputFloatingCell"])
    {
        return MAX(((OATextInputFloatingCell *)_data[indexPath.row][@"cell"]).inputField.intrinsicContentSize.height, 60.0);
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
    if ([item[@"type"] isEqualToString:@"OATextInputFloatingCell"])
        return item[@"cell"];
    else
        return nil;
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
    return 0.01;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 10.0;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    view.hidden = YES;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

@synthesize vwController;


#pragma mark - MDCMultilineTextInputLayoutDelegate
- (void)multilineTextField:(id<MDCMultilineTextInput> _Nonnull)multilineTextField
      didChangeContentSize:(CGSize)size
{
    [self.tblView beginUpdates];
    [self.tblView endUpdates];
    [vwController updateTableHeaderView:CurrentInterfaceOrientation];
}

@end

@interface OATextEditingBottomSheetViewController ()

@end

@implementation OATextEditingBottomSheetViewController
{
    NSDictionary *_cellInfo;
}

- (id) initWithTitle:(NSString *)cellTitle placeholder:(NSString *)placeholder type:(EOATextInputBottomSheetType)type
{
    NSDictionary *data = @{
                           @"title" : cellTitle,
                           @"placeholder" : placeholder,
                           };
    _inputType = type;
    return [super initWithParam:data];
}

- (NSDictionary *)data
{
    return self.customParam;
}

- (void) setupView
{
    if (!self.screenObj)
        self.screenObj = [[OATextEditingBottomSheetScreen alloc] initWithTable:self.tableView viewController:self param:self.data];
    [super setupView];
}

- (void)adjustViewHeight
{
    CGRect cancelFrame = self.buttonsView.frame;
    cancelFrame.size.height = bottomSheetCancelButtonHeight;
    cancelFrame.origin.y = DeviceScreenHeight - cancelFrame.size.height - self.keyboardHeight;
    self.buttonsView.frame = cancelFrame;
    
    CGRect tableViewFrame = self.tableView.frame;
    tableViewFrame.size.height = DeviceScreenHeight - cancelFrame.size.height - self.keyboardHeight;
    self.tableView.frame = tableViewFrame;
}

- (void)dismiss:(id)sender
{
    [self.messageDelegate refreshData];
    [super dismiss:sender];
}

- (void) setupButtons
{
    CGFloat buttonWidth = self.buttonsView.frame.size.width / 2 - 21;
    self.doneButton.frame = CGRectMake(self.buttonsView.frame.size.width - 16.0 - buttonWidth, 4.0, buttonWidth, 32.0);
    self.doneButton.backgroundColor = [UIColor colorWithRed:0 green:0.48 blue:1 alpha:1];
    self.doneButton.layer.cornerRadius = 4;
    self.doneButton.titleLabel.font = [UIFont systemFontOfSize:15.0];
    
    self.cancelButton.frame = CGRectMake(16.0 , 4.0, buttonWidth, 32.0);
    self.cancelButton.autoresizingMask = UIViewAutoresizingNone;
    self.cancelButton.backgroundColor = [UIColor colorWithRed:0.82 green:0.82 blue:0.84 alpha:1];
    self.cancelButton.layer.cornerRadius = 4;
}

-(void)applyLocalization
{
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_close") forState:UIControlStateNormal];
    [self.doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
}

@end
