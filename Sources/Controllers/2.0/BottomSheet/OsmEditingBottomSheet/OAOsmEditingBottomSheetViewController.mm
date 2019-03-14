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
#import "OAMenuSimpleCell.h"
#import "OASwitchTableViewCell.h"
#import "OADividerCell.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "OAIAPHelper.h"
#import "OAMapPanelViewController.h"
#import "OARootViewController.h"
#import "OAEntity.h"
#import "OAOpenStreetMapLocalUtil.h"
#import "MaterialTextFields.h"
#import "OAEntity.h"
#import "OAPOI.h"
#import "OAEditPOIData.h"
#import "OASizes.h"

#define kButtonsDividerTag 150

@interface OAOsmEditingBottomSheetScreen () <UITextViewDelegate, MDCMultilineTextInputLayoutDelegate>

@end

@implementation OAOsmEditingBottomSheetScreen
{
    OsmAndAppInstance _app;
    OAOsmEditingBottomSheetViewController *vwController;
    NSArray* _data;
    
    NSMutableArray *_floatingTextFieldControllers;
    id<OAOpenStreetMapUtilsProtocol> _editingUtil;
    
    UIButton *_doneButton;
    
    BOOL _closeChangeset;
}

@synthesize tableData, tblView;

- (id) initWithTable:(UITableView *)tableView viewController:(OAOsmEditingBottomSheetViewController *)viewController param:(id)param type:(EOAEditingBottomSheetType)type
{
    self = [super init];
    if (self)
    {
        _editingType = type;
        _editingUtil = param;
        [self initOnConstruct:tableView viewController:viewController];
        _floatingTextFieldControllers = [NSMutableArray new];
        _closeChangeset = NO;
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
    _doneButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_doneButton addTarget:self action:@selector(doneButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [vwController.cancelButton setTitle:OALocalizedString(@"shared_string_close") forState:UIControlStateNormal];
    [_doneButton setTitle:_editingType == UPLOAD_EDIT ?
     OALocalizedString(@"shared_string_upload") : OALocalizedString(@"shared_string_delete") forState:UIControlStateNormal];
    [vwController.buttonsView addSubview:_doneButton];
    [[self.vwController.buttonsView viewWithTag:kButtonsDividerTag] removeFromSuperview];
    [self setupButtons];
    NSMutableArray *arr = [NSMutableArray array];
    switch (_editingType) {
        case DELETE_EDIT:
        {
            [arr addObject:@{
                             @"type" : @"OABottomSheetHeaderCell",
                             @"title" : OALocalizedString(@"osm_confirm_delete"),
                             @"description" : @""
                             }];
            [arr addObject:@{
                             @"type" : @"OATextInputFloatingCell",
                             @"cell" : [self getInputCellWithHint:OALocalizedString(@"osm_alert_message") text:[NSString stringWithFormat:@"%@ %@",
                                                                                                                OALocalizedString(@"shared_string_delete"),
                                                                                                                ((OAOsmEditingBottomSheetViewController *) self.vwController).getPoiData.getPoiTypeString]]
                             }];
            if (![_editingUtil isKindOfClass:OAOpenStreetMapLocalUtil.class])
            {
                [arr addObject:@{
                                 @"type" : @"OASwitchCell",
                                 @"name" : @"close_changeset",
                                 @"title" : OALocalizedString(@"osm_close_changeset"),
                                 @"value" : @(_closeChangeset)
                                 }];
            }
            
            break;
        }
        case UPLOAD_EDIT:
        {
            break;
        }
    }
    _data = [NSArray arrayWithArray:arr];
}

- (void) setupButtons
{
    CGFloat buttonWidth = self.vwController.buttonsView.frame.size.width / 2 - 21;
    _doneButton.frame = CGRectMake(16.0 , 4.0, buttonWidth, 42.0);
    _doneButton.backgroundColor = [UIColor colorWithRed:0 green:0.48 blue:1 alpha:1];
    _doneButton.layer.cornerRadius = 9;
    _doneButton.titleLabel.font = [UIFont systemFontOfSize:15.0];
    [_doneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    
    vwController.cancelButton.frame = CGRectMake(self.vwController.buttonsView.frame.size.width - 16.0 - buttonWidth, 4.0, buttonWidth, 42.0);
    vwController.cancelButton.autoresizingMask = UIViewAutoresizingNone;
    vwController.cancelButton.backgroundColor = [UIColor colorWithRed:0.82 green:0.82 blue:0.84 alpha:1];
    vwController.cancelButton.layer.cornerRadius = 9;
}

- (OATextInputFloatingCell *)getInputCellWithHint:(NSString *)hint text:(NSString *)text
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATextInputFloatingCell" owner:self options:nil];
    OATextInputFloatingCell *resultCell = (OATextInputFloatingCell *)[nib objectAtIndex:0];
    resultCell.backgroundColor = [UIColor clearColor];
    MDCMultilineTextField *textField = resultCell.inputField;
    textField.underline.hidden = YES;
    textField.placeholder = hint;
    [textField.textView setText:text];
    textField.textView.delegate = self;
    textField.layoutDelegate = self;
    textField.userInteractionEnabled = NO;
    textField.font = [UIFont systemFontOfSize:17.0];
    textField.clearButton.imageView.tintColor = UIColorFromRGB(color_icon_color);
    [textField.clearButton setImage:[[UIImage imageNamed:@"ic_custom_clear_field"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [textField.clearButton setImage:[[UIImage imageNamed:@"ic_custom_clear_field"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateHighlighted];
    if (!_floatingTextFieldControllers)
        _floatingTextFieldControllers = [NSMutableArray new];
    
    MDCTextInputControllerFilled *fieldController = [[MDCTextInputControllerFilled alloc] initWithTextInput:textField];
    fieldController.borderFillColor = [UIColor colorWithRed:0.82 green:0.82 blue:0.84 alpha:1];
    fieldController.disabledColor = [UIColor blackColor];
    fieldController.inlinePlaceholderFont = [UIFont systemFontOfSize:16.0];
    fieldController.textInput.textInsetsMode = MDCTextInputTextInsetsModeIfContent;
    [_floatingTextFieldControllers addObject:fieldController];
    
    return resultCell;
}

-(void) doneButtonPressed:(id)sender
{
    
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
    [vwController dismiss];
}

@synthesize vwController;


#pragma mark - MDCMultilineTextInputLayoutDelegate
- (void)multilineTextField:(id<MDCMultilineTextInput> _Nonnull)multilineTextField
      didChangeContentSize:(CGSize)size
{
    [self.tblView beginUpdates];
    [self.tblView endUpdates];
}

@end

@interface OAOsmEditingBottomSheetViewController ()

@end

@implementation OAOsmEditingBottomSheetViewController
{
    EOAEditingBottomSheetType _type;
    OAEditPOIData *_poiData;
}

- (id) initWithEditingUtils:(id<OAOpenStreetMapUtilsProtocol>)editingUtil data:(OAEditPOIData *)data type:(EOAEditingBottomSheetType)type
{
    _poiData = data;
    _type = type;
    return [super initWithParam:editingUtil];
}

- (id<OAOpenStreetMapUtilsProtocol>)editingUtil
{
    return self.customParam;
}

-(OAEditPOIData *)getPoiData
{
    return _poiData;
}

- (void) setupView
{
    if (!self.screenObj)
        self.screenObj = [[OAOsmEditingBottomSheetScreen alloc] initWithTable:self.tableView viewController:self param:self.editingUtil type:_type];
    
    [super setupView];
}

-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [(OAOsmEditingBottomSheetScreen *) self.screenObj setupButtons];
    } completion:nil];
}

- (void)adjustViewHeight
{
    CGFloat bottomMargin = [OAUtilities getBottomMargin];
    if (bottomMargin == 0.0)
        return;
    
    CGRect cancelFrame = self.buttonsView.frame;
    cancelFrame.size.height = bottomSheetCancelButtonHeight + bottomMargin;
    cancelFrame.origin.y = DeviceScreenHeight - cancelFrame.size.height;
    self.buttonsView.frame = cancelFrame;
}

@end
