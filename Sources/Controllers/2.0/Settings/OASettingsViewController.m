//
//  OASettingsViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 06.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OASettingsViewController.h"
#import "OASettingsTableViewCell.h"
#import "OASettingsTitleTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAIAPHelper.h"
#import "OAUtilities.h"
#import "OANavigationSettingsViewController.h"
#import "OATripRecordingSettingsViewController.h"
#import "OAOsmEditingSettingsViewController.h"
#import "OAApplicationMode.h"
#import "OAMapViewTrackingUtilities.h"
#import "SunriseSunset.h"
#import "OADayNightHelper.h"
#import "OAPointDescription.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapPanelViewController.h"
#import "OALocationServices.h"
#import "OsmAndApp.h"
#import "OALocationConvert.h"
#import "OATableViewCustomFooterView.h"
#import "OAColors.h"

#import "OACreateProfileViewController.h"
#import "OARearrangeProfilesViewController.h"
#import "OAProfileNavigationSettingsViewController.h"
#import "OAProfileGeneralSettingsViewController.h"
#import "OAGlobalSettingsViewController.h"

#define kCellTypeSwitch @"switch"
#define kCellTypeSingleSelectionList @"single_selection_list"
#define kCellTypeMultiSelectionList @"multi_selection_list"
#define kCellTypeCheck @"check"
#define kCellTypeSettings @"settings"
#define kFooterId @"TableViewSectionFooter"

@interface OASettingsViewController ()

@property NSArray* data;

@end

@implementation OASettingsViewController

- (id) initWithSettingsType:(EOASettingsScreen)settingsType
{
    self = [super init];
    if (self)
    {
        _settingsType = settingsType;
    }
    return self;
}

- (void) applyLocalization
{
    _titleView.text = OALocalizedString(@"sett_settings");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.settingsTableView.rowHeight = UITableViewAutomaticDimension;
    self.settingsTableView.estimatedRowHeight = kEstimatedRowHeight;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    [self setupView];
}

-(UIView *) getTopView
{
    return _navBarView;
}

- (void) setupView
{
    if ([self.backButton isDirectionRTL])
        self.backButton.transform = CGAffineTransformMakeRotation(M_PI);
    OAAppSettings* settings = [OAAppSettings sharedManager];
    OAApplicationMode *appMode = settings.applicationMode;
    switch (self.settingsType)
    {
        case EOASettingsScreenMain:
        {
            NSMutableArray *arr = [NSMutableArray arrayWithObjects:@{
                                                                     @"name" : @"global_settings",
                                                                     @"title" : OALocalizedString(@"global_settings"),
                                                                     @"description" : OALocalizedString(@"global_settings_descr"),
                                                                     @"img" : @"menu_cell_pointer.png",
                                                                     @"type" : kCellTypeCheck },
                                                                    @{
                                                                     @"name" : @"general_settings",
                                                                     @"title" : OALocalizedString(@"general_settings_2"),
                                                                     @"description" : OALocalizedString(@"general_settings_descr"),
                                                                     @"img" : @"menu_cell_pointer.png",
                                                                     @"type" : kCellTypeCheck },
                                                                    @{
                                                                     @"name" : @"routing_settings",
                                                                     @"title" : OALocalizedString(@"routing_settings_2"),
                                                                     @"description" : OALocalizedString(@"routing_settings_descr"),
                                                                     @"img" : @"menu_cell_pointer.png",
                                                                     @"type" : kCellTypeCheck },
                                                                    @{
                                                                     @"name" : @"new_profile",
                                                                     @"title" : OALocalizedString(@"new_profile"),
                                                                     @"description" : @"",
                                                                     @"img" : @"ic_custom_add.png",
                                                                     @"type" : kCellTypeCheck },
                                                                    @{
                                                                     @"name" : @"edit_profile_list",
                                                                     @"title" : OALocalizedString(@"edit_profile_list"),
                                                                     @"description" : @"",
                                                                     @"img" : @"ic_custom_edit.png",
                                                                     @"type" : kCellTypeCheck },nil];
            
            BOOL shouldAddHeader = YES;
            if ([[OAIAPHelper sharedInstance].trackRecording isActive])
            {
                NSMutableDictionary *pluginsRow = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                                @"name" : @"track_recording",
                                                                                                @"title" : OALocalizedString(@"product_title_track_recording"),
                                                                                                @"description" : @"",
                                                                                                @"img" : @"menu_cell_pointer.png",
                                                                                                @"type" : kCellTypeCheck
                                                                                                }];
                shouldAddHeader = NO;
                pluginsRow[@"header"] = OALocalizedString(@"plugins");
                [arr addObject:pluginsRow];
            }
            if ([[OAIAPHelper sharedInstance].osmEditing isActive])
            {
                NSMutableDictionary *pluginsRow = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                                                  @"name" : @"osm_editing",
                                                                                                  @"title" : OALocalizedString(@"product_title_osm_editing"),
                                                                                                  @"description" : @"",
                                                                                                  @"img" : @"menu_cell_pointer.png",
                                                                                                  @"type" : kCellTypeCheck,
                                                                                                  }];
                if (shouldAddHeader)
                    pluginsRow[@"header"] = OALocalizedString(@"plugins");
                
                shouldAddHeader = NO;
                [arr addObject:pluginsRow];
            }
            self.data = [NSArray arrayWithArray:arr];
            break;
        }
        case EOASettingsScreenAppMode:
        {
            _titleView.text = OALocalizedString(@"settings_preset");
            NSMutableArray *arr = [NSMutableArray array];
            NSArray<OAApplicationMode *> *availableModes = [OAApplicationMode values];
            for (OAApplicationMode *mode in availableModes)
            {
                [arr addObject: @{
                                  @"name" : mode.stringKey,
                                  @"title" : mode.name,
                                  @"value" : @"",
                                  @"img" : appMode == mode ? @"menu_cell_selected.png" : @"",
                                  @"type" : kCellTypeCheck }];
            }
            self.data = [NSArray arrayWithArray:arr];
            
            break;
        }
        default:
            break;
    }
    
    [self.settingsTableView setDataSource: self];
    [self.settingsTableView setDelegate:self];
    self.settingsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.settingsTableView reloadData];
    [self.settingsTableView reloadInputViews];
    [self.settingsTableView setSeparatorInset:UIEdgeInsetsMake(0.0, 16.0, 0.0, 0.0)];
    [self.settingsTableView registerClass:OATableViewCustomFooterView.class forHeaderFooterViewReuseIdentifier:kFooterId];
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    if ([self sectionsOnly])
        return _data[indexPath.section];
    else
        return _data[indexPath.row];
}

- (void) applyParameter:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        UISwitch *sw = (UISwitch *) sender;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
        NSDictionary *item = [self getItem:indexPath];
        NSString *name = item[@"name"];
        if (name)
        {
            OAAppSettings *settings = [OAAppSettings sharedManager];
            BOOL isChecked = ((UISwitch *) sender).on;
            if ([name isEqualToString:@"do_not_show_discount"])
            {
                [settings setSettingDoNotShowPromotions:isChecked];
            }
            else if ([name isEqualToString:@"do_not_send_anonymous_data"])
            {
                [settings setSettingDoNotUseAnalytics:isChecked];
            }
            else if ([name isEqualToString:@"allow_3d"])
            {
                [settings.settingAllow3DView set:isChecked];
                if (!isChecked)
                {
                    OsmAndAppInstance app = OsmAndApp.instance;
                    if (app.mapMode == OAMapModeFollow)
                        [app setMapMode:OAMapModePositionTrack];
                    else
                        [app.mapModeObservable notifyEvent];
                }
            }
        }
    }
}

- (BOOL) sectionsOnly
{
    return _settingsType == EOASettingsScreenMain;
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([self sectionsOnly])
        return _data.count;
    else
        return 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self sectionsOnly])
        return 1;
    else
        return _data.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *type = item[@"type"];
    
    if ([type isEqualToString:kCellTypeSwitch])
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
            id value = item[@"value"];
            [cell.switchView removeTarget:NULL action:NULL forControlEvents:UIControlEventAllEvents];
            cell.switchView.on = [value boolValue];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([type isEqualToString:kCellTypeSingleSelectionList] || [type isEqualToString:kCellTypeMultiSelectionList] || [type isEqualToString:kCellTypeSettings])
    {
        static NSString* const identifierCell = @"OASettingsTableViewCell";
        OASettingsTableViewCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsCell" owner:self options:nil];
            cell = (OASettingsTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [cell.textView setText: item[@"title"]];
            [cell.descriptionView setText: item[@"value"]];
            if (item[@"img"])
                [cell.iconView setImage:[UIImage imageNamed:item[@"img"]]];
            else
                [cell.iconView setImage:nil];
        }
        return cell;
    }
    else if ([type isEqualToString:kCellTypeCheck])
    {
        static NSString* const identifierCell = @"OASettingsTitleTableViewCell";
        OASettingsTitleTableViewCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsTitleCell" owner:self options:nil];
            cell = (OASettingsTitleTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [cell.textView setText: item[@"title"]];
            if (item[@"img"])
            {
                if ([item[@"img"] isEqualToString:(@"menu_cell_pointer.png")])
                    [cell.iconView setImage:[UIImage imageNamed:item[@"img"]].imageFlippedForRightToLeftLayoutDirection];
                else
                    [cell.iconView setImage:[UIImage imageNamed:item[@"img"]]];
            }
            else
            {
                [cell.iconView setImage:nil];
            }
        }
        return cell;
    }
    return nil;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([self sectionsOnly])
    {
        NSDictionary *item = _data[section];
        return item[@"header"];
    }
    return nil;
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if ([self sectionsOnly])
    {
        NSDictionary *item = _data[section];
        return item[@"description"];
    }
    else
    {
        return nil;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if ([self sectionsOnly])
    {
        NSDictionary *item = _data[section];
        NSString *text = item[@"description"];
        OATableViewCustomFooterView *vw = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kFooterId];
        NSString *url = item[@"url"];
        if (url)
        {
            NSURL *URL = [NSURL URLWithString:url];
            UIFont *textFont = [UIFont systemFontOfSize:13];
            NSMutableAttributedString * str = [[NSMutableAttributedString alloc] initWithString:OALocalizedString(@"shared_string_read_more") attributes:@{NSFontAttributeName : textFont}];
            [str addAttribute:NSLinkAttributeName value:URL range: NSMakeRange(0, str.length)];
            text = [text stringByAppendingString:@" "];
            NSMutableAttributedString *textStr = [[NSMutableAttributedString alloc] initWithString:text
                                                                                        attributes:@{NSFontAttributeName : textFont,
                                                                                                     NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer)}];
            [textStr appendAttributedString:str];
            vw.label.attributedText = textStr;
        }
        else
        {
            vw.label.text = text;
        }
        return vw;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if ([self sectionsOnly])
    {
        NSDictionary *item = _data[section];
        NSString *text = item[@"description"];
        NSString *url = item[@"url"];
        return [OATableViewCustomFooterView getHeight:url ? [NSString stringWithFormat:@"%@ %@", text, OALocalizedString(@"shared_string_read_more")] : text width:tableView.bounds.size.width];
    }
    else
    {
        return 0.01;
    }
}

#pragma mark - UITableViewDelegate

- (nullable NSIndexPath *) tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
    NSDictionary *item = [self getItem:indexPath];
    BOOL nonClickable = item[@"nonclickable"] != nil;
    return nonClickable ? nil : indexPath;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *name = item[@"name"];
    if (name)
    {
        switch (self.settingsType)
        {
            case EOASettingsScreenMain:
                [self selectSettingMain:name];
                break;
            case EOASettingsScreenAppMode:
                [self selectAppMode:name];
                break;
            default:
                break;
        }
    }
}

- (void) selectSettingMain:(NSString *)name
{
    if ([name isEqualToString:@"global_settings"])
    {
        OAGlobalSettingsViewController* globalSettingsViewController = [[OAGlobalSettingsViewController alloc] initWithSettingsType:EOAGlobalSettingsMain];
        [self.navigationController pushViewController:globalSettingsViewController animated:YES];
    }
    else if ([name isEqualToString:@"general_settings"])
    {
        OAProfileGeneralSettingsViewController* settingsViewController = [[OAProfileGeneralSettingsViewController alloc] initWithAppMode:OAApplicationMode.CAR];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([name isEqualToString:@"routing_settings"])
    {
        // TODO: pass selected mode after refactoring
        OAProfileNavigationSettingsViewController* settingsViewController = [[OAProfileNavigationSettingsViewController alloc] initWithAppMode:OAApplicationMode.CAR];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([name isEqualToString:@"track_recording"])
    {
        OATripRecordingSettingsViewController* settingsViewController = [[OATripRecordingSettingsViewController alloc] initWithSettingsType:kTripRecordingSettingsScreenGeneral];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([name isEqualToString:@"osm_editing"])
    {
        OAOsmEditingSettingsViewController* settingsViewController = [[OAOsmEditingSettingsViewController alloc] init];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([name isEqualToString:@"new_profile"])
    {
        OACreateProfileViewController* createProfileViewController = [[OACreateProfileViewController alloc] init];
        [self.navigationController pushViewController:createProfileViewController animated:YES];
    }
    else if ([name isEqualToString:@"edit_profile_list"])
    {
        OARearrangeProfilesViewController* rearrangeProfilesViewController = [[OARearrangeProfilesViewController alloc] init];
        [self.navigationController pushViewController:rearrangeProfilesViewController animated:YES];
    }
}

- (void) selectSettingGeneral:(NSString *)name
{
    if ([name isEqualToString:@"settings_preset"])
    {
        OASettingsViewController* settingsViewController = [[OASettingsViewController alloc] initWithSettingsType:EOASettingsScreenAppMode];
        [self.navigationController pushViewController:settingsViewController animated:YES];
    }
    else if ([name isEqualToString:@"do_not_show_discount"])
    {
    }
    else if ([name isEqualToString:@"do_not_send_anonymous_data"])
    {
    }
}

- (void) selectAppMode:(NSString *)name
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    OAApplicationMode *mode = [OAApplicationMode valueOfStringKey:name def:[OAApplicationMode DEFAULT]];
    settings.defaultApplicationMode = mode;
    settings.applicationMode = mode;
    [self backButtonClicked:nil];
}

@end
