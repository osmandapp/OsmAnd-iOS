//
//  OAAdvancedEditingViewController.m
//  OsmAnd
//
//  Created by Paul on 3/27/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAAdvancedEditingViewController.h"
#import "OAOsmEditingViewController.h"
#import "OATextInputFloatingCell.h"
#import "OATextInputFloatingCellWithIcon.h"
#import "OAButtonCell.h"
#import "OAEditPOIData.h"
#import "Localization.h"
#import "OAColors.h"
#import "MaterialTextFields.h"
#import "OAOSMSettings.h"
#import "OAEditPOIData.h"
#import "OAPOIType.h"
#import "OAPOICategory.h"

@interface OAAdvancedEditingViewController () <UITextViewDelegate, MDCMultilineTextInputLayoutDelegate>

@end

@implementation OAAdvancedEditingViewController
{
    OAEditPOIData *_poiData;
    id<OAOsmEditingDataProtocol> _dataProvider;
    
    NSMutableArray *_floatingTextFieldControllers;
    
    NSMutableArray *_fieldPairs;
    NSMutableArray *_tags;
    
    BOOL _isKeyboardShown;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [[OAAdvancedEditingViewController alloc] initWithNibName:@"OAAdvancedEditingViewController" bundle:nil];
    if (self)
    {
        self.view.frame = frame;
    }
    return self;
}

-(void) setDataProvider:(id<OAOsmEditingDataProtocol>)provider
{
    _dataProvider = provider;
}

- (OATextInputFloatingCell *)getInputCellWithHint:(NSString *)hint text:(NSString *)text
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATextInputFloatingCell" owner:self options:nil];
    OATextInputFloatingCell *resultCell = (OATextInputFloatingCell *)[nib objectAtIndex:0];
    resultCell.userInteractionEnabled = NO;
    MDCMultilineTextField *textField = resultCell.inputField;
    [textField.underline removeFromSuperview];
    textField.placeholder = hint;
    [textField.textView setText:text];
    textField.font = [UIFont systemFontOfSize:17.0];
    if (!_floatingTextFieldControllers)
        _floatingTextFieldControllers = [NSMutableArray new];
    
    MDCTextInputControllerUnderline *fieldController = [[MDCTextInputControllerUnderline alloc] initWithTextInput:textField];
    fieldController.inlinePlaceholderFont = [UIFont systemFontOfSize:16.0];
    fieldController.floatingPlaceholderActiveColor = fieldController.floatingPlaceholderNormalColor;
    fieldController.textInput.textInsetsMode = MDCTextInputTextInsetsModeIfContent;
    [_floatingTextFieldControllers addObject:fieldController];
    return resultCell;
}

- (OATextInputFloatingCellWithIcon *)getInputCellWithHint:(NSString *)hint text:(NSString *)text indexPath:(NSIndexPath *)indexPath iconName:(NSString *)iconName
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATextInputFloatingCellWithIcon" owner:self options:nil];
    OATextInputFloatingCellWithIcon *resultCell = (OATextInputFloatingCellWithIcon *)[nib objectAtIndex:0];
    long tag = indexPath.section << 10 | indexPath.row;
    resultCell.separatorInset = UIEdgeInsetsMake(0.0, 44.0, 0.0, 0.0);
    if (iconName.length > 0)
    {
        [resultCell.buttonView setImage:[UIImage imageNamed:iconName] forState:UIControlStateNormal];
        resultCell.buttonView.tag = tag;
        [resultCell.buttonView addTarget:self action:@selector(deleteSectionPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    else
        resultCell.buttonView.hidden = YES;
    MDCMultilineTextField *textField = resultCell.textField;
    [textField.underline removeFromSuperview];
    textField.placeholder = hint;
    [textField.textView setText:text];
    textField.textView.delegate = self;
    textField.layoutDelegate = self;
    textField.textView.tag = tag;
    textField.clearButton.tag = tag;
    [textField.clearButton addTarget:self action:@selector(clearButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    textField.font = [UIFont systemFontOfSize:17.0];
    textField.clearButton.imageView.tintColor = UIColorFromRGB(color_icon_color);
    [textField.clearButton setImage:[[UIImage imageNamed:@"ic_custom_clear_field"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [textField.clearButton setImage:[[UIImage imageNamed:@"ic_custom_clear_field"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateHighlighted];
    if (!_floatingTextFieldControllers)
        _floatingTextFieldControllers = [NSMutableArray new];
    
    MDCTextInputControllerUnderline *fieldController = [[MDCTextInputControllerUnderline alloc] initWithTextInput:textField];
    fieldController.inlinePlaceholderFont = [UIFont systemFontOfSize:16.0];
    fieldController.floatingPlaceholderActiveColor = fieldController.floatingPlaceholderNormalColor;
    fieldController.textInput.textInsetsMode = MDCTextInputTextInsetsModeIfContent;
    [_floatingTextFieldControllers addObject:fieldController];
    
    return resultCell;
}

- (OAButtonCell *) getAddTagButtonCell
{
    static NSString* const identifierCell = @"OAButtonCell";
    OAButtonCell* cell = nil;
    
    cell = [self.tableView dequeueReusableCellWithIdentifier:identifierCell];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAButtonCell" owner:self options:nil];
        cell = (OAButtonCell *)[nib objectAtIndex:0];
    }
    if (cell)
    {
        [cell.button setTitle:OALocalizedString(@"shared_string_add") forState:UIControlStateNormal];
        [cell.button addTarget:self action:@selector(addTag:) forControlEvents:UIControlEventTouchDown];
        [cell showImage:YES];
        cell.iconView.image = [UIImage imageNamed:@"ic_custom_add"];
    }
    return cell;
}

- (void) updateViewTags
{
    for (int i = 0; i < _fieldPairs.count; i++)
    {
        NSArray *pair = _fieldPairs[i];
        for (int j = 0; j < pair.count; j++)
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:j inSection:i];
            
            UITableViewCell *cell = [self getItem:indexPath];
            if ([cell isKindOfClass:OATextInputFloatingCellWithIcon.class])
            {
                long tag = indexPath.section << 10 | indexPath.row;
                OATextInputFloatingCellWithIcon *inputCell = (OATextInputFloatingCellWithIcon *)cell;
                inputCell.tag = tag;
                inputCell.buttonView.tag = tag;
                inputCell.textField.clearButton.tag = tag;
            }
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [self setupView];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void) setupView
{
    _poiData = _dataProvider.getData;
    _fieldPairs = [NSMutableArray new];
    _tags = [NSMutableArray new];
    OAPOIType *pt = _poiData.getCurrentPoiType;
    NSString *hint = OALocalizedString(@"amenity");
    NSString *value = @"";
    if (pt)
    {
        hint = pt.getEditOsmTag;
        value = pt.getEditOsmValue;
    }
    else
    {
        OAPOICategory *category = _poiData.getPoiCategory;
        if (category)
            hint = category.name;
       
        value = _poiData.getPoiTypeString;
    }
    NSArray *nameTypePair = @[
                              [self getInputCellWithHint:OALocalizedString(@"fav_name") text:[_poiData getTag:[OAOSMSettings getOSMKey:NAME]]],
                              [self getInputCellWithHint:hint text:value]
                              ];
    [_fieldPairs addObject:nameTypePair];
    
    NSString *currentPoiTypeKey = @"";
    if (pt)
        currentPoiTypeKey = pt.getEditOsmTag;
    
    [_poiData.getTagValues enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull value, BOOL * _Nonnull stop) {
        if (![key isEqualToString:POI_TYPE_TAG]
            && ![key isEqualToString:[OAOSMSettings getOSMKey:NAME]]
            && ![key hasPrefix:REMOVE_TAG_PREFIX]
            && ![key isEqualToString:currentPoiTypeKey]) {
            [_tags addObject:key];
            [self addTagPair:key value:value index:-1];
        }
    }];
    
    OAButtonCell *addButtonCell = [self getAddTagButtonCell];
    [_fieldPairs addObject:@[addButtonCell]];
    
    [self.tableView reloadData];
}

- (void) addTagPair:(NSString *)key value:(NSString *)value index:(NSInteger)index
{
    BOOL addToEnd = index == -1;
    OATextInputFloatingCellWithIcon *tagCell = [self getInputCellWithHint:OALocalizedString(@"osm_tag") text:key indexPath:[NSIndexPath indexPathForRow:0 inSection:addToEnd ? _fieldPairs.count : index] iconName:@"ic_custom_delete"];
    OATextInputFloatingCellWithIcon *valueCell = [self getInputCellWithHint:OALocalizedString(@"osm_value") text:value indexPath:[NSIndexPath indexPathForRow:1 inSection:addToEnd ? _fieldPairs.count : index] iconName:@""];
    if (addToEnd)
        [_fieldPairs addObject:@[tagCell, valueCell]];
    else
        [_fieldPairs insertObject:@[tagCell, valueCell] atIndex:index];
}

-(UITableViewCell *)getItem:(NSIndexPath *)indexPath
{
    NSArray *pair = _fieldPairs[indexPath.section];
    return pair[indexPath.row];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self getItem:indexPath];
    if ([cell isKindOfClass:OATextInputFloatingCell.class]) {
        return ((OATextInputFloatingCell *)cell).inputField.intrinsicContentSize.height;
    }
    else if ([cell isKindOfClass:OATextInputFloatingCellWithIcon.class]) {
        return ((OATextInputFloatingCellWithIcon *)cell).textField.intrinsicContentSize.height;
    }
    else if ([cell isKindOfClass:OAButtonCell.class])
    {
        OAButtonCell *buttonCell = (OAButtonCell *)cell;
        return [OAButtonCell getHeight:buttonCell.button.titleLabel.text desc:@"" cellWidth:DeviceScreenWidth - 50.0];
    }
    return 44.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self getItem:indexPath];
    [tableView deselectRowAtIndexPath:indexPath animated:true];
    if ([cell isKindOfClass:OAButtonCell.class])
        [self addTag:nil];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self getItem:indexPath];
}

#pragma mark - UITextViewDelegate

-(void)textViewDidChange:(UITextView *)textView
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:textView.tag & 0x3FF inSection:textView.tag >> 10];
    if (indexPath.section < _fieldPairs.count)
    {
        NSArray *cellPair = _fieldPairs[indexPath.section];
        BOOL tagChanged = indexPath.row == 0;
        OATextInputFloatingCellWithIcon *tagCell = cellPair[0];
        OATextInputFloatingCellWithIcon *valueCell = cellPair[1];
        if (tagChanged)
        {
            if (indexPath.section - 1 < _tags.count)
            {
                [_poiData removeTag:_tags[indexPath.section - 1]];
                if (textView.text.length > 0)
                {
                    [_poiData putTag:textView.text value:valueCell.textField.text];
                    [_tags setObject:textView.text atIndexedSubscript:indexPath.section - 1];
                }
                else
                    [_tags removeObjectAtIndex:indexPath.section - 1];
                
            }
            else if (valueCell.textField.text && valueCell.textField.text.length > 0)
            {
                if (textView.text.length > 0 && valueCell.textField.text.length > 0)
                {
                    [_tags addObject:textView.text];
                    [_poiData putTag:textView.text value:valueCell.textField.text];
                }
            }
        }
        else if (textView.text.length > 0 && tagCell.textField.text.length > 0)
            [_poiData putTag:tagCell.textField.text value:textView.text];
    }
}

#pragma mark - MDCMultilineTextInputLayoutDelegate
- (void)multilineTextField:(id<MDCMultilineTextInput> _Nonnull)multilineTextField
      didChangeContentSize:(CGSize)size
{
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _fieldPairs.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *pair = _fieldPairs[section];
    return pair.count;
}

#pragma mark - Keyboard Notifications

- (void) keyboardWillShow:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [[self tableView] contentInset];
    if (!_isKeyboardShown) {
        [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
            [[self tableView] setContentInset:UIEdgeInsetsMake(insets.top, insets.left, 44.0, insets.right)];
            //        [[self view] layoutIfNeeded];
        } completion:nil];
    }
    _isKeyboardShown = YES;
}

- (void) keyboardWillHide:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [[self tableView] contentInset];
    if (_isKeyboardShown)
    {
        [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
            [[self tableView] setContentInset:UIEdgeInsetsMake(insets.top, insets.left, 0., insets.right)];
            [[self view] layoutIfNeeded];
        } completion:nil];
    }
    _isKeyboardShown = NO;
}

-(void) clearButtonPressed:(UIButton *)sender
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag & 0x3FF inSection:sender.tag >> 10];
    NSArray *pair = _fieldPairs[indexPath.section];
    NSString *oldKey = indexPath.row == 0 ? _tags[indexPath.section - 1] : ((OATextInputFloatingCellWithIcon *)pair[0]).textField.text;
    [_poiData removeTag:oldKey];
    [_tags removeObjectAtIndex:indexPath.section - 1];
}

-(void) deleteSectionPressed:(UIButton *)sender
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag & 0x3FF inSection:sender.tag >> 10];
    [self.tableView beginUpdates];
    NSArray *pair = _fieldPairs[indexPath.section];
    OATextInputFloatingCellWithIcon *tagCell = pair[0];
    NSString *tagName = tagCell.textField.text;
    if (tagName && tagName.length > 0)
        [_tags removeObjectAtIndex:indexPath.section - 1];
    
    [_poiData removeTag:tagName];
    [_fieldPairs removeObjectAtIndex:indexPath.section];
    [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    [self updateViewTags];
}

-(void) addTag:(UIButton *)sender
{
    NSInteger sectionNumber = _fieldPairs.count - 1;
    [self.tableView beginUpdates];
    [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionNumber] withRowAnimation:UITableViewRowAnimationFade];
    [self addTagPair:@"" value:@"" index:sectionNumber];
    [self.tableView endUpdates];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:_fieldPairs.count - 1] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

@end
