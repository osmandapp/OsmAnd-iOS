//
//  OAConfigureProfileViewController.m
//  OsmAnd
//
//  Created by Paul on 01.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAConfigureProfileViewController.h"
#import "OAApplicationMode.h"
#import "Localization.h"
#import "OAColors.h"
#import "OATableViewCustomHeaderView.h"
#import "OASwitchTableViewCell.h"
#import "OAIconTextDescCell.h"
#import "OAAutoObserverProxy.h"
#import "OsmAndApp.h"

#import "OAProfileGeneralSettingsViewController.h"
#import "OAProfileNavigationSettingsViewController.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAProfileAppearanceViewController.h"

#define kSidePadding 16.

#define kHeaderId @"TableViewSectionHeader"
#define kSwitchCell @"OASettingSwitchCell"
#define kIconTitleDescrCell @"OAIconTextDescCell"

typedef NS_ENUM(NSInteger, EOADashboardScreenType) {
    EOADashboardScreenTypeNone = 0,
    EOADashboardScreenTypeMap,
    EOADashboardScreenTypeScreen
};

@interface OAConfigureProfileViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAConfigureProfileViewController
{
    OAApplicationMode *_appMode;
    
    NSArray<NSString *> *_sectionHeaderTitles;
    NSArray<NSString *> *_sectionFooterTitles;
    
    NSArray<NSArray *> *_data;
    
    OAAutoObserverProxy* _appModeChangeObserver;
    
    EOADashboardScreenType _screenToOpen;
}

- (instancetype) initWithAppMode:(OAApplicationMode *)mode
{
    self = [super init];
    if (self) {
        _appMode = mode;
//        [self generateData];
    }
    return self;
}

- (void) generateData
{
    NSMutableArray<NSArray *> *data = [NSMutableArray new];
    
    [data addObject:@[
        @{
            @"type" : kSwitchCell,
            @"title" : OALocalizedString(@"shared_string_enabled")
        }
    ]];
    
    [data addObject:@[
        @{
            @"type" : kIconTitleDescrCell,
            @"title" : OALocalizedString(@"general_settings_2"),
            @"descr" : OALocalizedString(@"general_settings_descr"),
            @"img" : @"left_menu_icon_settings",
            @"key" : @"general_settings"
        },
        @{
            @"type" : kIconTitleDescrCell,
            @"title" : OALocalizedString(@"routing_settings_2"),
            @"descr" : OALocalizedString(@"routing_settings_descr"),
            @"img" : @"left_menu_icon_navigation",
            @"key" : @"nav_settings"
        },
        @{
            @"type" : kIconTitleDescrCell,
            @"title" : OALocalizedString(@"configure_map"),
            @"descr" : OALocalizedString(@"configure_map_descr"),
            @"img" : @"left_menu_icon_map",
            @"key" : @"configure_map"
        },
        @{
            @"type" : kIconTitleDescrCell,
            @"title" : OALocalizedString(@"layer_map_appearance"),
            @"descr" : OALocalizedString(@"configure_screen_descr"),
            @"img" : @"left_menu_configure_screen",
            @"key" : @"configure_screen"
        },
        @{
            @"type" : kIconTitleDescrCell,
            @"title" : OALocalizedString(@"profile_appearance"),
            @"descr" : OALocalizedString(@"profile_appearance_descr"),
            @"img" : _appMode.getIconName,
            @"key" : @"profile_appearance"
        },
        // TODO: add ui customization
//        @{
//            @"type" : kIconTitleDescrCell,
//            @"title" : OALocalizedString(@"ui_customization"),
//            @"descr" : OALocalizedString(@"ui_customization_descr"),
//            @"img" : todo,
//            @"key" : @"ui_customization"
//        }
    ]];
    
    _data = data;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupTableHeaderView];
    [self generateData];
    [self.tableView reloadData];
}

- (void) applyLocalization
{
    self.titleLabel.text = _appMode.name;
}

- (UIView *)setupTableHeaderView
{
    return self.tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:self.getTableHeaderTitle font:[UIFont systemFontOfSize:34.0 weight:UIFontWeightBold] titntColor:UIColorFromRGB(_appMode.getIconColor) icon:_appMode.getIconName];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _appModeChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                       withHandler:@selector(onAvailableAppModesChanged)
                                                        andObserve:[OsmAndApp instance].availableAppModesChangedObservable];
    
    _sectionHeaderTitles = @[OALocalizedString(@"configure_profile"), OALocalizedString(@"profile_settings"), OALocalizedString(@"plugins"), OALocalizedString(@"actions")];
    _sectionFooterTitles = @[@"", OALocalizedString(@"profile_sett_descr"), OALocalizedString(@"plugin_settings_descr"), OALocalizedString(@"export_profile_descr")];
    
    self.backButton.hidden = YES;
    self.backImageButton.hidden = NO;
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:kHeaderId];
}

- (void)openDashboardScreen:(EOADashboardScreenType)type
{
    if (type == EOADashboardScreenTypeMap)
        [OARootViewController.instance.mapPanel mapSettingsButtonClick:nil mode:_appMode];
    else if (type == EOADashboardScreenTypeScreen)
        [OARootViewController.instance.mapPanel showConfigureScreen:_appMode];
}

- (void) onAvailableAppModesChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self openDashboardScreen:_screenToOpen];
        _screenToOpen = EOADashboardScreenTypeNone;
    });
}

- (void) dealloc
{
    [_appModeChangeObserver detach];
}

- (NSString *)getTableHeaderTitle
{
    return _appMode.name;
}

- (void) onModeSwitchPressed:(UISwitch *)sender
{
    [OAApplicationMode changeProfileAvailability:_appMode isSelected:sender.isOn];
}

- (void) setCurrentModeActive:(EOADashboardScreenType)type
{
    OAAppSettings.sharedManager.applicationMode = _appMode;
    if (![OAApplicationMode.values containsObject:_appMode])
    {
        _screenToOpen = type;
        [OAApplicationMode changeProfileAvailability:_appMode isSelected:YES];
    }
    else
    {
        [self openDashboardScreen:type];
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self setupTableHeaderView];
        [self.tableView reloadData];
    } completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    OATableViewCustomHeaderView *vw = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kHeaderId];
    vw.label.text = nil;
    vw.label.attributedText = nil;
    
    NSString *title = _sectionHeaderTitles[section];
    
    if (section == 0)
    {
        [vw setYOffset:6.];
        UIFont *labelFont = [UIFont systemFontOfSize:15.0];
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        [style setLineSpacing:6];
        vw.label.attributedText = [[NSAttributedString alloc] initWithString:title attributes:@{NSParagraphStyleAttributeName : style, NSFontAttributeName : labelFont, NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer)}];
    }
    else
    {
        [vw setYOffset:17.];
        vw.label.text = [title upperCase];
    }
    [vw sizeToFit];
    return vw;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat textWidth = self.tableView.bounds.size.width - (kSidePadding + OAUtilities.getLeftMargin) * 2;
    if (section == 0)
        return [OATableViewCustomHeaderView getHeight:_sectionHeaderTitles[section] width:textWidth yOffset:6. font:[UIFont systemFontOfSize:15.0]] + 10.;
    
    return [OATableViewCustomHeaderView getHeight:_sectionHeaderTitles[section] width:textWidth];
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return section == 0 ? 0.01 : [OAUtilities calculateTextBounds:_sectionFooterTitles[section] width:DeviceScreenWidth - (16 + OAUtilities.getLeftMargin) * 2 font:[UIFont systemFontOfSize:13.]].height + 16.;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSString *title = _sectionFooterTitles[section];
    return title.length > 0 ? title : nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    if ([item[@"type"] isEqualToString:kSwitchCell])
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
            [cell.switchView removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
            cell.switchView.on = [OAApplicationMode.values containsObject:_appMode];
            [cell.switchView addTarget:self action:@selector(onModeSwitchPressed:) forControlEvents:UIControlEventValueChanged];
            cell.textView.text = item[@"title"];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:kIconTitleDescrCell])
    {
        OAIconTextDescCell* cell;
        cell = (OAIconTextDescCell *)[tableView dequeueReusableCellWithIdentifier:@"OAIconTextDescCell"];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextDescCell" owner:self options:nil];
            cell = (OAIconTextDescCell *)[nib objectAtIndex:0];
            cell.textView.numberOfLines = 0;
            cell.arrowIconView.image = [cell.arrowIconView.image imageFlippedForRightToLeftLayoutDirection];
            [cell.iconView setTintColor:UIColorFromRGB(color_icon_inactive)];
            cell.descView.font = [UIFont systemFontOfSize:15.];
            cell.separatorInset = UIEdgeInsetsMake(0., 64., 0., 0.);
        }
        if (cell)
        {
            [cell.textView setText:item[@"title"]];
            [cell.descView setText:item[@"descr"]];
            [cell.iconView setImage:[[UIImage imageNamed:item[@"img"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
            
            if ([cell needsUpdateConstraints])
                [cell setNeedsUpdateConstraints];
        }
        return cell;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][indexPath.row];
    NSString *key = item[@"key"];
    if ([key isEqualToString:@"general_settings"])
    {
        OAProfileGeneralSettingsViewController* settingsViewController = [[OAProfileGeneralSettingsViewController alloc] initWithAppMode:_appMode];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([key isEqualToString:@"nav_settings"])
    {
        OAProfileNavigationSettingsViewController* settingsViewController = [[OAProfileNavigationSettingsViewController alloc] initWithAppMode:_appMode];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([key isEqualToString:@"configure_map"])
    {
        [self setCurrentModeActive:EOADashboardScreenTypeMap];
        [self.navigationController popToViewController:OARootViewController.instance animated:NO];
    }
    else if ([key isEqualToString:@"configure_screen"])
    {
        [self setCurrentModeActive:EOADashboardScreenTypeScreen];
        [self.navigationController popToViewController:OARootViewController.instance animated:NO];
    }
    else if ([key isEqualToString:@"profile_appearance"])
    {
        OAProfileAppearanceViewController *profileAppearance = [[OAProfileAppearanceViewController alloc] initWithProfile:_appMode];
        [self.navigationController pushViewController:profileAppearance animated:YES];
    }
//    else if ([key isEqualToString:@"ui_customization"])
//    {
//
//    }
//  else if ([name isEqualToString:@"track_recording"])
//    {
//        OATripRecordingSettingsViewController* settingsViewController = [[OATripRecordingSettingsViewController alloc] initWithSettingsType:kTripRecordingSettingsScreenGeneral];
//        [self.navigationController pushViewController:settingsViewController animated:YES];
//    }
//    else if ([name isEqualToString:@"osm_editing"])
//    {
//        OAOsmEditingSettingsViewController* settingsViewController = [[OAOsmEditingSettingsViewController alloc] init];
//        [self.navigationController pushViewController:settingsViewController animated:YES];
//    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
