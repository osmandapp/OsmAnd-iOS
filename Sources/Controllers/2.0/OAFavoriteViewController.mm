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

@interface OAFavoriteViewController () <OAFavoriteColorViewControllerDelegate, OAFavoriteGroupViewControllerDelegate>

@end

@implementation OAFavoriteViewController
{
    OsmAnd::PointI _newTarget31;
    
    EFavoriteAction _favAction;
    
    CGFloat contentOriginY;
    CGFloat dy;
    
    BOOL isAdjustingVews;
    
    BOOL _showFavoriteOnExit;
    BOOL _wasShowingFavorite;
    BOOL _deleteFavorite;
    BOOL _wasEdited;
    
    NSInteger _colorIndex;
    NSString *_groupName;
    
    OAFavoriteColorViewController *_colorController;
    OAFavoriteGroupViewController *_groupController;
    
    CGFloat _descHeight;
    BOOL _descSingleLine;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (BOOL)hasTopToolbar
{
    return YES;
}

- (BOOL)showTopToolbarWithFullMenuOnly
{
    return YES;
}

- (void)cancelPressed
{
    // back / cancel
    OsmAndAppInstance app = [OsmAndApp instance];
    if (self.newFavorite)
    {
        app.favoritesCollection->removeFavoriteLocation(self.favorite.favorite);
        [app saveFavoritesToPermamentStorage];
        if (self.delegate)
            [self.delegate btnCancelPressed];
    }
    else
    {
        if (_wasEdited)
            [self doSave:NO];
        else if (self.delegate)
                [self.delegate btnCancelPressed];
    }
}

- (void)okPressed
{
    // save
    if (_colorIndex != -1)
        [[NSUserDefaults standardUserDefaults] setInteger:_colorIndex forKey:kFavoriteDefaultColorKey];
    
    [[NSUserDefaults standardUserDefaults] setObject:_groupName forKey:kFavoriteDefaultGroupKey];
    
    [self doSave:YES];
}

- (CGFloat)contentHeight
{
    return ([self.tableView numberOfRowsInSection:0] - 1) * 44.0 + _descHeight;
}

- (IBAction)deletePressed:(id)sender
{
    [[[UIAlertView alloc] initWithTitle:@"" message:OALocalizedString(@"fav_remove_q") cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_no")] otherButtonItems:
      [RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_yes") action:^{
        
        OsmAndAppInstance app = [OsmAndApp instance];
        app.favoritesCollection->removeFavoriteLocation(self.favorite.favorite);
        [app saveFavoritesToPermamentStorage];
        _deleteFavorite = YES;
        
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
        _favAction = kFavoriteActionNone;
        _colorIndex = -1;
    }
    return self;
}

- (id)initWithLocation:(CLLocationCoordinate2D)location andTitle:(NSString*)formattedLocation
{
    self = [super init];
    if (self)
    {
        OsmAndAppInstance app = [OsmAndApp instance];
        
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
    if (self.newFavorite)
        [self.buttonCancel setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    else
        [self.buttonCancel setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
    
    [self.buttonOK setTitle:OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self setupView];

    if (self.newFavorite)
    {
        self.buttonOK.hidden = NO;
        self.deleteButton.hidden = YES;
    }
    else
    {
        self.buttonOK.hidden = YES;
        self.deleteButton.hidden = NO;
    }
    
    self.tableView.backgroundColor = UIColorFromRGB(0xf2f2f2);
}

-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    if (_favAction != kFavoriteActionNone)
    {
        [self setupView];
        return;
    }
    
    _showFavoriteOnExit = NO;
    
    [self registerForKeyboardNotifications];
    
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (_favAction != kFavoriteActionNone) {
        _favAction = kFavoriteActionNone;
        return;
    }
    
    OAAppSettings* settings = [OAAppSettings sharedManager];
    _wasShowingFavorite = settings.mapSettingShowFavorites;
    [settings setMapSettingShowFavorites:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (_favAction != kFavoriteActionNone)
        return;
    
    if (_showFavoriteOnExit)
    {
        [[OARootViewController instance].mapPanel modifyMapAfterReuse:[OANativeUtilities convertFromPointI:_newTarget31] zoom:kDefaultFavoriteZoomOnShow azimuth:0.0 elevationAngle:90.0 animated:NO];
        
    }
    else
    {
        OAAppSettings* settings = [OAAppSettings sharedManager];
        if (!_showFavoriteOnExit && !_wasShowingFavorite)
            [settings setMapSettingShowFavorites:NO];
    }
    
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
    NSString *desc = @"When Export is started, you may see error message: \"Check if you have enough free space on the device and is OsmAnd DVR has to access Camera Roll\". Please check the phone settings: \"Settings\" ➞ \"Privacy\" ➞ \"Photos\" ➞ «OsmAnd DVR» (This setting must be enabled). Also check the free space in the device's memory. To successfully copy / move the video to the Camera Roll, free space must be two times bigger than the size of the exported video at least. For example, if the size of the video is 200 MB, then for successful export you need to have 400 MB free.";
    
    CGSize s = [OAUtilities calculateTextBounds:desc width:self.tableView.bounds.size.width - 38.0 font:[UIFont fontWithName:@"AvenirNext-Regular" size:14.0]];
    CGFloat h = MIN(88.0, s.height);
    h = MAX(44.0, h);
    
    _descHeight = h;
    _descSingleLine = (s.height < 24.0);
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
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
}

- (void)unregisterKeyboardNotifications
{
    //unregister the keyboard notifications while not visible
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillShowNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    
}
// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWillShow:(NSNotification*)aNotification
{
    /*
    CGRect keyboardFrame = [[[aNotification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect convertedFrame = [self.view convertRect:keyboardFrame fromView:self.view.window];
    
    CGRect frameMap = self.mapView.frame;
    CGRect frameScrollView = self.scrollView.frame;
    CGRect frameDistView = self.distanceDirectionHolderView.frame;
    CGRect frameNameBtn = self.favoriteNameButton.frame;
    
    CGFloat minBottom = frameScrollView.origin.y + contentOriginY + frameNameBtn.size.height;
    CGFloat keyboardTop = self.view.frame.size.height - convertedFrame.size.height;
    
    BOOL needOffsetViews = minBottom > keyboardTop;
    
    if (needOffsetViews) {
        
        dy = keyboardTop - minBottom;
        isAdjustingVews = YES;
        
        [UIView animateWithDuration:.3 animations:^{
            self.mapView.frame = CGRectOffset(frameMap, 0.0, dy);
            self.scrollView.frame = CGRectOffset(frameScrollView, 0.0, dy);
            self.distanceDirectionHolderView.frame = CGRectOffset(frameDistView, 0.0, dy);
        } completion:^(BOOL finished) {
            isAdjustingVews = NO;
        }];
        
    } else {
        dy = 0.0;
    }
     */
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    /*
    if (dy < 0.0) {
        
        CGRect frameMap = self.mapView.frame;
        CGRect frameScrollView = self.scrollView.frame;
        CGRect frameDistView = self.distanceDirectionHolderView.frame;
        
        isAdjustingVews = YES;
        [UIView animateWithDuration:.3 animations:^{
            self.mapView.frame = CGRectOffset(frameMap, 0.0, -dy);
            self.scrollView.frame = CGRectOffset(frameScrollView, 0.0, -dy);
            self.distanceDirectionHolderView.frame = CGRectOffset(frameDistView, 0.0, -dy);
        } completion:^(BOOL finished) {
            isAdjustingVews = NO;
        }];
    }
     */
}

/*
#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)sender{
    OsmAndAppInstance app = [OsmAndApp instance];
    
    [self.favoriteNameButton setTitle:self.favoriteNameTextView.text forState:UIControlStateNormal];
    self.favorite.favorite->setTitle(QString::fromNSString(self.favoriteNameTextView.text));
    [app saveFavoritesToPermamentStorage];
    [self.favoriteNameTextView resignFirstResponder];
    [self.favoriteNameTextView setHidden:YES];
    
    [self.favoriteNameButton setTitle:self.favoriteNameTextView.text forState:UIControlStateNormal];
    
    _wasEdited = YES;
    
    return YES;
}

#pragma mark - Actions

- (IBAction)favoriteNameClicked:(id)sender {
    NSString* name = self.favorite.favorite->getTitle().toNSString();
    
    [self.favoriteNameButton setTitle:@"" forState:UIControlStateNormal];
    [self.favoriteNameTextView setText:name];
    
    [self.favoriteNameTextView setDelegate:self];
    [self.favoriteNameTextView becomeFirstResponder];
    [self.favoriteNameTextView setHidden:NO];
    
    if (_newFavorite)
        [self.favoriteNameTextView setSelectedTextRange:[self.favoriteNameTextView textRangeFromPosition:self.favoriteNameTextView.beginningOfDocument toPosition:self.favoriteNameTextView.endOfDocument]];
    
}
*/

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

- (void)doSave:(BOOL)flyToFav
{
    //if ([self.favoriteNameTextView isFirstResponder])
    //    self.favorite.favorite->setTitle(QString::fromNSString(self.favoriteNameTextView.text));
    
    NSString *favoriteTitle = self.favorite.favorite->getTitle().toNSString();
    
    if ([self isFavExists:favoriteTitle])
    {
        NSString *newName = [self getNewFavName:favoriteTitle];
        
        [[[UIAlertView alloc] initWithTitle:@"" message:[NSString stringWithFormat:OALocalizedString(@"fav_exists"), favoriteTitle] cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_cancel")] otherButtonItems:
          [RIButtonItem itemWithLabel:[NSString stringWithFormat:@"%@ %@", OALocalizedString(@"add_as"), newName] action:^{
            self.favorite.favorite->setTitle(QString::fromNSString(newName));
            [self saveAndExit:flyToFav];
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
            [self saveAndExit:flyToFav];
        }],
          nil] show];
        
        return;
    }
    
    [self saveAndExit:flyToFav];
}

- (void)saveAndExit:(BOOL)flyToFav
{
    [[OsmAndApp instance] saveFavoritesToPermamentStorage];
    
    if (flyToFav)
    {
        _newTarget31 = self.favorite.favorite->getPosition31();
        _showFavoriteOnExit = YES;
    }
    [self.navigationController popViewControllerAnimated:YES];
}



- (IBAction)favoriteChangeColorClicked:(id)sender
{
    _favAction = kFavoriteActionChangeColor;
    _colorController = [[OAFavoriteColorViewController alloc] initWithFavorite:self.favorite];
    _colorController.delegate = self;
    _colorController.hideToolbar = YES;
    [self.navController pushViewController:_colorController animated:YES];
}

- (IBAction)favoriteChangeGroupClicked:(id)sender
{
    _favAction = kFavoriteActionChangeGroup;
    _groupController = [[OAFavoriteGroupViewController alloc] initWithFavorite:self.favorite];
    _groupController.delegate = self;
    _groupController.hideToolbar = YES;
    [self.navController pushViewController:_groupController animated:YES];
}

// open map with favorite item
-(void)goToFavorite {
    
    OARootViewController* rootViewController = [OARootViewController instance];
    OAFavoriteItem* itemData = self.favorite;
    // Close everything
    [rootViewController closeMenuAndPanelsAnimated:YES];
    
    // Go to favorite location
    _newTarget31 = itemData.favorite->getPosition31();
    
    _showFavoriteOnExit = YES;
    
    [self.navigationController popToRootViewControllerAnimated:YES];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString* const reusableIdentifierTextLineCell = @"OATextLineViewCell";
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
            OATextLineViewCell* cell;
            cell = (OATextLineViewCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierTextLineCell];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATextLineViewCell" owner:self options:nil];
                cell = (OATextLineViewCell *)[nib objectAtIndex:0];
            }
            
            cell.textView.text = self.favorite.favorite->getTitle().toNSString();
            cell.backgroundColor = UIColorFromRGB(0xf2f2f2);

            return cell;
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
            
            NSString *desc = @"When Export is started, you may see error message: \"Check if you have enough free space on the device and is OsmAnd DVR has to access Camera Roll\". Please check the phone settings: \"Settings\" ➞ \"Privacy\" ➞ \"Photos\" ➞ «OsmAnd DVR» (This setting must be enabled). Also check the free space in the device's memory. To successfully copy / move the video to the Camera Roll, free space must be two times bigger than the size of the exported video at least. For example, if the size of the video is 200 MB, then for successful export you need to have 400 MB free.";
            
            if (!desc)
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

                cell.textView.text = desc;
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
    [self.tableView reloadData];
}

#pragma mark
#pragma mark - OAFavoriteGroupViewControllerDelegate

-(void)favoriteGroupChanged
{
    [self.tableView reloadData];
}

@end
