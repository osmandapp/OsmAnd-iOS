//
//  OAOsmEditingSettingsViewController.m
//  OsmAnd
//
//  Created by Paul on 8/29/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAOsmEditingSettingsViewController.h"
#import "OAOsmAccountSettingsViewController.h"
#import "OATitleRightIconCell.h"
#import "OASwitchTableViewCell.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OsmAndApp.h"
#import "OAOsmEditsListViewController.h"
#import "OAButtonCell.h"
#import "OAColors.h"
#import "OAMenuSimpleCellNoIcon.h"

@interface OAOsmEditingSettingsViewController () <OAAccontSettingDelegate>

@end

@implementation OAOsmEditingSettingsViewController
{
    NSArray<NSArray *> *_data;
    
    OAAppSettings *_settings;
}

static const NSInteger credentialsSectionIndex = 0;
static const NSInteger actionsSectionIndex = 2;

- (void) applyLocalization
{
    _titleView.text = OALocalizedString(@"product_title_osm_editing");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    _settings = [OAAppSettings sharedManager];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.estimatedRowHeight = kEstimatedRowHeight;
    
    self.tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:OALocalizedString(@"osm_editing_settings_descr") font:[UIFont systemFontOfSize:15] textColor:UIColorFromRGB(color_text_footer) lineSpacing:0.0 isTitle:NO];
    
}

- (OAButtonCell *) getButtonCell
{
    OAButtonCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OAButtonCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAButtonCell getCellIdentifier] owner:self options:nil];
        cell = (OAButtonCell *)[nib objectAtIndex:0];
        [cell.button setTitleColor:UIColorFromRGB(color_primary_purple) forState:UIControlStateNormal];
    }
    if (cell)
    {
        [cell.button setTitle:_settings.osmUserName.get.length == 0 ? OALocalizedString(@"shared_string_account_add") : _settings.osmUserName.get forState:UIControlStateNormal];
        [cell.button removeTarget:self action:NULL forControlEvents:UIControlEventTouchDown];
        [cell.button addTarget:self action:@selector(editPressed) forControlEvents:UIControlEventTouchDown];
        [cell showImage:NO];
    }
    return cell;
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
    [self applySafeAreaMargins];
    NSMutableArray<NSArray *> *sectionArr = [NSMutableArray new];
    NSMutableArray *dataArr = [NSMutableArray new];
    
    [dataArr addObject:
     @{
         @"name" : @"edit_credentials",
         @"type" : [OAButtonCell getCellIdentifier]
     }];
    
    [sectionArr addObject:[NSArray arrayWithArray:dataArr]];
    
    [dataArr removeAllObjects];
    
    [dataArr addObject:
     @{
         @"name" : @"offline_editing",
         @"type" : [OASwitchTableViewCell getCellIdentifier],
         @"title" : OALocalizedString(@"osm_offline_editing"),
         @"value" : @(_settings.offlineEditing.get)
     }];
    
    [sectionArr addObject:[NSArray arrayWithArray:dataArr]];
    
    [dataArr removeAllObjects];
    
    NSString *menuPath = [NSString stringWithFormat:@"%@ — %@ — %@", OALocalizedString(@"menu"), OALocalizedString(@"menu_my_places"), OALocalizedString(@"osm_edits_title")];
    NSString *actionsDescr = [NSString stringWithFormat:OALocalizedString(@"osm_editing_access_descr"), menuPath];
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:actionsDescr attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:15], NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer)}];
    [str addAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold]} range:[actionsDescr rangeOfString:menuPath]];
    
    [dataArr addObject:
     @{
         @"type" : [OAMenuSimpleCellNoIcon getCellIdentifier],
         @"title" : str
     }];
    
    [dataArr addObject:
     @{
         @"type" : [OATitleRightIconCell getCellIdentifier],
         @"title" : OALocalizedString(@"osm_edits_title"),
         @"img" : @"ic_custom_folder",
         @"name" : @"open_edits"
     }];
    
    [sectionArr addObject:[NSArray arrayWithArray:dataArr]];
    
    _data = sectionArr;
    
    [self.tableView reloadData];
    self.backButton.imageView.image = [self.backButton.imageView.image imageFlippedForRightToLeftLayoutDirection];
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

- (void) applyParameter:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        UISwitch *sw = (UISwitch *) sender;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
        NSDictionary *item = [self getItem:indexPath];

        BOOL isChecked = ((UISwitch *) sender).on;
        NSString *name = item[@"name"];
        
        if ([name isEqualToString:@"offline_editing"])
            [_settings.offlineEditing set:isChecked];
    }
}

- (void) editPressed
{
    OAOsmAccountSettingsViewController *accountSettings = [[OAOsmAccountSettingsViewController alloc] init];
    accountSettings.delegate = self;
    [self presentViewController:accountSettings animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *type = item[@"type"];
    
    if ([type isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
            cell.textView.numberOfLines = 0;
        }
        
        if (cell)
        {
            [cell.textView setText: item[@"title"]];
            id v = item[@"value"];
            
            cell.switchView.on = [v boolValue];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([type isEqualToString:[OAMenuSimpleCellNoIcon getCellIdentifier]])
    {
        OAMenuSimpleCellNoIcon* cell = [tableView dequeueReusableCellWithIdentifier:[OAMenuSimpleCellNoIcon getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMenuSimpleCellNoIcon getCellIdentifier] owner:self options:nil];
            cell = (OAMenuSimpleCellNoIcon *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., DBL_MAX, 0., 0.);
            cell.descriptionView.hidden = YES;
        }
        if (cell)
        {
            cell.textView.attributedText = item[@"title"];
        }
        return cell;
    }
    else if ([type isEqualToString:[OATitleRightIconCell getCellIdentifier]])
    {
        OATitleRightIconCell* cell = [tableView dequeueReusableCellWithIdentifier:[OATitleRightIconCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleRightIconCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleRightIconCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 16.0, 0.0, 0.0);
            cell.titleView.textColor = UIColorFromRGB(color_primary_purple);
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.titleView.font = [UIFont systemFontOfSize:17. weight:UIFontWeightSemibold];
        }
        cell.titleView.text = item[@"title"];
        [cell.iconView setImage:[UIImage templateImageNamed:item[@"img"]]];
        return cell;
    }
    else if ([type isEqualToString:[OAButtonCell getCellIdentifier]])
    {
        return [self getButtonCell];
    }
    return nil;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == credentialsSectionIndex)
        return OALocalizedString(@"shared_string_account");
    else if (section == actionsSectionIndex)
        return OALocalizedString(@"actions");
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    [header.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *)view;
    [footer.textLabel setTextColor:UIColorFromRGB(color_text_footer)];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:OALocalizedString(@"osm_editing_settings_descr") font:[UIFont systemFontOfSize:15] textColor:UIColorFromRGB(color_text_footer) lineSpacing:0.0 isTitle:NO];
    } completion:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    
    if ([item[@"name"] isEqualToString:@"open_edits"])
    {
        UITabBarController* myPlacesViewController = [[UIStoryboard storyboardWithName:@"MyPlaces" bundle:nil] instantiateInitialViewController];
        [myPlacesViewController setSelectedIndex:2];
        
        OAOsmEditsListViewController *osmEdits = myPlacesViewController.viewControllers[2];
        if (osmEdits == nil)
            return;

        [osmEdits setShouldPopToParent:YES];
        
        [self.navigationController pushViewController:myPlacesViewController animated:YES];
    }
    else if ([item[@"name"] isEqualToString:@"edit_credentials"])
    {
        [self editPressed];
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
}

#pragma mark - OAAccontSettingDelegate

- (void)onAccountInformationUpdated
{
    [self.tableView reloadData];
}

@end
