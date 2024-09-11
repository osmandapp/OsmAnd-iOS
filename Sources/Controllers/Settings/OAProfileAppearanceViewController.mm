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
#import "OAIconsTableViewCell.h"
#import "OAIndexConstants.h"
#import "OAColorsPaletteCell.h"
#import "OAColorCollectionHandler.h"
#import "OAGPXAppearanceCollection.h"
#import "OAColorCollectionViewController.h"
#import "OAIconsPaletteCell.h"
#import "GeneratedAssetSymbols.h"

static const int kIconsAtRestRow = 0;
static const int kIconsWhileMovingRow = 1;

static const int kNameSectionIndex = 0;
static const int kColorSectionIndex = 1;
static const int kColorRowIndex = 0;
static const int kProfileIconSectionIndex = 2;
static const int kLocationIconSectionIndex = 3;
static const int kNavigationIconSectionIndex = 4;
static const int kOptionsSectionIndex = 5;

static NSString *kColorsCellKey =  @"kColorsCellKey";
static NSString *kProfileIconCellKey =  @"kProfileIconCellKey";
static NSString *kPositionIconCellKey =  @"kPositionIconCellKey";
static NSString *kLocationIconCellKey =  @"kLocationIconCellKey";
static NSString *kViewAngleCellKey =  @"kViewAngleButtonKey";
static NSString *kLocationRadiusCellKey =  @"kLocationRadiusButtonKey";

static NSString *kCellHeaderTitleKey = @"kCellHeaderTitleKey";
static NSString *kCellTitleColorKey = @"kCellTitleColorKey";
static NSString *kCellHideSeparatorKey = @"kCellHideSeparatorKey";
static NSString *kCellNonInteractive = @"kCellNonInteractive";

static NSString *kColorsCellTitleKey =  @"kColorsCellTitleKey";
static NSString *kAllColorsButtonKey =  @"kAllColorsButtonKey";

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
@property (nonatomic) int viewAngleVisibility;
@property (nonatomic) int locationRadiusVisibility;
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
        if (_locationRadiusVisibility != that.locationRadiusVisibility)
            return NO;
        if (_viewAngleVisibility != that.viewAngleVisibility)
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
    result = 31 * result + @(_viewAngleVisibility).hash;
    result = 31 * result + @(_locationRadiusVisibility).hash;
    return result;
}

@end

@interface OAProfileAppearanceViewController() <UITableViewDelegate, UITableViewDataSource, OAColorsCollectionCellDelegate, ProfileAppearanceViewAngleUpdatable, ProfileAppearanceLocationRadiusUpdatable, UITextFieldDelegate>

@end

@implementation OAProfileAppearanceViewController
{
    OAApplicationProfileObject *_profile;
    OAApplicationProfileObject *_changedProfile;
    
    BOOL _isNewProfile;
    BOOL _hasChangesBeenMade;
    
    OATableDataModel *_data;
    
    NSArray<NSString *> *_icons;
    
    OAColorCollectionHandler *_colorCollectionHandler;
    BOOL _needToScrollToSelectedColor;
    
    IconCollectionHandler *_profileIconCollectionHandler;
    IconCollectionHandler *_positionIconCollectionHandler;
    IconCollectionHandler *_locationIconCollectionHandler;
    
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
    _changedProfile.viewAngleVisibility = _profile.viewAngleVisibility;
    _changedProfile.locationRadiusVisibility = _profile.locationRadiusVisibility;
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
    _profile.viewAngleVisibility = [baseModeForNewProfile getViewAngleVisibility];
    _profile.locationRadiusVisibility = [baseModeForNewProfile getLocationRadiusVisibility];
}

- (void) commonInit
{
    [self prepareData];
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
    [self generateData];

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

- (void) generateData
{
    _data = [[OATableDataModel alloc] init];
    OATableSectionData *profileNameSection = [_data createNewSection];
    [profileNameSection addRowFromDictionary:@{
        kCellTypeKey : [OAInputTableViewCell getCellIdentifier],
        kCellTitleKey : _changedProfile.name,
    }];
    
    OATableSectionData *profileColorSection = [_data createNewSection];
    [profileColorSection addRowFromDictionary:@{
        kCellTypeKey : [OAColorsPaletteCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"shared_string_color"),
        kCellDescrKey : OALocalizedString(@"shared_string_all_colors"),
        kCellKeyKey : kColorsCellKey,
    }];
    
    OATableSectionData *profileIconSection = [_data createNewSection];
    [profileIconSection addRowFromDictionary:@{
        kCellTypeKey : [OAIconsPaletteCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"profile_icon"),
        kCellDescrKey : OALocalizedString(@"shared_string_all_icons"),
        kCellKeyKey : kProfileIconCellKey,
    }];
    
    OATableSectionData *positionIconsSection = [_data createNewSection];
    [positionIconsSection addRowFromDictionary:@{
        kCellHeaderTitleKey : OALocalizedString(@"resting_position_icon"),
        kCellTypeKey : [OAIconsPaletteCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"resting_position_icon_summary"),
        kCellDescrKey : OALocalizedString(@"shared_string_all_icons"),
        kCellKeyKey : kPositionIconCellKey,
    }];
    
    OATableSectionData *navigationIconsSection = [_data createNewSection];
    [navigationIconsSection addRowFromDictionary:@{
        kCellHeaderTitleKey : OALocalizedString(@"navigation_position_icon"),
        kCellTypeKey : [OAIconsPaletteCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"navigation_position_icon_summary"),
        kCellDescrKey : OALocalizedString(@"shared_string_all_icons"),
        kCellKeyKey : kLocationIconCellKey,
    }];

    OATableSectionData *optionsSection = [_data createNewSection];
    [OAAppSettings.sharedManager.viewAngleVisibility get:_profile.parent];
    
    MarkerDisplayOption viewAngleVisibility = [MarkerDisplayOptionWrapper valueBy:_changedProfile.viewAngleVisibility];
    MarkerDisplayOption locationRadiusVisibility = [MarkerDisplayOptionWrapper valueBy:_changedProfile.locationRadiusVisibility];
    NSString *viewAngleVisibilityName = [MarkerDisplayOptionWrapper getNameForType:viewAngleVisibility];
    NSString *locationRadiusVisibilityName = [MarkerDisplayOptionWrapper getNameForType:locationRadiusVisibility];
    [optionsSection addRowFromDictionary:@{
        kCellHeaderTitleKey : OALocalizedString(@"shared_string_options"),
        kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"view_angle"),
        kCellDescrKey : OALocalizedString(viewAngleVisibilityName),
        kCellIconNameKey : @"ic_custom_location_view_angle",
        kCellIconTintColor : UIColorFromRGB(_changedProfile.profileColor),
        kCellKeyKey : kViewAngleCellKey,
    }];
    [optionsSection addRowFromDictionary:@{
        kCellTypeKey : [OAValueTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"location_radius"),
        kCellDescrKey : OALocalizedString(locationRadiusVisibilityName),
        kCellIconNameKey : @"ic_custom_location_radius",
        kCellIconTintColor : UIColorFromRGB(_changedProfile.profileColor),
        kCellKeyKey : kLocationRadiusCellKey,
    }];
}

- (void) prepareData
{
    OAGPXAppearanceCollection *appearanceCollection = [OAGPXAppearanceCollection sharedInstance];
    NSMutableArray<OAColorItem *> *sortedColorItems = [NSMutableArray arrayWithArray:[appearanceCollection getAvailableColorsSortingByLastUsed]];
    _colorCollectionHandler =  [[OAColorCollectionHandler alloc] initWithData:@[sortedColorItems] collectionView:nil];
    _colorCollectionHandler.delegate = self;
    _colorCollectionHandler.hostVC = self;
    
    UIColor *selectedColor = selectedColor = UIColorFromRGB([_changedProfile profileColor]);
    OAColorItem * selectedColorItem = [appearanceCollection getColorItemWithValue:[selectedColor toARGBNumber]];
    NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:[[_colorCollectionHandler getData][0] indexOfObject:selectedColorItem] inSection:0];
    if (selectedIndexPath.row == NSNotFound)
        selectedIndexPath = [NSIndexPath indexPathForRow:[[_colorCollectionHandler getData][0] indexOfObject:[appearanceCollection getDefaultPointColorItem]] inSection:0];
    [_colorCollectionHandler setSelectedIndexPath:selectedIndexPath];
    
    _icons = @[@"ic_world_globe_dark",
               @"ic_action_car_dark",
               @"ic_action_taxi",
               @"ic_action_truck_dark",
               @"ic_action_suv",
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
    
    _profileIconCollectionHandler = [[IconCollectionHandler alloc] initWithData:@[_icons] collectionView:nil];
    _profileIconCollectionHandler.delegate = self;
    _profileIconCollectionHandler.hostVC = self;
    _profileIconCollectionHandler.customTitle = OALocalizedString(@"profile_icon");
    _profileIconCollectionHandler.regularIconColor = [UIColor colorNamed:ACColorNameIconColorDefault];
    _profileIconCollectionHandler.selectedIconColor = UIColorFromRGB(_changedProfile.profileColor);
    [_profileIconCollectionHandler setItemSizeWithSize:48];
    [_profileIconCollectionHandler setIconSizeWithSize:30];
    NSInteger selectedIconIndex = [_icons indexOfObject:_changedProfile.iconName];
    [_profileIconCollectionHandler setSelectedIndexPath:[NSIndexPath indexPathForRow:selectedIconIndex inSection:0]];
    
    _customModelNames = [Model3dHelper getCustomModelNames];
    _locationIcons = [self getlocationIcons];
    _locationIconNames = [self getlocationIconNames];
    _locationIconImages = [self getlocationIconImages];
    _positionIconCollectionHandler = [[IconCollectionHandler alloc] initWithData:@[_locationIconNames] collectionView:nil];
    _positionIconCollectionHandler.iconImagesData = @[_locationIconImages];
    _positionIconCollectionHandler.roundedSquareCells = true;
    _positionIconCollectionHandler.cornerRadius = 6;
    _positionIconCollectionHandler.delegate = self;
    _positionIconCollectionHandler.hostVC = self;
    _positionIconCollectionHandler.customTitle = OALocalizedString(@"resting_position_icon");
    _positionIconCollectionHandler.regularIconColor = [UIColor colorNamed:ACColorNameIconColorDefault];
    _positionIconCollectionHandler.selectedIconColor = UIColorFromRGB(_changedProfile.profileColor);
    [_positionIconCollectionHandler setItemSizeWithSize:156];
    [_positionIconCollectionHandler setIconSizeWithSize:52];
    selectedIconIndex = [_locationIconNames indexOfObject:_changedProfile.locationIcon];
    [_positionIconCollectionHandler setSelectedIndexPath:[NSIndexPath indexPathForRow:selectedIconIndex inSection:0]];
    
    _navigationIcons = [self getlocationIcons];
    _navigationIconNames = [self getlocationIconNames];
    _navigationIconImages = [self getlocationIconImages];
    _locationIconCollectionHandler = [[IconCollectionHandler alloc] initWithData:@[_navigationIconNames] collectionView:nil];
    _locationIconCollectionHandler.iconImagesData = @[_navigationIconImages];
    _locationIconCollectionHandler.roundedSquareCells = true;
    _locationIconCollectionHandler.cornerRadius = 6;
    _locationIconCollectionHandler.delegate = self;
    _locationIconCollectionHandler.hostVC = self;
    _locationIconCollectionHandler.customTitle = OALocalizedString(@"navigation_position_icon");
    _locationIconCollectionHandler.regularIconColor = [UIColor colorNamed:ACColorNameIconColorDefault];
    _locationIconCollectionHandler.selectedIconColor = UIColorFromRGB(_changedProfile.profileColor);
    [_locationIconCollectionHandler setItemSizeWithSize:156];
    [_locationIconCollectionHandler setIconSizeWithSize:52];
    selectedIconIndex = [_navigationIconNames indexOfObject:_changedProfile.navigationIcon];
    [_locationIconCollectionHandler setSelectedIndexPath:[NSIndexPath indexPathForRow:selectedIconIndex inSection:0]];
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
        [mode setViewAngleVisibility:_changedProfile.viewAngleVisibility];
        [mode setLocationRadiusVisibility:_changedProfile.locationRadiusVisibility];
        
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
    [builder setViewAngleVisibility:_changedProfile.viewAngleVisibility];
    [builder setLocationRadiusVisibility:_changedProfile.locationRadiusVisibility];
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
    return [_data sectionCount];
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_data rowCount:section];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self tableView:tableView titleForHeaderInSection:section].length > 0 ? 34.0 : UITableViewAutomaticDimension;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    OATableRowData *item = [_data itemForIndexPath:[NSIndexPath indexPathForRow:0 inSection:section]];
    if (item)
    {
        NSString *header = [item stringForKey:kCellHeaderTitleKey];
        return header ?: @"";
    }
    return @"";
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewAutomaticDimension;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath 
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    
    NSString *cellType = [[NSString alloc] initWithString:[item cellType]];
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
        cell.inputField.text = [item title];
        cell.inputField.delegate = self;
        return cell;
    }
    else if ([cellType isEqualToString:[OAColorsPaletteCell getCellIdentifier]])
    {
        OAColorsPaletteCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAColorsPaletteCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAColorsPaletteCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            cell.disableAnimationsOnStart = YES;
            [_colorCollectionHandler setCollectionView:cell.collectionView];
            [cell setCollectionHandler:_colorCollectionHandler];
            _colorCollectionHandler.hostVCOpenColorPickerButton = cell.rightActionButton;
            cell.hostVC = self;
        }
        if (cell)
        {
            cell.topLabel.text = item.title;
            [cell.bottomButton setTitle:item.descr forState:UIControlStateNormal];
            [cell.rightActionButton setImage:[UIImage templateImageNamed:@"ic_custom_add"] forState:UIControlStateNormal];
            cell.rightActionButton.tag = indexPath.section << 10 | indexPath.row;
            [cell.collectionView reloadData];
            [cell layoutIfNeeded];
            
            if (_needToScrollToSelectedColor)
            {
                NSIndexPath *selectedIndexPath = [[cell getCollectionHandler] getSelectedIndexPath];
                if (selectedIndexPath.row != NSNotFound && ![cell.collectionView.indexPathsForVisibleItems containsObject:selectedIndexPath])
                {
                    [cell.collectionView scrollToItemAtIndexPath:selectedIndexPath
                                                atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                                        animated:YES];
                }
                _needToScrollToSelectedColor = NO;
            }
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OAIconsPaletteCell getCellIdentifier]])
    {
        OAIconsPaletteCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAIconsPaletteCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconsPaletteCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            cell.hostVC = self;
            cell.useMultyLines = NO;
            cell.forceScrollOnStart = YES;
            cell.disableAnimationsOnStart = YES;
        }
        if (cell)
        {
            if ([item.key isEqualToString:kProfileIconCellKey])
            {
                [_profileIconCollectionHandler setCollectionView:cell.collectionView];
                [cell setCollectionHandler:_profileIconCollectionHandler];
                cell.topLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
                cell.topLabel.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
            }
            else if ([item.key isEqualToString:kPositionIconCellKey])
            {
                [_positionIconCollectionHandler setCollectionView:cell.collectionView];
                [cell setCollectionHandler:_positionIconCollectionHandler];
                NSInteger selectedIndex = [_locationIconNames indexOfObject:_changedProfile.locationIcon];
                if (selectedIndex == NSNotFound)
                    selectedIndex = 0;
                NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:selectedIndex inSection:0];
                [_positionIconCollectionHandler setSelectedIndexPath:selectedIndexPath];
                cell.topLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
                cell.topLabel.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
            }
            else if ([item.key isEqualToString:kLocationIconCellKey])
            {
                [_locationIconCollectionHandler setCollectionView:cell.collectionView];
                [cell setCollectionHandler:_locationIconCollectionHandler];
                NSInteger selectedIndex = [_navigationIconNames indexOfObject:_changedProfile.navigationIcon];
                if (selectedIndex == NSNotFound)
                    selectedIndex = 0;
                NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:selectedIndex inSection:0];
                [_locationIconCollectionHandler setSelectedIndexPath:selectedIndexPath];
                cell.topLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
                cell.topLabel.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
            }
            cell.topLabel.text = item.title;
            [cell.bottomButton setTitle:item.descr forState:UIControlStateNormal];
            [cell.rightActionButton setImage:[UIImage templateImageNamed:@"ic_custom_add"] forState:UIControlStateNormal];
            cell.rightActionButton.tag = indexPath.section << 10 | indexPath.row;
            [cell.collectionView reloadData];
            [cell layoutIfNeeded];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
            cell.titleLabel.textColor = (UIColor *)[item objForKey:kCellTitleColorKey];
            BOOL hideSeparator = [item boolForKey:kCellHideSeparatorKey];
            [cell setCustomLeftSeparatorInset:hideSeparator];
            cell.separatorInset = UIEdgeInsetsMake(0., hideSeparator ? CGFLOAT_MAX : 0, 0., 0.);
            cell.selectionStyle = [item boolForKey:kCellNonInteractive] ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleDefault;
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
            cell.valueLabel.text = item.descr;
            cell.leftIconView.tintColor = item.iconTintColor;
            cell.leftIconView.image = [UIImage templateImageNamed:item.iconName];
            return cell;
        }
    }
    return nil;
}

- (void) tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView * headerView = (UITableViewHeaderFooterView *) view;
        headerView.textLabel.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
    }
}

- (NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    return cell.selectionStyle == UITableViewCellSelectionStyleNone ? nil : indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.key isEqualToString:kViewAngleCellKey])
    {
        ProfileAppearanceViewAngleViewController *vc = [[ProfileAppearanceViewAngleViewController alloc] init];
        vc.delegate = self;
        vc.selectedIndex = _changedProfile.viewAngleVisibility;
        [self showModalViewController:vc];
    }
    else if ([item.key isEqualToString:kLocationRadiusCellKey])
    {
        ProfileAppearanceLocationRadiusViewController *vc = [[ProfileAppearanceLocationRadiusViewController alloc] init];
        vc.delegate = self;
        vc.selectedIndex = _changedProfile.locationRadiusVisibility;
        [self showModalViewController:vc];
    }
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

#pragma mark - OACollectionCellDelegate

- (void)onCollectionItemSelected:(NSIndexPath *)indexPath collectionView:(UICollectionView *)collectionView
{
    if (collectionView == [_colorCollectionHandler getCollectionView])
    {
        _hasChangesBeenMade = YES;
        _needToScrollToSelectedColor = YES;
        _changedProfile.color = -1;
        _changedProfile.customColor = (int)[_colorCollectionHandler getData][0][indexPath.row].value;
        
        _locationIconImages = [self getlocationIconImages];
        _navigationIconImages = [self getlocationIconImages];
        UIColor *newSelectedColor = UIColorFromRGB(_changedProfile.profileColor);;
        _profileIconImageView.tintColor = newSelectedColor;
        [self generateData];

        _profileIconCollectionHandler.selectedIconColor = newSelectedColor;
        _positionIconCollectionHandler.selectedIconColor = newSelectedColor;
        _locationIconCollectionHandler.selectedIconColor = newSelectedColor;
        _positionIconCollectionHandler.iconImagesData = @[_locationIconImages];
        _locationIconCollectionHandler.iconImagesData = @[_navigationIconImages];
        [[_profileIconCollectionHandler getCollectionView] reloadData];
        [[_positionIconCollectionHandler getCollectionView] reloadData];
        [[_locationIconCollectionHandler getCollectionView] reloadData];
        [_tableView reloadSections:[NSIndexSet indexSetWithIndex:kOptionsSectionIndex] withRowAnimation:UITableViewRowAnimationNone];
    }
    else if (collectionView == [_profileIconCollectionHandler getCollectionView])
    {
        _hasChangesBeenMade = YES;
        _changedProfile.iconName = _icons[indexPath.row];
        _profileIconImageView.image = [UIImage templateImageNamed:_changedProfile.iconName];
    }
    else if (collectionView == [_positionIconCollectionHandler getCollectionView])
    {
        _hasChangesBeenMade = YES;
        _changedProfile.locationIcon = _locationIconNames[indexPath.row];
        [self generateData];
    }
    else if (collectionView == [_locationIconCollectionHandler getCollectionView])
    {
        _hasChangesBeenMade = YES;
        _changedProfile.navigationIcon = _navigationIconNames[indexPath.row];
        [self generateData];
    }
}

- (void)reloadCollectionData
{
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kColorRowIndex inSection:kColorSectionIndex]] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - ProfileAppearanceViewAngleUpdatable

- (void) onViewAngleUpdatedWithNewValue:(NSInteger)newValue
{
    _changedProfile.viewAngleVisibility = newValue;
    [self generateData];
    [_tableView reloadSections:[NSIndexSet indexSetWithIndex:kOptionsSectionIndex] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - ProfileAppearanceLocationRadiusUpdatable

- (void) onLocationRadiusUpdatedWithNewValue:(NSInteger)newValue
{
    _changedProfile.locationRadiusVisibility = newValue;
    [self generateData];
    [_tableView reloadSections:[NSIndexSet indexSetWithIndex:kOptionsSectionIndex] withRowAnimation:UITableViewRowAnimationNone];
}

@end
