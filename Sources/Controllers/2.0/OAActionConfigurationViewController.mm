//
//  OAActionConfigurationViewController.m
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAActionConfigurationViewController.h"
#import "Localization.h"
#import "OAQuickActionRegistry.h"
#import "OAQuickActionFactory.h"
#import "OAQuickAction.h"
#import "OrderedDictionary.h"
#import "OATextInputCell.h"
#import "OAQuickActionRegistry.h"
#import "OASizes.h"
#import "OAColors.h"
#import "OASwitchTableViewCell.h"
#import "OATextInputIconCell.h"
#import "OAIconTitleValueCell.h"
#import "OAEditColorViewController.h"
#import "OADefaultFavorite.h"
#import "OAEditGroupViewController.h"
#import "OANativeUtilities.h"
#import "OsmAndApp.h"
#import "OABottomSheetActionCell.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>

#define kTextInputCell @"OATextInputCell"
#define kCellTypeSwitch @"OASwitchTableViewCell"
#define kTextInputIconCell @"OATextInputIconCell"
#define kIconTitleValueCell @"OAIconTitleValueCell"
#define kBottomSheetActionCell @"OABottomSheetActionCell"

@interface OAActionConfigurationViewController () <UITableViewDelegate, UITableViewDataSource, OAEditColorViewControllerDelegate, OAEditGroupViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *backBtn;
@property (weak, nonatomic) IBOutlet UIView *buttonBackgroundView;
@property (weak, nonatomic) IBOutlet UIButton *btnApply;

@end

@implementation OAActionConfigurationViewController
{
    OAQuickAction *_action;
    MutableOrderedDictionary<NSString *, NSArray<NSDictionary *> *> *_data;
    
    OAQuickActionRegistry *_actionRegistry;
    
    BOOL _isNew;
    
    OAEditColorViewController *_colorController;
    OAEditGroupViewController *_groupController;
}

-(instancetype) initWithAction:(OAQuickAction *)action isNew:(BOOL)isNew
{
    self = [super init];
    if (self) {
        _action = action;
        _isNew = isNew;
        _actionRegistry = [OAQuickActionRegistry sharedInstance];
        [self commonInit];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupView];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.backBtn setImage:[[UIImage imageNamed:@"ic_navbar_chevron"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.backBtn setTintColor:UIColor.whiteColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self applySafeAreaMargins];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

-(void) commonInit
{
    MutableOrderedDictionary *dataModel = [[MutableOrderedDictionary alloc] init];
    [dataModel setObject:@[@{
                           @"type" : kTextInputCell,
                           @"title" : _action.getName
                           }] forKey:OALocalizedString(@"quick_action_name_str")];
    
    OrderedDictionary *actionSpecific = _action.getUIModel;
    [dataModel addEntriesFromDictionary:actionSpecific];
    _data = [MutableOrderedDictionary dictionaryWithDictionary:dataModel];
}

-(void) setupView
{
    _btnApply.layer.cornerRadius = 9.0;
}

- (void)applyLocalization
{
    _titleView.text = _action.getName;
}

-(UIView *) getTopView
{
    return _navBarView;
}

-(UIView *) getMiddleView
{
    return _tableView;
}

- (UIView *)getBottomView
{
    return _buttonBackgroundView;
}

-(CGFloat) getToolBarHeight
{
    return customSearchToolBarHeight;
}

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    NSString *key = _data.allKeys[indexPath.section];
    return _data[key][indexPath.row];
}

-(void)onNameChanged:(UITextView *)textView
{
    [_action setName:textView.text];
}

-(void)onTextFieldChanged:(UITextView *)textView
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:textView.tag & 0x3FF inSection:textView.tag >> 10];
    NSMutableDictionary *item = [NSMutableDictionary dictionaryWithDictionary:[self getItem:indexPath]];
    NSString *key = _data.allKeys[indexPath.section];
    NSMutableArray *arr = [NSMutableArray arrayWithArray:_data[key]];
    [item setObject:textView.text forKey:@"title"];
    [arr setObject:item atIndexedSubscript:indexPath.row];
    [_data setObject:[NSArray arrayWithArray:arr] forKey:key];
}

- (IBAction)backPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)applyPressed:(id)sender
{
    if (![_action fillParams:_data])
        return;
    
    if ([_actionRegistry isNameUnique:_action])
    {
        if (_isNew)
            [_actionRegistry addQuickAction:_action];
        else
            [_actionRegistry updateQuickAction:_action];
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
    else
    {
        _action = [_actionRegistry generateUniqueName:_action];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:[NSString stringWithFormat:OALocalizedString(@"quick_action_name_alert"), _action.getName] preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            if (_isNew)
                [_actionRegistry addQuickAction:_action];
            else
                [_actionRegistry updateQuickAction:_action];
            [self.navigationController popToRootViewControllerAnimated:YES];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
    [_actionRegistry.quickActionListChangedObservable notifyEvent];
}

- (void)applyParameter:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        UISwitch *sw = (UISwitch *)sender;
        BOOL isChecked = sw.on;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
        NSMutableDictionary *item = [NSMutableDictionary dictionaryWithDictionary:[self getItem:indexPath]];
        [item setObject:@(isChecked) forKey:@"value"];
        NSString *key = _data.allKeys[indexPath.section];
        NSMutableArray *arr = [NSMutableArray arrayWithArray:_data[key]];
        [arr setObject:item atIndexedSubscript:indexPath.row];
        [_data setObject:[NSArray arrayWithArray:arr] forKey:key];
    }
}

- (NSArray *)getItemGroups
{
    return [[OANativeUtilities QListOfStringsToNSMutableArray:[OsmAndApp instance].favoritesCollection->getGroups().toList()] copy];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"key"] isEqualToString:@"category_name"])
    {
        _groupController = [[OAEditGroupViewController alloc] initWithGroupName:item[@"value"] groups:[self getItemGroups]];
        _groupController.delegate = self;
        [self.navigationController pushViewController:_groupController animated:YES];
    }
    else if ([item[@"key"] isEqualToString:@"category_color"])
    {
        OAFavoriteColor *favCol = [OADefaultFavorite builtinColors][[item[@"color"] integerValue]];
        _colorController = [[OAEditColorViewController alloc] initWithColor:favCol.color];
        _colorController.delegate = self;
        [self.navigationController pushViewController:_colorController animated:YES];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:kTextInputCell])
    {
        OATextInputCell* cell = [tableView dequeueReusableCellWithIdentifier:kTextInputCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kTextInputCell owner:self options:nil];
            cell = (OATextInputCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            cell.inputField.text = item[@"title"];
            [cell.inputField addTarget:self action:@selector(onNameChanged:) forControlEvents:UIControlEventEditingChanged];
        }
        
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kCellTypeSwitch])
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
            [cell.textView setText: item[@"title"]];
            cell.switchView.on = [item[@"value"] boolValue];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kTextInputIconCell])
    {
        OATextInputIconCell* cell = [tableView dequeueReusableCellWithIdentifier:kTextInputIconCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kTextInputIconCell owner:self options:nil];
            cell = (OATextInputIconCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            cell.inputField.text = item[@"title"];
            cell.inputField.placeholder = item[@"hint"];
            cell.inputField.tag = indexPath.section << 10 | indexPath.row;
            [cell.inputField addTarget:self action:@selector(onTextFieldChanged:) forControlEvents:UIControlEventEditingChanged];
            NSString *imgName = item[@"img"];
            if (imgName && imgName.length > 0)
            {
                [cell.iconView setImage:[[UIImage imageNamed:imgName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
                cell.iconView.tintColor = UIColorFromRGB(color_text_footer);
            }
        }
        
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kIconTitleValueCell])
    {
        static NSString* const identifierCell = kIconTitleValueCell;
        OAIconTitleValueCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kIconTitleValueCell owner:self options:nil];
            cell = (OAIconTitleValueCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
            OAFavoriteColor *color = [OADefaultFavorite builtinColors][[item[@"color"] integerValue]];
            if (item[@"img"])
            {
                cell.leftImageView.layer.cornerRadius = 0.;
                cell.leftImageView.image = [[UIImage imageNamed:item[@"img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                cell.leftImageView.tintColor = color.color;
            }
            else
            {
                cell.leftImageView.layer.cornerRadius = cell.leftImageView.frame.size.height / 2;
                cell.leftImageView.backgroundColor = color.color;
            }
            
            cell.descriptionView.text = item[@"value"];
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
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.allKeys.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *key = _data.allKeys[section];
    NSString *footer = _data[key].lastObject[@"footer"];
    return _data[key].count - (footer != nil ? 1 : 0);
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *header = _data.allKeys[section];
    if ([header hasPrefix:kSectionNoName])
        return nil;
    
    return header;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSArray *data = _data[_data.allKeys[section]];
    NSString *footer = data.lastObject[@"footer"];
    return footer;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:kIconTitleValueCell])
    {
        return [OAIconTitleValueCell getHeight:item[@"title"] value:item[@"value"] cellWidth:tableView.bounds.size.width];
    }
    else if ([item[@"type"] isEqualToString:kBottomSheetActionCell])
    {
        return [OABottomSheetActionCell getHeight:item[@"title"] value:nil cellWidth:tableView.bounds.size.width];
    }
    return 44.0;
}

#pragma mark - Keyboard Notifications

- (void) keyboardWillShow:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    NSValue *keyboardBoundsValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGFloat keyboardHeight = [keyboardBoundsValue CGRectValue].size.height;
    
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        _buttonBackgroundView.frame = CGRectMake(0, DeviceScreenHeight - keyboardHeight - 44.0, _buttonBackgroundView.frame.size.width, 44.0);
        [self applyHeight:32.0 cornerRadius:4.0 toView:_btnApply];
        [[self view] layoutIfNeeded];
    } completion:nil];
}

- (void) keyboardWillHide:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        [self applySafeAreaMargins];
        [self applyHeight:42.0 cornerRadius:9.0 toView:_btnApply];
        [[self view] layoutIfNeeded];
    } completion:nil];
}

-(void) applyHeight:(CGFloat)height cornerRadius:(CGFloat)radius toView:(UIView *)button
{
    CGRect buttonFrame = button.frame;
    buttonFrame.size.height = height;
    button.frame = buttonFrame;
    button.layer.cornerRadius = radius;
}

#pragma mark - OAEditColorViewControllerDelegate

- (void)colorChanged
{
    NSString *key = _data.allKeys.lastObject;
    NSArray *colorItems = _data[key];
    NSMutableArray *newItems = [NSMutableArray new];
    for (NSDictionary *item in colorItems)
    {
        if (!item[@"footer"])
        {
            NSMutableDictionary *mutableItem = [NSMutableDictionary dictionaryWithDictionary:item];
            [mutableItem setObject:@(_colorController.colorIndex) forKey:@"color"];
            if ([item[@"key"] isEqualToString:@"category_color"])
            {
                OAFavoriteColor *col = [OADefaultFavorite builtinColors][_colorController.colorIndex];
                [mutableItem setObject:col.name forKey:@"value"];
            }
            [newItems addObject:[NSDictionary dictionaryWithDictionary:mutableItem]];
        }
        else
        {
            [newItems addObject:item];
        }
    }
    [_data setObject:[NSArray arrayWithArray:newItems] forKey:key];
    [self.tableView reloadData];
}

#pragma mark - OAEditGroupViewControllerDelegate

- (void) groupChanged
{
    NSString *key = _data.allKeys.lastObject;
    NSArray *items = _data[key];
    NSMutableArray *newItems = [NSMutableArray new];
    for (NSDictionary *item in items)
    {
        if ([item[@"key"] isEqualToString:@"category_name"])
        {
            NSMutableDictionary *mutableItem = [NSMutableDictionary dictionaryWithDictionary:item];
            [mutableItem setObject:_groupController.groupName forKey:@"value"];
            [newItems addObject:[NSDictionary dictionaryWithDictionary:mutableItem]];
        }
        else
        {
            [newItems addObject:item];
        }
    }
    [_data setObject:[NSArray arrayWithArray:newItems] forKey:key];
    [self.tableView reloadData];
}

@end
