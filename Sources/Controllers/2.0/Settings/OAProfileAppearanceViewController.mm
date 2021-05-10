//
//  OAProfileAppearanceViewController.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 17.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAProfileAppearanceViewController.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAApplicationMode.h"
#import "OANavigationIcon.h"
#import "OALocationIcon.h"
#import "OAMainSettingsViewController.h"
#import "OAConfigureProfileViewController.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"

#import "OATextInputCell.h"
#import "OAColorsTableViewCell.h"
#import "OAIconsTableViewCell.h"
#import "OALocationIconsTableViewCell.h"

#define kCellTypeInput @"OATextInputCell"
#define kCellTypeColorCollection @"colorCollectionCell"
#define kCellTypeIconCollection @"iconCollectionCell"
#define kCellTypePositionIconCollection @"positionIconCollection"
#define kIconsAtRestRow 0
#define kIconsWhileMovingRow 1

@interface OAApplicationProfileObject : NSObject

@property (nonatomic) NSString *stringKey;
@property (nonatomic) OAApplicationMode *parent;
@property (nonatomic) NSString *name;
@property (nonatomic) int color;
@property (nonatomic) NSString *iconName;
@property (nonatomic) NSString *routingProfile;
@property (nonatomic) EOARouteService routeService;
@property (nonatomic) EOANavigationIcon navigationIcon;
@property (nonatomic) EOALocationIcon locationIcon;
@property (nonatomic) CGFloat minSpeed;
@property (nonatomic) CGFloat maxSpeed;

@end

@implementation OAApplicationProfileObject

- (BOOL)isEqual:(id)other
{
    if (other == self) {
        return YES;
    } else {
        OAApplicationProfileObject *that = (OAApplicationProfileObject *) other;

        if (![_iconName isEqualToString:that.iconName])
            return NO;
        if (_stringKey != nil ? ![_stringKey isEqualToString:that.stringKey] : that.stringKey != nil)
            return NO;
        if (_parent != nil ? ![_parent isEqual:that.parent] : that.parent != nil)
            return NO;
        if (_name != nil ? ![_name isEqualToString:that.name] : that.name != nil)
            return NO;
        if (_color != that.color)
            return NO;
        if (_routingProfile != nil ? ![_routingProfile isEqualToString:that.routingProfile] : that.routingProfile != nil)
            return NO;
        if (_routeService != that.routeService)
            return NO;
        if (_navigationIcon != that.navigationIcon)
            return NO;
        if (_minSpeed != that.minSpeed)
            return NO;
        if (_maxSpeed != that.maxSpeed)
            return NO;
        return _locationIcon == that.locationIcon;
    }
}

- (NSUInteger)hash
{
    NSUInteger result = _stringKey != nil ? _stringKey.hash : 0;
    result = 31 * result + (_parent != nil ? _parent.hash : 0);
    result = 31 * result + (_name != nil ? _name.hash : 0);
    result = 31 * result + @(_color).hash;
    result = 31 * result + (_iconName != nil ? _iconName.hash : 0);
    result = 31 * result + (_routingProfile != nil ? _routingProfile.hash : 0);
    result = 31 * result + @(_routeService).hash;
    result = 31 * result + @(_navigationIcon).hash;
    result = 31 * result + @(_locationIcon).hash;
    return result;
}

@end

@interface OAProfileAppearanceViewController() <UITableViewDelegate, UITableViewDataSource, OAColorsTableViewCellDelegate,  OAIconsTableViewCellDelegate, OALocationIconsTableViewCellDelegate, UITextFieldDelegate>

@end

@implementation OAProfileAppearanceViewController
{
    OAApplicationProfileObject *_profile;
    OAApplicationProfileObject *_changedProfile;
    
    BOOL _isNewProfile;
    BOOL _hasChangesBeenMade;
    
    NSArray<NSArray *> *_data;
    
    NSArray<NSNumber *> *_colors;
    NSDictionary<NSNumber *, NSString *> *_colorNames;
    NSArray<NSString *> *_icons;
}

- (instancetype) initWithParentProfile:(OAApplicationMode *)profile
{
    self = [super init];
    if (self) {
        _isNewProfile = YES;
        _profile = [[OAApplicationProfileObject alloc] init];
        [self setupAppProfileObjectFromAppMode:profile];
        _profile.parent = profile;
        _profile.stringKey = [self getUniqueStringKey:profile];
        
        [self setupChangedProfile];
        
        [self commonInit];
    }
    return self;
}

- (instancetype) initWithProfile:(OAApplicationMode *)profile
{
    self = [super init];
    if (self) {
        _isNewProfile = NO;
        _profile = [[OAApplicationProfileObject alloc] init];
        [self setupAppProfileObjectFromAppMode:profile];
        
        [self setupChangedProfile];
        
        [self commonInit];
    }
    return self;
}

- (void) setupChangedProfile
{
    _changedProfile = [[OAApplicationProfileObject alloc] init];
    _changedProfile.stringKey = _profile.stringKey;
    _changedProfile.parent = _profile.parent;
    _changedProfile.name = _isNewProfile ? [self createNonDuplicateName:_profile.name] : _profile.name;
    _changedProfile.color = _profile.color;
    _changedProfile.iconName = _profile.iconName;
    _changedProfile.routeService = _profile.routeService;
    _changedProfile.routingProfile = _profile.routingProfile;
    _changedProfile.navigationIcon = _profile.navigationIcon;
    _changedProfile.locationIcon = _profile.locationIcon;
    _changedProfile.minSpeed = _profile.minSpeed;
    _changedProfile.maxSpeed = _profile.maxSpeed;
}

- (void) setupAppProfileObjectFromAppMode:(OAApplicationMode *) baseModeForNewProfile
{
    _profile.stringKey = baseModeForNewProfile.stringKey;
    _profile.parent = baseModeForNewProfile.parent;
    _profile.name = baseModeForNewProfile.toHumanString;
    _profile.color = baseModeForNewProfile.getIconColor;
    _profile.iconName = baseModeForNewProfile.getIconName;
    _profile.routingProfile = baseModeForNewProfile.getRoutingProfile;
    _profile.routeService = (EOARouteService) baseModeForNewProfile.getRouterService;
    _profile.locationIcon = baseModeForNewProfile.getLocationIcon;
    _profile.navigationIcon = baseModeForNewProfile.getNavigationIcon;
    _profile.minSpeed = baseModeForNewProfile.baseMinSpeed;
    _profile.maxSpeed = baseModeForNewProfile.baseMaxSpeed;
}

- (void) commonInit
{
    [self generateData];
}

- (void) applyLocalization
{
    [_saveButton setTitle:OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
    _titleLabel.text = _changedProfile.name.length == 0 ? [self getEmptyNameTitle] : _changedProfile.name;
}

- (NSString *) getEmptyNameTitle
{
    return _isNewProfile ? OALocalizedString(@"new_profile") : OALocalizedString(@"profile_appearance");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.separatorInset = UIEdgeInsetsMake(0., 16., 0., 0.);
    _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self setupNavBar];
    [self setupView];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [self.navigationController.interactivePopGestureRecognizer addTarget:self
                                                                      action:@selector(swipeToCloseRecognized:)];
}

- (void) swipeToCloseRecognized:(UIGestureRecognizer *)recognizer
{
    if (_hasChangesBeenMade)
    {
        recognizer.enabled = NO;
        recognizer.enabled = YES;
        [self showExitWithoutSavingAlert];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void) setupNavBar
{
    NSString *imgName = _changedProfile.iconName;
    UIImage *img = [UIImage imageNamed:imgName];
    _profileIconImageView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _profileIconImageView.tintColor = UIColorFromRGB(_changedProfile.color);
    _profileIconView.layer.cornerRadius = _profileIconView.frame.size.height/2;
}

- (NSString *) createNonDuplicateName:(NSString *)profileName
{
    NSRange lastSpace = [profileName rangeOfString:@" " options:NSBackwardsSearch];
    NSString *baseString;
    NSString *numberString;
    NSInteger number = 0;
    if (lastSpace.length == 0)
    {
        baseString = profileName;
    }
    else
    {
        baseString = [profileName substringToIndex:lastSpace.location];
        numberString = [profileName substringFromIndex:lastSpace.location];
        number = [numberString intValue];
        if (number == 0)
            baseString = profileName;
    }
    NSString *proposedProfileName;
    for (NSInteger value = number + 1; ; value++)
    {
        proposedProfileName = [NSString stringWithFormat:@"%@ %ld", baseString, value];
        if ([OAApplicationMode isProfileNameAvailable:proposedProfileName])
            break;
    }
    return proposedProfileName;
}

- (void) setupView
{
    NSMutableArray *tableData = [NSMutableArray array];
    
    NSMutableArray *profileNameArr = [NSMutableArray array];
    NSMutableArray *profileAppearanceArr = [NSMutableArray array];
    NSMutableArray *profileMapAppearanceArr = [NSMutableArray array];
    NSString* profileColor = OALocalizedString(_colorNames[@(_changedProfile.color)]);
    [profileNameArr addObject:@{
        @"type" : kCellTypeInput,
        @"title" : _changedProfile.name,
    }];
    [profileAppearanceArr addObject:@{
        @"type" : kCellTypeColorCollection,
        @"title" : OALocalizedString(@"select_color"),
        @"value" : profileColor,
    }];
    [profileAppearanceArr addObject:@{
        @"type" : kCellTypeIconCollection,
        @"title" : OALocalizedString(@"select_icon"),
        @"value" : @"",
    }];
    [profileMapAppearanceArr addObject:@{
        @"type" : kCellTypePositionIconCollection,
        @"title" : OALocalizedString(@"position_icon_at_rest"),
        @"description" : @"",
    }];
    [profileMapAppearanceArr addObject:@{
        @"type" : kCellTypePositionIconCollection,
        @"title" : OALocalizedString(@"position_icon_while_moving"),
        @"description" : OALocalizedString(@"will_be_show_while_moving"),
    }];
    [tableData addObject:profileNameArr];
    [tableData addObject:profileAppearanceArr];
    [tableData addObject:profileMapAppearanceArr];
    _data = [NSArray arrayWithArray:tableData];
}

- (void) generateData
{
    _colors = @[
        @(profile_icon_color_blue_light_default),
        @(profile_icon_color_purple_light),
        @(profile_icon_color_green_light),
        @(profile_icon_color_blue_light),
        @(profile_icon_color_red_light),
        @(profile_icon_color_yellow_light),
        @(profile_icon_color_magenta_light),
    ];
    
    _colorNames = @{@(profile_icon_color_blue_light_default): @"lightblue", @(profile_icon_color_purple_light) : @"purple", @(profile_icon_color_green_light) : @"green", @(profile_icon_color_blue_light) : @"blue",  @(profile_icon_color_red_light) : @"red", @(profile_icon_color_yellow_light) : @"yellow", @(profile_icon_color_magenta_light) : @"col_magenta"};
    
    _icons = @[@"ic_world_globe_dark",
               @"ic_action_car_dark",
               @"ic_action_taxi",
               @"ic_action_truck_dark",
               @"ic_action_shuttle_bus",
               @"ic_action_bus_dark",
               @"ic_action_subway",
               @"ic_action_motorcycle_dark",
               @"ic_action_enduro_motorcycle",
               @"ic_action_motor_scooter",
               @"ic_action_bicycle_dark",
               @"ic_action_horse",
               @"ic_action_pedestrian_dark",
               @"ic_action_trekking_dark",
               @"ic_action_ski_touring",
               @"ic_action_skiing",
               @"ic_action_monowheel",
               @"ic_action_personal_transporter",
               @"ic_action_scooter",
               @"ic_action_inline_skates",
               @"ic_action_wheelchair",
               @"ic_action_wheelchair_forward",
               @"ic_action_sail_boat_dark",
               @"ic_action_aircraft",
               @"ic_action_camper",
               @"ic_action_campervan",
               @"ic_action_helicopter",
               @"ic_action_offroad",
               @"ic_action_pickup_truck",
               @"ic_action_snowmobile",
               @"ic_action_ufo",
               @"ic_action_utv",
               @"ic_action_wagon",
               @"ic_action_go_cart",
               @"ic_action_openstreetmap_logo",
               @"ic_action_kayak",
               @"ic_action_motorboat",
               @"ic_action_light_aircraft"];
}

- (NSArray<UIImage *> *) getIconsAtRest
{
    UIColor *currColor = UIColorFromRGB(_changedProfile.color);
    return @[[OALocationIcon getIcon:LOCATION_ICON_DEFAULT color:currColor], [OALocationIcon getIcon:LOCATION_ICON_CAR color:currColor], [OALocationIcon getIcon:LOCATION_ICON_BICYCLE color:currColor]];
}

- (NSArray<UIImage *> *) getNavIcons
{
    UIColor *currColor = UIColorFromRGB(_changedProfile.color);
    return @[[OANavigationIcon getIcon:NAVIGATION_ICON_DEFAULT color:currColor], [OANavigationIcon getIcon:NAVIGATION_ICON_NAUTICAL color:currColor], [OANavigationIcon getIcon:NAVIGATION_ICON_CAR color:currColor]];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (void)showExitWithoutSavingAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"osm_editing_lost_changes_title") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_exit") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (IBAction) cancelButtonClicked:(id)sender
{
    if (_hasChangesBeenMade)
        [self showExitWithoutSavingAlert];
    else
        [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction) saveButtonClicked:(id)sender
{
    _changedProfile.name = [_changedProfile.name trim];
    if (_changedProfile.name.length == 0)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"empty_profile_name_warning") preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else if (![OAApplicationMode isProfileNameAvailable:_changedProfile.name] && _isNewProfile)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"not_available_profile_name") preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else
    {
        [self saveProfile];
        for (UIViewController *vc in [self.navigationController viewControllers])
        {
            if (([vc isKindOfClass:OAMainSettingsViewController.class] && _isNewProfile)
                || ([vc isKindOfClass:OAConfigureProfileViewController.class] && !_isNewProfile))
            {
                [self.navigationController popToViewController:vc animated:YES];
            }
        }
    }
}

- (void) saveProfile
{
    _profile = _changedProfile;
    if (_isNewProfile)
    {
        [self saveNewProfile];
    }
    else
    {
        OAApplicationMode *mode = [OAApplicationMode valueOfStringKey:_changedProfile.stringKey
                                                                 def:[[OAApplicationMode alloc] initWithName:@"" stringKey:_changedProfile.stringKey]];
        [mode setParent:_changedProfile.parent];
        [mode setIconName:_changedProfile.iconName];
        [mode setUserProfileName:[_changedProfile.name trim]];
        [mode setRoutingProfile:_changedProfile.routingProfile];
        [mode setRouterService:_changedProfile.routeService];
        [mode setIconColor:_changedProfile.color];
        [mode setLocationIcon:_changedProfile.locationIcon];
        [mode setNavigationIcon:_changedProfile.navigationIcon];
        
        [[[OsmAndApp instance] availableAppModesChangedObservable] notifyEvent];
    }
}

- (void) saveNewProfile
{
    _changedProfile.stringKey = [self getUniqueStringKey:_changedProfile.parent];
    
    OAApplicationModeBuilder *builder = [OAApplicationMode createCustomMode:_changedProfile.parent stringKey:_changedProfile.stringKey];
    [builder setIconResName:_changedProfile.iconName];
    [builder setUserProfileName:_changedProfile.name.trim];
    [builder setRoutingProfile:_changedProfile.routingProfile];
    [builder setRouteService:_changedProfile.routeService];
    [builder setIconColor:_changedProfile.color];
    [builder setLocationIcon:_changedProfile.locationIcon];
    [builder setNavigationIcon:_changedProfile.navigationIcon];
    [builder setOrder:(int) OAApplicationMode.allPossibleValues.count];
    
    OAApplicationMode *mode = [OAApplicationMode saveProfile:builder];
    if (![OAApplicationMode.values containsObject:mode])
        [OAApplicationMode changeProfileAvailability:mode isSelected:YES];
}

- (NSString *) getUniqueStringKey:(OAApplicationMode *)am
{
    return [NSString stringWithFormat:@"%@_%ld", am.stringKey, (NSInteger) [NSDate.date timeIntervalSince1970]];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [_tableView reloadData];
    } completion:nil];
}

#pragma mark - Table View

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _data[section].count;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return @"";
    else if (section == 1)
        return OALocalizedString(@"map_settings_appearance");
    else if (section == 2)
        return OALocalizedString(@"appearance_on_map");
    return @"";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath { 
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = [[NSString alloc] initWithString:item[@"type"]];
    if ([cellType isEqualToString:kCellTypeInput])
    {
        static NSString* const identifierCell = @"OATextInputCell";
        OATextInputCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATextInputCell" owner:self options:nil];
            cell = (OATextInputCell *)[nib objectAtIndex:0];
            [cell.inputField addTarget:self action:@selector(textViewDidChange:) forControlEvents:UIControlEventEditingChanged];
            cell.inputField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        }
        cell.inputField.text = item[@"title"];
        cell.inputField.delegate = self;
        return cell;
    }
    else if ([cellType isEqualToString:kCellTypeColorCollection])
    {
        static NSString* const identifierCell = [OAColorsTableViewCell getCellIdentifier];
        OAColorsTableViewCell *cell = nil;
        cell = (OAColorsTableViewCell*)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OAColorsTableViewCell *)[nib objectAtIndex:0];
            cell.dataArray = _colors;
            cell.delegate = self;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsZero;
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.valueLabel.text = item[@"value"];
            cell.valueLabel.tintColor = UIColorFromRGB(color_text_footer);
            cell.currentColor = [_colors indexOfObject:@(_changedProfile.color)];
            [cell.collectionView reloadData];
            [cell layoutIfNeeded];
        }
        return cell;
    }
    else if ([cellType isEqualToString:kCellTypeIconCollection])
    {
        static NSString* const identifierCell = @"OAIconsTableViewCell";
        OAIconsTableViewCell *cell = nil;
        cell = (OAIconsTableViewCell*)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconsTableViewCell" owner:self options:nil];
            cell = (OAIconsTableViewCell *)[nib objectAtIndex:0];
            cell.dataArray = _icons;
            cell.delegate = self;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsZero;
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.currentColor = _changedProfile.color;
            cell.currentIcon = [_icons indexOfObject:_changedProfile.iconName];
            [cell.collectionView reloadData];
            [cell layoutIfNeeded];
        }
        return cell;
    }
    else if ([cellType isEqualToString:kCellTypePositionIconCollection])
    {
        static NSString* const identifierCell = @"OALocationIconsTableViewCell";
        OALocationIconsTableViewCell *cell = nil;
        cell = (OALocationIconsTableViewCell*)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OALocationIconsTableViewCell" owner:self options:nil];
            cell = (OALocationIconsTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsZero;
        }
        if (cell)
        {
            BOOL isAtRestRow = indexPath.row == kIconsAtRestRow;
            cell.locationType = isAtRestRow ? EOALocationTypeRest : EOALocationTypeMoving;
            cell.dataArray = isAtRestRow ? [self getIconsAtRest] : [self getNavIcons];
            cell.selectedIndex = isAtRestRow ? _changedProfile.locationIcon : _changedProfile.navigationIcon;
            cell.titleLabel.text = item[@"title"];
            cell.currentColor = _changedProfile.color;
            cell.delegate = self;
            [cell.collectionView reloadData];
            [cell layoutIfNeeded];
        }
        return cell;
    }
    return nil;
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    return cell.selectionStyle == UITableViewCellSelectionStyleNone ? nil : indexPath;
}

- (void) tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView * headerView = (UITableViewHeaderFooterView *) view;
        headerView.textLabel.textColor  = UIColorFromRGB(color_text_footer);
    }
}

#pragma mark - OAColorsTableViewCellDelegate

- (void)colorChanged:(NSInteger)tag
{
    _hasChangesBeenMade = YES;
    _changedProfile.color = _colors[tag].intValue;
    
    [self setupView];
    _profileIconImageView.tintColor = UIColorFromRGB(_changedProfile.color);
    [_tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, _tableView.numberOfSections - 1)] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - OAIconsTableViewCellDelegate

- (void)iconChanged:(NSInteger)tag
{
    _hasChangesBeenMade = YES;
    _changedProfile.iconName = _icons[tag];
    
    UIImage *img = nil;
    NSString *imgName = _changedProfile.iconName;
    img = [UIImage imageNamed:imgName];
    _profileIconImageView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - OASeveralViewsTableViewCellDelegate

- (void)mapIconChanged:(NSInteger)newValue type:(EOALocationType)locType
{
    _hasChangesBeenMade = YES;
    if (locType == EOALocationTypeRest)
        _changedProfile.locationIcon = (EOALocationIcon) newValue;
    else if (locType == EOALocationTypeMoving)
        _changedProfile.navigationIcon = (EOANavigationIcon) newValue;
    
    [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:locType == EOALocationTypeRest ? 0 : 1 inSection:2]] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - UITextFieldDelegate

- (BOOL) textFieldShouldReturn:(UITextField *)sender
{
    [sender resignFirstResponder];
    return YES;
}

- (void) textViewDidChange:(UITextView *)textView
{
    _hasChangesBeenMade = YES;
    _changedProfile.name = textView.text;
    _titleLabel.text = _changedProfile.name.length == 0 ? [self getEmptyNameTitle] : _changedProfile.name;
}

#pragma mark - Keyboard Notifications

- (void) keyboardWillShow:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    NSValue *keyboardBoundsValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGFloat keyboardHeight = [keyboardBoundsValue CGRectValue].size.height;
    
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [[self tableView] contentInset];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        [[self tableView] setContentInset:UIEdgeInsetsMake(insets.top, insets.left, keyboardHeight, insets.right)];
        [[self view] layoutIfNeeded];
    } completion:nil];
}

- (void) keyboardWillHide:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [[self tableView] contentInset];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        [[self tableView] setContentInset:UIEdgeInsetsMake(insets.top, insets.left, 0., insets.right)];
        [[self view] layoutIfNeeded];
    } completion:nil];
}

@end
