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
#import "OALocationIcon.h"
#import "OAMainSettingsViewController.h"
#import "OAConfigureProfileViewController.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "OAObservable.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAInputTableViewCell.h"
#import "OAColorsTableViewCell.h"
#import "OAIconsTableViewCell.h"
#import "OALocationIconsTableViewCell.h"
#import "OAIndexConstants.h"
#import "GeneratedAssetSymbols.h"

#define kIconsAtRestRow 0
#define kIconsWhileMovingRow 1

@interface OAApplicationProfileObject : NSObject

@property (nonatomic) NSString *stringKey;
@property (nonatomic) OAApplicationMode *parent;
@property (nonatomic) NSString *name;
@property (nonatomic) int color;
@property (nonatomic) int customColor;
@property (nonatomic) NSString *iconName;
@property (nonatomic) NSString *routingProfile;
@property (nonatomic) NSString *derivedProfile;
@property (nonatomic) EOARouteService routeService;
@property (nonatomic) NSString *navigationIcon;
@property (nonatomic) NSString *locationIcon;
@property (nonatomic) CGFloat minSpeed;
@property (nonatomic) CGFloat maxSpeed;

- (int) profileColor;

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
        if (_customColor != that.customColor)
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

- (int) profileColor
{
    if (_customColor != -1)
        return _customColor;
    return _color;
}

- (NSUInteger)hash
{
    NSUInteger result = _stringKey != nil ? _stringKey.hash : 0;
    result = 31 * result + (_parent != nil ? _parent.hash : 0);
    result = 31 * result + (_name != nil ? _name.hash : 0);
    result = 31 * result + @(_color).hash;
    result = 31 * result + @(_customColor).hash;
    result = 31 * result + (_iconName != nil ? _iconName.hash : 0);
    result = 31 * result + (_routingProfile != nil ? _routingProfile.hash : 0);
    result = 31 * result + @(_routeService).hash;
    result = 31 * result + _navigationIcon.hash;
    result = 31 * result + _locationIcon.hash;
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
    
    NSArray<NSString *> *_customModelNames;
    NSArray<OALocationIcon *> *_locationIcons;
    NSArray<OALocationIcon *> *_navigationIcons;
    NSArray<NSString *> *_locationIconNames;
    NSArray<NSString *> *_navigationIconNames;
    NSArray<UIImage *> *_locationIconImages;
    NSArray<UIImage *> *_navigationIconImages;
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
    _changedProfile.customColor = _profile.customColor;
    _changedProfile.iconName = _profile.iconName;
    _changedProfile.routeService = _profile.routeService;
    _changedProfile.derivedProfile = _profile.derivedProfile;
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
    _profile.customColor = baseModeForNewProfile.getCustomIconColor;
    _profile.iconName = baseModeForNewProfile.getIconName;
    _profile.derivedProfile = baseModeForNewProfile.getDerivedProfile;
    _profile.routingProfile = baseModeForNewProfile.getRoutingProfile;
    _profile.routeService = (EOARouteService) baseModeForNewProfile.getRouterService;
    _profile.locationIcon = [baseModeForNewProfile.getLocationIcon name];
    _profile.navigationIcon = [baseModeForNewProfile.getNavigationIcon name];
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
    [self.cancelButton setImage:[UIImage rtlImageNamed:@"ic_navbar_chevron"] forState:UIControlStateNormal];
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
    _profileIconImageView.image = [UIImage templateImageNamed:_changedProfile.iconName];
    _profileIconImageView.tintColor = UIColorFromRGB(_changedProfile.profileColor);
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
        @"type" : [OAInputTableViewCell getCellIdentifier],
        @"title" : _changedProfile.name,
    }];
    [profileAppearanceArr addObject:@{
        @"type" : [OAColorsTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"select_color"),
        @"value" : profileColor,
    }];
    [profileAppearanceArr addObject:@{
        @"type" : [OAIconsTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"select_icon_profile_dialog_title"),
        @"value" : @"",
    }];
    [profileMapAppearanceArr addObject:@{
        @"type" : [OALocationIconsTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"select_map_icon"),
        @"description" : @"",
    }];
    [profileMapAppearanceArr addObject:@{
        @"type" : [OALocationIconsTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"select_navigation_icon"),
        @"description" : OALocalizedString(@"will_be_show_while_moving"),
    }];
    [tableData addObject:profileNameArr];
    [tableData addObject:profileAppearanceArr];
    [tableData addObject:profileMapAppearanceArr];
    _data = [NSArray arrayWithArray:tableData];
}

- (void) generateData
{
    _customModelNames = [Model3dHelper getCustomModelNames];
    _locationIcons = [self getlocationIcons];
    _locationIconNames = [self getlocationIconNames];
    _navigationIcons = [self getlocationIcons];
    _navigationIconNames = [self getlocationIconNames];
    _locationIconImages = [self getlocationIconImages];
    _navigationIconImages = [self getlocationIconImages];
    
    _colors = @[
        @(profile_icon_color_blue_light_default),
        @(profile_icon_color_purple_light),
        @(profile_icon_color_green_light),
        @(profile_icon_color_blue_light),
        @(profile_icon_color_red_light),
        @(profile_icon_color_yellow_light),
        @(profile_icon_color_magenta_light),
    ];
    
    _colorNames = @{@(profile_icon_color_blue_light_default): @"rendering_value_lightblue_name", @(profile_icon_color_purple_light) : @"rendering_value_purple_name", @(profile_icon_color_green_light) : @"rendering_value_green_name", @(profile_icon_color_blue_light) : @"rendering_value_blue_name",  @(profile_icon_color_red_light) : @"rendering_value_red_name", @(profile_icon_color_yellow_light) : @"rendering_value_yellow_name", @(profile_icon_color_magenta_light) : @"shared_string_color_magenta"};
    
    _icons = @[@"ic_world_globe_dark",
               @"ic_action_car_dark",
               @"ic_action_taxi",
               @"ic_action_truck",
               @"ic_action_shuttle_bus",
               @"ic_action_bus_dark",
               @"ic_action_subway",
               @"ic_action_train",
               @"ic_action_motorcycle_dark",
               @"ic_action_enduro_motorcycle",
               @"ic_action_motor_scooter",
               @"ic_action_bicycle_dark",
               @"ic_action_mountain_bike",
               @"ic_action_horse",
               @"ic_action_pedestrian_dark",
               @"ic_action_trekking_dark",
               @"ic_action_hill_climbing",
               @"ic_action_ski_touring",
               @"ic_action_skiing",
               @"ic_action_monowheel",
               @"ic_action_personal_transporter",
               @"ic_action_scooter",
               @"ic_action_inline_skates",
               @"ic_action_wheelchair",
               @"ic_action_wheelchair_forward",
               @"ic_action_baby_transport",
               @"ic_action_sail_boat_dark",
               @"ic_action_aircraft",
               @"ic_action_camper",
               @"ic_action_campervan",
               @"ic_action_helicopter",
               @"ic_action_paragliding",
               @"ic_aciton_hang_gliding",
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

- (NSArray<OALocationIcon *> *) getlocationIcons
{
    NSMutableArray<OALocationIcon *> *icons = [NSMutableArray array];
    [icons addObjectsFromArray:[OALocationIcon defaultIcons]];
    
    NSArray<NSString *> *sortedCustomModelNames = [_customModelNames sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
        return [obj1 compare:obj2];
    }];
    for (NSString *modelName in sortedCustomModelNames)
    {
        OALocationIcon *icon = [OALocationIcon locationIconWithName:modelName];
        if (icon)
            [icons addObject:icon];
    }
    return icons;
}


- (NSArray<NSString *> *) getlocationIconNames
{
    NSMutableArray<NSString *> *iconNames = [NSMutableArray array];
    for (OALocationIcon *icon in _locationIcons)
    {
        [iconNames addObject:[icon name]];
    }
    return [iconNames copy];
}

- (NSArray<UIImage *> *) getlocationIconImages
{
    NSMutableArray<UIImage *> *images = [NSMutableArray array];
    UIColor *currColor = UIColorFromRGB(_changedProfile.profileColor);
    for (OALocationIcon *icon in _locationIcons)
    {
        UIImage *image = [icon getPreviewIconWithColor:currColor];
        if (image)
            [images addObject:image];
    }
    return images;
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (void)showExitWithoutSavingAlert {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"exit_without_saving") preferredStyle:UIAlertControllerStyleAlert];
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
        BOOL foundVC = NO;
        for (UIViewController *vc in [self.navigationController viewControllers])
        {
            if (([vc isKindOfClass:OAMainSettingsViewController.class] && _isNewProfile)
                || ([vc isKindOfClass:OAConfigureProfileViewController.class] && !_isNewProfile))
            {
                foundVC = YES;
                [self.navigationController popToViewController:vc animated:YES];
            }
        }
        if (!foundVC)
        {
            [self.navigationController popToRootViewControllerAnimated:YES];
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
        [mode setCustomIconColor:_changedProfile.customColor];
        [mode setLocationIconName:_changedProfile.locationIcon];
        [mode setNavigationIconName:_changedProfile.navigationIcon];
        
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
    [builder setDerivedProfile:_changedProfile.derivedProfile];
    [builder setRouteService:_changedProfile.routeService];
    [builder setIconColor:_changedProfile.color];
    [builder setCustomIconColor:_changedProfile.customColor];
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
        return OALocalizedString(@"shared_string_appearance");
    else if (section == 2)
        return OALocalizedString(@"appearance_on_the_map");
    return @"";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath { 
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *cellType = [[NSString alloc] initWithString:item[@"type"]];
    if ([cellType isEqualToString:[OAInputTableViewCell getCellIdentifier]])
    {
        OAInputTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAInputTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAInputTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAInputTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell titleVisibility:NO];
            [cell clearButtonVisibility:NO];
            [cell.inputField removeTarget:self action:NULL forControlEvents:UIControlEventEditingChanged];
            [cell.inputField addTarget:self action:@selector(textViewDidChange:) forControlEvents:UIControlEventEditingChanged];
            cell.inputField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
            cell.inputField.textAlignment = NSTextAlignmentNatural;
        }
        cell.inputField.text = item[@"title"];
        cell.inputField.delegate = self;
        return cell;
    }
    else if ([cellType isEqualToString:[OAColorsTableViewCell getCellIdentifier]])
    {
        OAColorsTableViewCell *cell = nil;
        cell = (OAColorsTableViewCell*)[tableView dequeueReusableCellWithIdentifier:[OAColorsTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAColorsTableViewCell getCellIdentifier] owner:self options:nil];
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
            cell.valueLabel.tintColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
            cell.currentColor = [_colors indexOfObject:@(_changedProfile.color)];
            [cell.collectionView reloadData];
            [cell layoutIfNeeded];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OAIconsTableViewCell getCellIdentifier]])
    {
        OAIconsTableViewCell *cell = nil;
        cell = (OAIconsTableViewCell*)[tableView dequeueReusableCellWithIdentifier:[OAIconsTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconsTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconsTableViewCell *)[nib objectAtIndex:0];
            cell.dataArray = _icons;
            cell.delegate = self;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsZero;
            cell.valueLabel.hidden = YES;
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.currentColor = _changedProfile.profileColor;
            cell.currentIcon = [_icons indexOfObject:_changedProfile.iconName];
            [cell.collectionView reloadData];
            [cell layoutIfNeeded];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OALocationIconsTableViewCell getCellIdentifier]])
    {
        static NSString* const identifierCell = [OALocationIconsTableViewCell getCellIdentifier];
        OALocationIconsTableViewCell *cell = nil;
        cell = (OALocationIconsTableViewCell*)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OALocationIconsTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OALocationIconsTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsZero;
        }
        if (cell)
        {
            BOOL isAtRestRow = indexPath.row == kIconsAtRestRow;
            cell.locationType = isAtRestRow ? EOALocationTypeRest : EOALocationTypeMoving;
            cell.dataArray = isAtRestRow ? _locationIconImages : _navigationIconImages;
            
            if (isAtRestRow)
            {
                cell.selectedIndex = [_locationIconNames indexOfObject:_changedProfile.locationIcon];
                if (cell.selectedIndex == NSNotFound)
                    cell.selectedIndex = 0;
            }
            else
            {
                cell.selectedIndex = [_navigationIconNames indexOfObject:_changedProfile.navigationIcon];
                if (cell.selectedIndex == NSNotFound)
                    cell.selectedIndex = 0;
            }

            cell.titleLabel.text = item[@"title"];
            cell.currentColor = _changedProfile.profileColor;
            
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
        headerView.textLabel.textColor  = [UIColor colorNamed:ACColorNameTextColorSecondary];
    }
}

#pragma mark - OAColorsTableViewCellDelegate

- (void)colorChanged:(NSInteger)tag
{
    _hasChangesBeenMade = YES;
    _changedProfile.color = _colors[tag].intValue;
    _changedProfile.customColor = -1;
    
    _locationIconImages = [self getlocationIconImages];
    _navigationIconImages = [self getlocationIconImages];
    [self setupView];
    _profileIconImageView.tintColor = UIColorFromRGB(_changedProfile.profileColor);
    [_tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, _tableView.numberOfSections - 1)] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - OAIconsTableViewCellDelegate

- (void)iconChanged:(NSInteger)tag
{
    _hasChangesBeenMade = YES;
    _changedProfile.iconName = _icons[tag];
    
    _profileIconImageView.image = [UIImage templateImageNamed:_changedProfile.iconName];
    [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - OASeveralViewsTableViewCellDelegate

- (void)mapIconChanged:(NSInteger)newValue type:(EOALocationType)locType
{
    _hasChangesBeenMade = YES;
    if (locType == EOALocationTypeRest)
        _changedProfile.locationIcon = _locationIconNames[newValue];
    else if (locType == EOALocationTypeMoving)
        _changedProfile.navigationIcon = _navigationIconNames[newValue];
    
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
