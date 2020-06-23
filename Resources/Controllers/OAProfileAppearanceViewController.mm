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

#import "OATextInputCell.h"
#import "OAColorsTableViewCell.h"
#import "OAIconsTableViewCell.h"
#import "OASeveralViewsTableViewCell.h"

#define kCellTypeInput @"OATextInputCell"
#define kCellTypeColorCollection @"colorCollectionCell"
#define kCellTypeIconCollection @"iconCollectionCell"
#define kCellTypePositionIconCollection @"positionIconCollection"
#define kIconsAtRestRow 0
#define kIconsWhileMovingRow 1

@interface OAProfileAppearanceViewController() <UITableViewDelegate, UITableViewDataSource, OAColorsTableViewCellDelegate,  OAIconsTableViewCellDelegate, OASeveralViewsTableViewCellDelegate>

@end

@implementation OAProfileAppearanceViewController
{
    OAApplicationMode *_profile;
    NSArray<NSArray *> *_data;
    
    NSArray<NSNumber *> *_colors;
    NSArray<NSString *> *_colorNames;
    NSInteger _currentColor;
    NSArray<NSString *> *_icons;
    NSInteger _currentIcon;
    EOALocationIcon _currentIconAtRest;
    EOANavigationIcon _currentIconWhileMoving;
}

- (instancetype) initWithProfile:(OAApplicationMode *)profile
{
    self = [super init];
    if (self) {
        _profile = profile;
        [self commonInit];
    }
    return self;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    [self generateData];
    
    
}

-(void) applyLocalization
{
    [_saveButton setTitle:OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
    _titleLabel.text = OALocalizedString(@"new_profile");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    [self setupNavBar];
    [self setupView];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupView];
}

- (void) setupNavBar
{
    UIImage *img = _profile.getIcon;
    _profileIconImageView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _profileIconImageView.tintColor = UIColorFromRGB(_profile.getIconColor);
    _profileIconView.layer.cornerRadius = _profileIconView.frame.size.height/2;
}

- (void) setupView
{
    NSMutableArray *tableData = [NSMutableArray array];
    
    NSMutableArray *profileNameArr = [NSMutableArray array];
    NSMutableArray *profileAppearanceArr = [NSMutableArray array];
    NSMutableArray *profileMapAppearanceArr = [NSMutableArray array];
    NSString* profileColor = OALocalizedString(_colorNames[_currentColor]);
    [profileNameArr addObject:@{
        @"type" : kCellTypeInput,
        @"title" : OALocalizedString(@"enter_profile_name"),
    }];
    [profileAppearanceArr addObject:@{
        @"type" : kCellTypeColorCollection,
        @"title" : OALocalizedString(@"select_color"),
        @"value" : profileColor,
        @"arrayToDisplay" : @"colors",
    }];
    [profileAppearanceArr addObject:@{
        @"type" : kCellTypeIconCollection,
        @"title" : OALocalizedString(@"select_icon"),
        @"value" : @"",
        @"arrayToDisplay" : @"icons",
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
    _colorNames = @[@"lightblue", @"purple", @"green", @"blue", @"red", @"yellow", @"col_magenta"];
    _currentColor = 0;
    
    _icons = @[@"ic_action_car_dark",
               @"ic_action_aircraft",
               @"ic_action_bicycle_dark",
               @"ic_action_bus_dark",
               @"ic_action_camper",
               @"ic_action_campervan",
               @"ic_action_helicopter",
               @"ic_action_horse",
               @"ic_action_monowheel",
               @"ic_action_motorcycle_dark",
               @"ic_action_offroad",
               @"ic_action_openstreetmap_logo",
               @"ic_action_pedestrian_dark",
               @"ic_action_personal_transporter",
               @"ic_action_pickup_truck",
               @"ic_action_sail_boat_dark",
               @"ic_action_scooter",
               @"ic_action_skiing",
               @"ic_action_snowmobile",
               @"ic_action_subway",
               @"ic_action_taxi",
               @"ic_action_trekking_dark",
               @"ic_action_truck_dark",
               @"ic_action_ufo",
               @"ic_action_utv",
               @"ic_action_wagon",
               @"ic_action_taxi",
               @"ic_action_trekking_dark",
               @"ic_action_truck_dark",
               @"ic_action_openstreetmap_logo",
               @"ic_action_snowmobile",
               @"ic_action_subway",
               @"ic_action_taxi",
               @"ic_action_trekking_dark",
               @"ic_action_camper",
               @"ic_action_offroad"];
    _currentIcon = 0;
    
    _currentIconAtRest = LOCATION_ICON_DEFAULT;
    _currentIconWhileMoving = NAVIGATION_ICON_DEFAULT;
}

- (NSArray<UIImage *> *) getIconsAtRest
{
    UIColor *currColor = UIColorFromRGB(_colors[_currentColor].integerValue);
    return @[[OALocationIcon getIcon:LOCATION_ICON_DEFAULT color:currColor], [OALocationIcon getIcon:LOCATION_ICON_CAR color:currColor], [OALocationIcon getIcon:LOCATION_ICON_BICYCLE color:currColor]];
}

- (NSArray<UIImage *> *) getNavIcons
{
    UIColor *currColor = UIColorFromRGB(_colors[_currentColor].integerValue);
    return @[[OANavigationIcon getIcon:NAVIGATION_ICON_DEFAULT color:currColor], [OANavigationIcon getIcon:NAVIGATION_ICON_NAUTICAL color:currColor], [OANavigationIcon getIcon:NAVIGATION_ICON_CAR color:currColor]];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (IBAction) cancelButtonClicked:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction) saveButtonClicked:(id)sender
{
    NSLog(@"Save profile");
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

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 1 && indexPath.row == 1)
    {
        return 432.;
    }
    return 44.;
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
        }
        cell.inputField.placeholder = item[@"title"];
        return cell;
    }
    else if ([cellType isEqualToString:kCellTypeColorCollection])
    {
        static NSString* const identifierCell = @"OAColorsTableViewCell";
        OAColorsTableViewCell *cell = nil;
        cell = (OAColorsTableViewCell*)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAColorsTableViewCell" owner:self options:nil];
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
            cell.currentColor = _currentColor;
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
            cell.currentColor = [_colors[_currentColor] integerValue];
            cell.currentIcon = _currentIcon;
            [cell.collectionView reloadData];
            [cell layoutIfNeeded];
        }
        return cell;
    }
    else if ([cellType isEqualToString:kCellTypePositionIconCollection])
    {
        static NSString* const identifierCell = @"OASeveralViewsTableViewCell";
        OASeveralViewsTableViewCell *cell = nil;
        cell = (OASeveralViewsTableViewCell*)[tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASeveralViewsTableViewCell" owner:self options:nil];
            cell = (OASeveralViewsTableViewCell *)[nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsZero;
        }
        if (cell)
        {
            cell.dataArray = indexPath.row == kIconsAtRestRow ? [self getIconsAtRest] : [self getNavIcons];
            cell.titleLabel.text = item[@"title"];
            cell.currentColor = [_colors[_currentColor] intValue];
            [cell.collectionView reloadData];
            cell.delegate = self;
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

#pragma mark - OAColorsTableViewCellDelegate

- (void)colorChanged:(NSInteger)tag
{
    _currentColor = tag;
    
    [self setupView];
    _profileIconImageView.tintColor = UIColorFromRGB([_colors[_currentColor] intValue]);
    [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1], [NSIndexPath indexPathForRow:1 inSection:1], [NSIndexPath indexPathForRow:0 inSection:2], [NSIndexPath indexPathForRow:1 inSection:2]] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - OAIconsTableViewCellDelegate

- (void)iconChanged:(NSInteger)tag
{
    _currentIcon = tag;
    
    UIImage *img = nil;
    NSString *imgName = _icons[_currentIcon];
    if (imgName)
        img = [UIImage imageNamed:imgName];
    _profileIconImageView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [_tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:1]] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - OASeveralViewsTableViewCellDelegate

- (void)mapIconChanged:(NSInteger)tag
{
    
}

@end
