//
//  OAEditTargetViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 08/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAEditTargetViewController.h"
#import "OsmAndApp.h"
#import "OAAppData.h"
#import "OALog.h"
#import "OAEditGroupViewController.h"
#import "OAEditColorViewController.h"
#import "OAEditDescriptionViewController.h"
#import "OADefaultFavorite.h"
#import "OARootViewController.h"
#import "OAUtilities.h"
#import "OAIconTextTableViewCell.h"
#import <UIAlertView+Blocks.h>

#import "OATextLineViewCell.h"
#import "OAColorViewCell.h"
#import "OAGroupViewCell.h"
#import "OATextViewTableViewCell.h"
#import "OATextMultiViewCell.h"

#include "Localization.h"


@interface OAEditTargetViewController () <OAEditColorViewControllerDelegate, OAEditGroupViewControllerDelegate, OAEditDescriptionViewControllerDelegate, UITextFieldDelegate>

@end

@implementation OAEditTargetViewController
{
    OAEditColorViewController *_colorController;
    OAEditGroupViewController *_groupController;
    OAEditDescriptionViewController *_editDescController;
    
    CGFloat _descHeight;
    BOOL _descSingleLine;
    CGFloat dy;
    
    BOOL _backButtonPressed;
    BOOL _editNameFirstTime;
}

@synthesize editing = _editing;
@synthesize wasEdited = _wasEdited;
@synthesize showingKeyboard = _showingKeyboard;

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (BOOL)hasTopToolbar
{
    return YES;
}

- (BOOL)shouldShowToolbar:(BOOL)isViewVisible;
{
    return isViewVisible;
}

- (BOOL)supportEditing
{
    return YES;
}

- (void)activateEditing
{
    if (self.editing)
        return;
    
    _editing = YES;
    _editNameFirstTime = YES;
    
    if (![self isViewLoaded])
        return;
    
    [self setupView];
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationBottom];
    [self.tableView endUpdates];
    if (self.delegate)
        [self.delegate contentHeightChanged:[self contentHeight]];
}

- (void)deleteItem
{
    // override
}

- (NSString *)getItemName
{
    return nil; // override
}

- (void)setItemName:(NSString *)name
{
    // override
}

- (BOOL) isItemExists:(NSString *)name
{
    return NO;
}

- (void)saveItemToStorage
{
    // override
}

- (void)removeExistingItemFromCollection
{
    // override
}

- (void)removeNewItemFromCollection
{
    // override
}

- (UIColor *)getItemColor
{
    return nil; // override
}

- (void)setItemColor:(UIColor *)color
{
    // override
}

- (NSString *)getItemGroup
{
    return nil; // override
}

- (void)setItemGroup:(NSString *)groupName
{
    // override
}

- (NSArray *)getItemGroups
{
    return nil; // override
}

- (NSString *)getItemDesc
{
    return nil; // override
}

- (void)setItemDesc:(NSString *)desc
{
    // override
}

- (void)cancelPressed
{
    _backButtonPressed = YES;
    
    // back / cancel
    if (self.newItem)
    {
        [self removeNewItemFromCollection];
    }
    else
    {
        if (_wasEdited)
        {
            [self doSave];
        }
        else if (self.delegate)
        {
            [self.delegate btnCancelPressed];
        }
    }
}

- (void)okPressed
{
    _backButtonPressed = NO;

    // save
    [self doSave];
}

- (void) processButtonPress
{
    if (_backButtonPressed)
    {
        if (self.delegate)
            [self.delegate btnCancelPressed];
    }
    else
    {
        if (self.delegate)
            [self.delegate btnOkPressed];
    }
    _backButtonPressed = NO;
}

- (CGFloat)contentHeight
{
    return ([self.tableView numberOfRowsInSection:0] - 1) * 44.0 + _descHeight + dy;
}

- (IBAction)deletePressed:(id)sender
{
    if (self.editing || ![self supportEditing])
        [self deleteItem];
    else
        [self activateEditing];
}

- (id)initWithItem:(id)item
{
    self = [super init];
    if (self)
    {
        self.newItem = NO;
        self.savedColorIndex = -1;
    }
    return self;
}

- (id)initWithLocation:(CLLocationCoordinate2D)location andTitle:(NSString*)formattedLocation
{
    self = [super init];
    if (self)
    {
        self.name = formattedLocation;
        self.desc = @"";
        self.savedColorIndex = -1;
        self.location = location;
        self.newItem = YES;        
    }
    return self;
}

- (void)applyLocalization
{
    [super applyLocalization];
    
    [self.buttonOK setTitle:OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    dy = 0.0;
    
    [self setupView];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;    
    self.tableView.backgroundColor = UIColorFromRGB(0xf2f2f2);
    
    [self registerForKeyboardNotifications];
}

-(void)dealloc
{
    [self unregisterKeyboardNotifications];
}

- (void)setupColor
{
    if (self.newItem && _colorController)
    {
        self.savedColorIndex = _colorController.colorIndex;
    }
}

- (void)setupGroup
{
    if (self.newItem && _groupController)
    {
        self.savedGroupName = _groupController.groupName;
    }
}


- (void)setupView
{
    CGSize s = [OAUtilities calculateTextBounds:self.desc width:self.tableView.bounds.size.width - 38.0 font:[UIFont fontWithName:@"AvenirNext-Regular" size:14.0]];
    CGFloat h = MIN(88.0, s.height + 10.0);
    h = MAX(44.0, h);
    
    _descHeight = h;
    _descSingleLine = (s.height < 24.0);
    
    if (self.newItem)
    {
        [self.buttonCancel setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
        [self.buttonCancel setImage:nil forState:UIControlStateNormal];
        [self.buttonCancel setTintColor:[UIColor whiteColor]];
        self.buttonCancel.titleEdgeInsets = UIEdgeInsetsZero;
        self.buttonCancel.imageEdgeInsets = UIEdgeInsetsZero;
        self.buttonOK.hidden = NO;
        self.deleteButton.hidden = YES;
    }
    else
    {
        [self.buttonCancel setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
        [self.buttonCancel setImage:[UIImage imageNamed:@"menu_icon_back"] forState:UIControlStateNormal];
        [self.buttonCancel setTintColor:[UIColor whiteColor]];
        self.buttonCancel.titleEdgeInsets = UIEdgeInsetsMake(0.0, 12.0, 0.0, 0.0);
        self.buttonCancel.imageEdgeInsets = UIEdgeInsetsMake(0.0, -12.0, 0.0, 0.0);
        self.buttonOK.hidden = YES;
        self.deleteButton.hidden = NO;
    }
    
    if (self.editing || ![self supportEditing])
        [self.deleteButton setImage:[UIImage imageNamed:@"icon_remove"] forState:UIControlStateNormal];
    else
        [self.deleteButton setImage:[UIImage imageNamed:@"icon_edit"] forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// keyboard notifications register+process
- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillChangeFrameNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

- (void)unregisterKeyboardNotifications
{
    //unregister the keyboard notifications while not visible
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}
// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWillShow:(NSNotification*)aNotification
{
    CGRect keyboardFrame = [[[aNotification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect convertedFrameView = [self.contentView convertRect:self.contentView.bounds fromView:nil];
    
    CGFloat minBottom = ABS(convertedFrameView.origin.y) + 44.0;
    CGFloat keyboardTop = DeviceScreenHeight - keyboardFrame.size.height;
    
    BOOL needOffsetViews = minBottom > keyboardTop;
    
    if (needOffsetViews)
    {
        dy = minBottom - keyboardTop;
        if (self.delegate)
            [self.delegate contentHeightChanged:[self contentHeight]];
    }
    
    _showingKeyboard = YES;
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    if (dy > 0.0)
    {
        dy = 0.0;
        if (self.delegate)
            [self.delegate contentHeightChanged:[self contentHeight]];
    }
    
    _showingKeyboard = NO;
}

-(BOOL)commitChangesAndExit
{
    if (_wasEdited)
    {
        return [self doSave];
    }
    else
    {
        [self doExit];
        return YES;
    }
}

- (NSString *) getNewItemName:(NSString *)name
{
    NSString *newName;
    for (int i = 2; i < 100000; i++) {
        newName = [NSString stringWithFormat:@"%@_%d", name, i];
        if (![self isItemExists:newName])
            break;
    }
    return newName;
}

- (BOOL)doSave
{
    if (self.name)
        [self setItemName:(self.name)];
    
    NSString *title = [self getItemName];
    
    if ([self isItemExists:title])
    {
        NSString *newName = [self getNewItemName:title];
        
        [[[UIAlertView alloc] initWithTitle:@"" message:[NSString stringWithFormat:OALocalizedString(@"fav_exists"), title] cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_cancel")] otherButtonItems:
          [RIButtonItem itemWithLabel:[NSString stringWithFormat:@"%@ %@", OALocalizedString(@"add_as"), newName] action:^{
            [self setItemName:newName];
            [self saveAndExit];
        }],
          [RIButtonItem itemWithLabel:OALocalizedString(@"fav_replace") action:^{
            [self removeExistingItemFromCollection];
            [self saveAndExit];
        }],
          nil] show];
        
        return NO;
    }
    
    [self saveAndExit];
    
    return YES;
}

- (void)saveAndExit
{
    [self saveItemToStorage];
    [self doExit];
}

- (void)doExit
{
    _editing = NO;
    _wasEdited = NO;
    
    [self processButtonPress];
}

- (void)changeColorClicked
{
    _colorController = [[OAEditColorViewController alloc] initWithColor:[self getItemColor]];
    _colorController.delegate = self;
    [self.navController pushViewController:_colorController animated:YES];
}

- (void)changeGroupClicked
{
    _groupController = [[OAEditGroupViewController alloc] initWithGroupName:[self getItemGroup] groups:[self getItemGroups]];
    _groupController.delegate = self;
    [self.navController pushViewController:_groupController animated:YES];
}

- (void)changeDescriptionClicked
{
    _editDescController = [[OAEditDescriptionViewController alloc] initWithDescription:self.desc isNew:self.newItem];
    _editDescController.delegate = self;
    [self.navController pushViewController:_editDescController animated:YES];
}

- (void)editFavName:(id)sender
{
    _wasEdited = YES;
    self.name = [((UITextField*)sender) text];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.editing)
        return 4 + (self.showCoords ? 1 : 0);
    else
        return 3 + (self.showCoords ? 1 : 0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const reusableIdentifierText = @"OAIconTextTableViewCell";
    static NSString* const reusableIdentifierColorCell = @"OAColorViewCell";
    static NSString* const reusableIdentifierGroupCell = @"OAGroupViewCell";
    static NSString* const reusableIdentifierTextViewCell = @"OATextViewTableViewCell";
    static NSString* const reusableIdentifierTextMultiViewCell = @"OATextMultiViewCell";
    
    int index = indexPath.row;
    if (!self.editing)
        index++;
    if (!self.showCoords)
        index++;
    
    if (!self.editing && self.showCoords && index == 1)
        index = 0;
    
    switch (index)
    {
        case 0:
        {
            OAIconTextTableViewCell* cell;
            cell = (OAIconTextTableViewCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierText];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextCell" owner:self options:nil];
                cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
                cell.backgroundColor = UIColorFromRGB(0xf2f2f2);
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.arrowIconView.hidden = YES;
                CGRect frame = CGRectMake(15.0, cell.textView.frame.origin.y, cell.textView.frame.size.width, cell.textView.frame.size.height);
                cell.textView.frame = frame;
            }
            cell.textView.text = self.formattedCoords;
            
            return cell;
        }
        case 1:
        {
            OATextViewTableViewCell* cell;
            cell = (OATextViewTableViewCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierTextViewCell];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATextViewCell" owner:self options:nil];
                cell = (OATextViewTableViewCell *)[nib objectAtIndex:0];
                cell.textView.frame = CGRectMake(15.0, 0, DeviceScreenWidth - 20.0, 44.0);
            }
            
            if (cell)
            {
                [cell.textView setText:self.name];
                [cell.textView setPlaceholder:OALocalizedString(@"enter_name")];
                [cell.textView setFont:[UIFont fontWithName:@"AvenirNext-Regular" size:16]];
                [cell.textView removeTarget:self action:NULL forControlEvents:UIControlEventEditingChanged];
                [cell.textView addTarget:self action:@selector(editFavName:) forControlEvents:UIControlEventEditingChanged];
                [cell.textView setDelegate:self];
                
                cell.textView.backgroundColor = UIColorFromRGB(0xf2f2f2);
                cell.backgroundColor = UIColorFromRGB(0xf2f2f2);
                return cell;
            }
        }
        case 2:
        {
            OAColorViewCell* cell;
            cell = (OAColorViewCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierColorCell];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAColorViewCell" owner:self options:nil];
                cell = (OAColorViewCell *)[nib objectAtIndex:0];
            }
            
            UIColor* color = [self getItemColor];
            
            OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
            [cell.colorIconView setImage:favCol.icon];
            [cell.descriptionView setText:favCol.name];
            
            cell.textView.text = OALocalizedString(@"fav_color");
            cell.backgroundColor = UIColorFromRGB(0xf2f2f2);
            
            return cell;
        }
        case 3:
        {
            OAGroupViewCell* cell;
            cell = (OAGroupViewCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierGroupCell];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAGroupViewCell" owner:self options:nil];
                cell = (OAGroupViewCell *)[nib objectAtIndex:0];
            }
            
            if ([self getItemGroup].length == 0)
                [cell.descriptionView setText: OALocalizedString(@"fav_no_group")];
            else
                [cell.descriptionView setText: [self getItemGroup]];
            
            cell.textView.text = OALocalizedString(@"fav_group");
            cell.backgroundColor = UIColorFromRGB(0xf2f2f2);
            
            return cell;
        }
        case 4:
        {
            OATextMultiViewCell* cell;
            cell = (OATextMultiViewCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierTextMultiViewCell];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATextMultiViewCell" owner:self options:nil];
                cell = (OATextMultiViewCell *)[nib objectAtIndex:0];
            }
            
            if (self.desc.length == 0)
            {
                cell.textView.font = [UIFont fontWithName:@"AvenirNext-Regular" size:16.0];
                cell.textView.textContainerInset = UIEdgeInsetsMake(11,11,0,0);
                cell.textView.text = OALocalizedString(@"enter_description");
                cell.textView.textColor = [UIColor lightGrayColor];
                cell.iconView.hidden = NO;
            }
            else
            {
                cell.textView.font = [UIFont fontWithName:@"AvenirNext-Regular" size:14.0];
                
                if (_descSingleLine)
                    cell.textView.textContainerInset = UIEdgeInsetsMake(12,11,0,35);
                else if (_descHeight > 44.0)
                    cell.textView.textContainerInset = UIEdgeInsetsMake(5,11,0,35);
                else
                    cell.textView.textContainerInset = UIEdgeInsetsMake(3,11,0,35);
                
                cell.textView.textColor = [UIColor blackColor];
                cell.textView.text = self.desc;
                cell.iconView.hidden = NO;
            }
            cell.textView.backgroundColor = UIColorFromRGB(0xf2f2f2);
            cell.backgroundColor = UIColorFromRGB(0xf2f2f2);
            
            return cell;
        }
            
        default:
            break;
    }
    
    return nil;
}



#pragma mark - UITableViewDelegate


-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int index = indexPath.row;
    if (!self.editing)
        index++;
    if (!self.showCoords)
        index++;
    
    if (index == 3) // description
        return _descHeight;
    else
        return 44.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    int index = indexPath.row;
    if (!self.editing)
        index++;
    if (!self.showCoords)
        index++;
    
    switch (index)
    {
        case 0: // coords
        {
            break;
        }
        case 1: // name
        {
            break;
        }
        case 2: // color
        {
            [self changeColorClicked];
            break;
        }
        case 3: // group
        {
            [self changeGroupClicked];
            break;
        }
        case 4: // description
        {
            [self changeDescriptionClicked];
            break;
        }
            
        default:
            break;
    }
}

#pragma mark
#pragma mark - OAEditColorViewControllerDelegate

-(void)colorChanged
{
    OAFavoriteColor *favCol = [[OADefaultFavorite builtinColors] objectAtIndex:_colorController.colorIndex];
    [self setItemColor:favCol.color];
    
    _wasEdited = YES;
    [self setupColor];
    [self.tableView reloadData];
}

#pragma mark
#pragma mark - OAEditGroupViewControllerDelegate

-(void)groupChanged
{
    [self setItemGroup:_groupController.groupName];
    
    _wasEdited = YES;
    [self setupGroup];
    [self.tableView reloadData];
}

#pragma mark
#pragma mark - OAEditDescriptionViewControllerDelegate

-(void)descriptionChanged
{
    _wasEdited = YES;
    
    self.desc = _editDescController.desc;
    [self setItemDesc:self.desc];
    
    [self setupView];
    [self.tableView reloadData];
    if (self.delegate)
        [self.delegate contentHeightChanged:[self contentHeight]];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (self.newItem && _editNameFirstTime)
    {
        [textField selectAll:nil];
    }
    _editNameFirstTime = NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)sender
{
    [self setItemName:self.name];
    [self saveItemToStorage];
    
    [sender resignFirstResponder];
    return YES;
}

@end
