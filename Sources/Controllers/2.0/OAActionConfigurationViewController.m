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

#define kTextInputCell @"OATextInputCell"

@interface OAActionConfigurationViewController () <UITableViewDelegate, UITableViewDataSource>
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
    OrderedDictionary<NSString *, NSArray<NSDictionary *> *> *_data;
    
    OAQuickActionRegistry *_actionRegistry;
    
    BOOL _isNew;
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
    _data = [OrderedDictionary dictionaryWithDictionary:dataModel];
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

- (IBAction)backPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)applyPressed:(id)sender
{
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

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
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
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.allKeys.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *key = _data.allKeys[section];
    return _data[key].count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return _data.allKeys[section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0;
}

#pragma mark - Keyboard Notifications

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

@end
