//
//  OAFavoriteViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 01/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAFavoriteViewController.h"
#import "OsmAndApp.h"
#import "OAAppData.h"
#import "OALog.h"
#import "OAFavoriteGroupViewController.h"
#import "OAFavoriteColorViewController.h"
#import "OAEditDescriptionViewController.h"
#import "OADefaultFavorite.h"
#import "OARootViewController.h"
#import "OANativeUtilities.h"
#import "OAGPXListViewController.h"
#import "OAFavoriteListViewController.h"
#import "OAUtilities.h"
#import <UIAlertView+Blocks.h>

#import "OATextLineViewCell.h"
#import "OAColorViewCell.h"
#import "OAGroupViewCell.h"
#import "OATextViewTableViewCell.h"
#import "OATextMultiViewCell.h"

#include <OsmAndCore.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/Utilities.h>
#include "Localization.h"


@interface OAFavoriteViewController () <OAFavoriteColorViewControllerDelegate, OAFavoriteGroupViewControllerDelegate, OAEditDescriptionViewControllerDelegate, UITextFieldDelegate>

@end

@implementation OAFavoriteViewController
{
    OsmAnd::PointI _newTarget31;
    
    BOOL _showFavoriteOnExit;
    BOOL _wasShowingFavorite;
    
    NSString *_favName;
    NSInteger _colorIndex;
    NSString *_groupName;
    NSString *_favDescription;
    
    OAFavoriteColorViewController *_colorController;
    OAFavoriteGroupViewController *_groupController;
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
    return isViewVisible && self.editing;
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

- (void)cancelPressed
{
    _backButtonPressed = YES;
    
    // back / cancel
    OsmAndAppInstance app = [OsmAndApp instance];
    if (self.newFavorite)
    {
        app.favoritesCollection->removeFavoriteLocation(self.favorite.favorite);
        [app saveFavoritesToPermamentStorage];
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
    if (_colorIndex != -1)
        [[NSUserDefaults standardUserDefaults] setInteger:_colorIndex forKey:kFavoriteDefaultColorKey];
    
    [[NSUserDefaults standardUserDefaults] setObject:_groupName forKey:kFavoriteDefaultGroupKey];
    
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
    [[[UIAlertView alloc] initWithTitle:@"" message:OALocalizedString(@"fav_remove_q") cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_no")] otherButtonItems:
      [RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_yes") action:^{
        
        OsmAndAppInstance app = [OsmAndApp instance];
        app.favoritesCollection->removeFavoriteLocation(self.favorite.favorite);
        [app saveFavoritesToPermamentStorage];
        
    }],
      nil] show];
    
}

- (id)initWithFavoriteItem:(OAFavoriteItem*)favorite
{
    self = [super init];
    if (self)
    {
        self.favorite = favorite;
        self.newFavorite = NO;
        _colorIndex = -1;
        _favName = favorite.favorite->getTitle().toNSString();
        _favDescription = favorite.favorite->getDescription().toNSString();
    }
    return self;
}

- (id)initWithLocation:(CLLocationCoordinate2D)location andTitle:(NSString*)formattedLocation
{
    self = [super init];
    if (self)
    {
        OsmAndAppInstance app = [OsmAndApp instance];
        
        _favName = formattedLocation;
        _favDescription = formattedLocation;
        _favDescription = @"";
        _colorIndex = -1;
        self.favorite = nil;
        self.location = location;
        self.newFavorite = YES;
        
        // Create favorite
        OsmAnd::PointI locationPoint;
        locationPoint.x = OsmAnd::Utilities::get31TileNumberX(location.longitude);
        locationPoint.y = OsmAnd::Utilities::get31TileNumberY(location.latitude);
        
        QString title = QString::fromNSString(formattedLocation);
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        int defaultColor = 0;
        if ([userDefaults objectForKey:kFavoriteDefaultColorKey])
            defaultColor = [userDefaults integerForKey:kFavoriteDefaultColorKey];
        
        NSString *groupName;
        if ([userDefaults objectForKey:kFavoriteDefaultGroupKey])
            groupName = [userDefaults stringForKey:kFavoriteDefaultGroupKey];
        
        OAFavoriteColor *favCol = [OADefaultFavorite builtinColors][defaultColor];
        
        UIColor* color_ = favCol.color;
        CGFloat r,g,b,a;
        [color_ getRed:&r
                 green:&g
                  blue:&b
                 alpha:&a];
        
        QString group;
        if (groupName)
            group = QString::fromNSString(groupName);
        else
            group = QString::null;
        
        OAFavoriteItem* fav = [[OAFavoriteItem alloc] init];
        fav.favorite = app.favoritesCollection->createFavoriteLocation(locationPoint,
                                                                       title,
                                                                       group,
                                                                       OsmAnd::FColorRGB(r,g,b));
        self.favorite = fav;
        [app saveFavoritesToPermamentStorage];
    }
    return self;
}

- (void)applyLocalization
{
    self.titleView.text = OALocalizedString(@"favorite");
    [self.buttonOK setTitle:OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    dy = 0.0;
    
    [self setupView];
    
    self.tableView.backgroundColor = UIColorFromRGB(0xf2f2f2);
    
    OAAppSettings* settings = [OAAppSettings sharedManager];
    _wasShowingFavorite = settings.mapSettingShowFavorites;
    [settings setMapSettingShowFavorites:YES];
    
    [self registerForKeyboardNotifications];
}

-(void)dealloc
{
    [self unregisterKeyboardNotifications];
}

- (void)setupColor
{
    // Color
    if (self.newFavorite && _colorController)
    {
        _colorIndex = _colorController.colorIndex;
    }
}

- (void)setupGroup
{
    if (self.newFavorite && _groupController)
    {
        _groupName = _groupController.groupName;
    }
}


- (void)setupView
{
    CGSize s = [OAUtilities calculateTextBounds:_favDescription width:self.tableView.bounds.size.width - 38.0 font:[UIFont fontWithName:@"AvenirNext-Regular" size:14.0]];
    CGFloat h = MIN(88.0, s.height + 10.0);
    h = MAX(44.0, h);
    
    _descHeight = h;
    _descSingleLine = (s.height < 24.0);
    
    if (self.newFavorite)
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
}

- (void)didReceiveMemoryWarning {
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

- (BOOL) isFavExists:(NSString *)name
{
    for(const auto& localFavorite : [OsmAndApp instance].favoritesCollection->getFavoriteLocations())
        if ((localFavorite != self.favorite.favorite) &&
            [name isEqualToString:localFavorite->getTitle().toNSString()])
        {
            return YES;
        }
    
    return NO;
}

- (NSString *) getNewFavName:(NSString *)favoriteTitle
{
    NSString *newName;
    for (int i = 2; i < 100000; i++) {
        newName = [NSString stringWithFormat:@"%@_%d", favoriteTitle, i];
        if (![self isFavExists:newName])
            break;
    }
    return newName;
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

- (BOOL)doSave
{
    if (_favName)
        self.favorite.favorite->setTitle(QString::fromNSString(_favName));
    
    NSString *favoriteTitle = self.favorite.favorite->getTitle().toNSString();
    
    if ([self isFavExists:favoriteTitle])
    {
        NSString *newName = [self getNewFavName:favoriteTitle];
        
        [[[UIAlertView alloc] initWithTitle:@"" message:[NSString stringWithFormat:OALocalizedString(@"fav_exists"), favoriteTitle] cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_cancel")] otherButtonItems:
          [RIButtonItem itemWithLabel:[NSString stringWithFormat:@"%@ %@", OALocalizedString(@"add_as"), newName] action:^{
            self.favorite.favorite->setTitle(QString::fromNSString(newName));
            [self saveAndExit];
        }],
          [RIButtonItem itemWithLabel:OALocalizedString(@"fav_replace") action:^{
            for(const auto& localFavorite : [OsmAndApp instance].favoritesCollection->getFavoriteLocations())
            {
                if ((localFavorite != self.favorite.favorite) &&
                    [favoriteTitle isEqualToString:localFavorite->getTitle().toNSString()])
                {
                    [OsmAndApp instance].favoritesCollection->removeFavoriteLocation(localFavorite);
                    break;
                }
            }
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
    [[OsmAndApp instance] saveFavoritesToPermamentStorage];
    [self doExit];
}

- (void)doExit
{
    _editing = NO;
    _wasEdited = NO;
    
    [self processButtonPress];
}


- (IBAction)favoriteChangeColorClicked:(id)sender
{
    _colorController = [[OAFavoriteColorViewController alloc] initWithFavorite:self.favorite];
    _colorController.delegate = self;
    _colorController.hideToolbar = YES;
    [self.navController pushViewController:_colorController animated:YES];
}

- (IBAction)favoriteChangeGroupClicked:(id)sender
{
    _groupController = [[OAFavoriteGroupViewController alloc] initWithFavorite:self.favorite];
    _groupController.delegate = self;
    _groupController.hideToolbar = YES;
    [self.navController pushViewController:_groupController animated:YES];
}

- (IBAction)favoriteChangeDescriptionClicked:(id)sender
{
    _editDescController = [[OAEditDescriptionViewController alloc] initWithDescription:_favDescription isNew:self.newFavorite];
    _editDescController.delegate = self;
    [self.navController pushViewController:_editDescController animated:YES];
}

- (void)editFavName:(id)sender
{
    _wasEdited = YES;
    _favName = [((UITextField*)sender) text];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.editing)
        return 4;
    else
        return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const reusableIdentifierColorCell = @"OAColorViewCell";
    static NSString* const reusableIdentifierGroupCell = @"OAGroupViewCell";
    static NSString* const reusableIdentifierTextViewCell = @"OATextViewTableViewCell";
    static NSString* const reusableIdentifierTextMultiViewCell = @"OATextMultiViewCell";
    
    int index = indexPath.row;
    if (!self.editing)
        index++;
    
    switch (index)
    {
        case 0:
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
                [cell.textView setText:_favName];
                [cell.textView setPlaceholder:OALocalizedString(@"enter_fav_name")];
                [cell.textView setFont:[UIFont fontWithName:@"AvenirNext-Regular" size:16]];
                [cell.textView removeTarget:self action:NULL forControlEvents:UIControlEventEditingChanged];
                [cell.textView addTarget:self action:@selector(editFavName:) forControlEvents:UIControlEventEditingChanged];
                [cell.textView setDelegate:self];
                
                cell.textView.backgroundColor = UIColorFromRGB(0xf2f2f2);
                cell.backgroundColor = UIColorFromRGB(0xf2f2f2);
                return cell;
            }
        }
        case 1:
        {
            OAColorViewCell* cell;
            cell = (OAColorViewCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierColorCell];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAColorViewCell" owner:self options:nil];
                cell = (OAColorViewCell *)[nib objectAtIndex:0];
            }
            
            UIColor* color = [UIColor colorWithRed:self.favorite.favorite->getColor().r/255.0 green:self.favorite.favorite->getColor().g/255.0 blue:self.favorite.favorite->getColor().b/255.0 alpha:1.0];
            
            OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];
            [cell.colorIconView setImage:favCol.icon];
            [cell.descriptionView setText:favCol.name];
            
            cell.textView.text = OALocalizedString(@"fav_color");
            cell.backgroundColor = UIColorFromRGB(0xf2f2f2);

            return cell;
        }
        case 2:
        {
            OAGroupViewCell* cell;
            cell = (OAGroupViewCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierGroupCell];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAGroupViewCell" owner:self options:nil];
                cell = (OAGroupViewCell *)[nib objectAtIndex:0];
            }
            
            if (self.favorite.favorite->getGroup().isEmpty())
                [cell.descriptionView setText: OALocalizedString(@"fav_no_group")];
            else
                [cell.descriptionView setText: self.favorite.favorite->getGroup().toNSString()];

            cell.textView.text = OALocalizedString(@"fav_group");
            cell.backgroundColor = UIColorFromRGB(0xf2f2f2);

            return cell;
        }
        case 3:
        {
            OATextMultiViewCell* cell;
            cell = (OATextMultiViewCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierTextMultiViewCell];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATextMultiViewCell" owner:self options:nil];
                cell = (OATextMultiViewCell *)[nib objectAtIndex:0];
            }
            
            if (_favDescription.length == 0)
            {
                cell.textView.font = [UIFont fontWithName:@"AvenirNext-Regular" size:16.0];
                cell.textView.textContainerInset = UIEdgeInsetsMake(11,11,0,0);
                cell.textView.text = OALocalizedString(@"enter_description");
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

                cell.textView.text = _favDescription;
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
    
    switch (index)
    {
        case 0: // name
        {
            break;
        }
        case 1: // color
        {
            [self favoriteChangeColorClicked:nil];
            break;
        }
        case 2: // group
        {
            [self favoriteChangeGroupClicked:nil];
            break;
        }
        case 3: // description
        {
            [self favoriteChangeDescriptionClicked:nil];
            break;
        }
            
        default:
            break;
    }
}

#pragma mark
#pragma mark - OAFavoriteColorViewControllerDelegate

-(void)favoriteColorChanged
{
    _wasEdited = YES;
    [self setupColor];
    [self.tableView reloadData];
}

#pragma mark
#pragma mark - OAFavoriteGroupViewControllerDelegate

-(void)favoriteGroupChanged
{
    _wasEdited = YES;
    [self setupGroup];
    [self.tableView reloadData];
}

#pragma mark
#pragma mark - OAEditDescriptionViewControllerDelegate

-(void)descriptionChanged
{
    _wasEdited = YES;
    
    _favDescription = _editDescController.desc;
    self.favorite.favorite->setDescription(QString::fromNSString(_favDescription));
    [[OsmAndApp instance] saveFavoritesToPermamentStorage];
    
    [self setupView];
    [self.tableView reloadData];
    if (self.delegate)
        [self.delegate contentHeightChanged:[self contentHeight]];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (self.newFavorite && _editNameFirstTime)
    {
        [textField selectAll:nil];
    }
    _editNameFirstTime = NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)sender
{
    self.favorite.favorite->setTitle(QString::fromNSString(_favName));
    [[OsmAndApp instance] saveFavoritesToPermamentStorage];

    [sender resignFirstResponder];
    return YES;
}

@end
