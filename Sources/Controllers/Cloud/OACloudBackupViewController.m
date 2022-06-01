//
//  OACloudBackupViewController.m
//  OsmAnd Maps
//
//  Created by Yuliia Stetsenko on 19.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OACloudBackupViewController.h"
#import "Localization.h"
#import "OAColors.h"

#import "OAFilledButtonCell.h"
#import "OATwoFilledButtonsTableViewCell.h"
#import "OALargeImageTitleDescrTableViewCell.h"
#import "OATitleRightIconCell.h"
#import "OAButtonRightIconCell.h"
#import "OAMultiIconTextDescCell.h"
#import "OAIconTitleValueCell.h"
#import "OATitleDescrRightIconTableViewCell.h"
#import "OAMainSettingsViewController.h"

@interface OACloudBackupViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *navBarBackgroundView;
@property (weak, nonatomic) IBOutlet UILabel *navBarTitle;
@property (weak, nonatomic) IBOutlet UIButton *backImgButton;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;
@property (weak, nonatomic) IBOutlet UITableView *tblView;

@end

@implementation OACloudBackupViewController
{
    NSArray<NSDictionary *> *_data;
}

- (instancetype)init
{
    self = [super initWithNibName:@"OACloudBackupViewController" bundle:nil];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self generateData];
    
    self.tblView.delegate = self;
    self.tblView.dataSource = self;
    self.tblView.estimatedRowHeight = 44.;
    self.tblView.rowHeight = UITableViewAutomaticDimension;
}

- (void)applyLocalization
{
    self.navBarTitle.text = OALocalizedString(@"backup_and_restore");
}

- (void)generateData
{
    NSMutableArray<NSDictionary *> *result = [NSMutableArray array];
    
    // No backup case
    NSArray <NSDictionary *> *noBackupRows = @[
        @{
            @"cellId": OALargeImageTitleDescrTableViewCell.getCellIdentifier,
            @"name": @"noOnlineBackup",
            @"title": OALocalizedString(@"cloud_no_online_backup"),
            @"description": OALocalizedString(@"cloud_no_online_backup_descr"),
            @"image": @"ic_custom_cloud_neutral_face_colored"
        },
        @{
            @"cellId": OAFilledButtonCell.getCellIdentifier,
            @"name": @"setUpBackup",
            @"title": OALocalizedString(@"cloud_set_up_backup")
        }
    ];
    
    // Existing backup case
    NSArray <NSDictionary *> *existingBackupRows = @[
        @{
            @"cellId": OALargeImageTitleDescrTableViewCell.getCellIdentifier,
            @"name": @"existingOnlineBackup",
            @"title": OALocalizedString(@"cloud_welcome_back"),
            @"description": OALocalizedString(@"cloud_description"),
            @"image": @"ic_action_cloud_smile_face_colored"
        },
        @{
            @"cellId": OATwoFilledButtonsTableViewCell.getCellIdentifier,
            @"name": @"backupAndRestore",
            @"topTitle": OALocalizedString(@"cloud_restore_now"),
            @"bottomTitle": OALocalizedString(@"cloud_set_up_backup")
        }
    ];
    
    // Last backup cell
    NSDictionary *lastBackupCell = @{
        @"cellId": OAMultiIconTextDescCell.getCellIdentifier,
        @"name": @"lastBackup",
        @"title": OALocalizedString(@"cloud_last_backup"),
        @"description": @"2 days ago", // TODO: insert correct relative last backup time
        @"image": @"ic_custom_cloud_done"
    };
    // Backup now cell
    NSDictionary *backupNowCell = @{
        @"cellId": OAButtonRightIconCell.getCellIdentifier,
        @"name": @"backupNow",
        @"title": OALocalizedString(@"cloud_backup_now"),
        @"image": @"ic_custom_cloud_upload"
    };
    // Make backup warning cell
    NSDictionary *makeBackupWarningCell = @{
        @"cellId": OATitleDescrRightIconTableViewCell.getCellIdentifier,
        @"name": @"makeBackupWarning",
        @"title": OALocalizedString(@"cloud_make_backup"),
        @"description": OALocalizedString(@"cloud_make_backup_descr"),
        @"imageColor": UIColorFromRGB(color_support_green),
        @"image": @"ic_custom_alert_circle"
    };
    // No Internet warning cell
    NSDictionary *noInternetWarningCell = @{
        @"cellId": OATitleDescrRightIconTableViewCell.getCellIdentifier,
        @"name": @"noInternetWarning",
        @"title": OALocalizedString(@"no_inet_connection"),
        @"description": OALocalizedString(@"osm_upload_no_internet"),
        @"imageColor": UIColorFromRGB(color_support_red),
        @"image": @"ic_custom_wifi_off"
    };
    // Conflicts warning cell
    NSDictionary *conflictsWarningCell = @{
        @"cellId": OATitleDescrRightIconTableViewCell.getCellIdentifier,
        @"name": @"conflictsWarning",
        @"title": OALocalizedString(@"cloud_conflicts"),
        @"description": OALocalizedString(@"cloud_conflicts_descr"),
        @"imageColor": UIColorFromRGB(color_support_red),
        @"image": @"ic_custom_alert"
    };
    // Retry button cell
    NSDictionary *retryCell = @{
        @"cellId": OAButtonRightIconCell.getCellIdentifier,
        @"name": @"retry",
        @"title": OALocalizedString(@"shared_string_retry"),
        @"image": @"ic_custom_reset"
    };
    // View conflicts cell
    NSDictionary *viewConflictsCell = @{
        @"cellId": OAIconTitleValueCell.getCellIdentifier,
        @"name": @"viewConflicts",
        @"title": OALocalizedString(@"cloud_view_conflicts"),
        @"value": @"13" // TODO: insert conflicts count
    };
    
    NSDictionary *backupSection = @{
        @"sectionHeader": OALocalizedString(@"cloud_backup"),
        @"rows": existingBackupRows
    };
    [result addObject:backupSection];
    [result addObject:[self getLocalBackupSectionData]];
    _data = result;
}

- (IBAction)onBackButtonPressed
{
    for (UIViewController *controller in self.navigationController.viewControllers)
    {
        if ([controller isKindOfClass:[OAMainSettingsViewController class]])
        {
            [self.navigationController popToViewController:controller animated:YES];
            return;
        }
    }
}

- (IBAction)onSettingsButtonPressed
{
}

- (void)onSetUpBackupButtonPressed
{
    
}

- (void)onRestoreButtonPressed
{
    
}

// MARK: UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return _data[section][@"sectionHeader"];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return _data[section][@"sectionFooter"];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ((NSArray *)_data[section][@"rows"]).count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][@"rows"][indexPath.row];
    NSString *cellId = item[@"cellId"];
    if ([cellId isEqualToString:OATitleRightIconCell.getCellIdentifier])
    {
        OATitleRightIconCell* cell = [tableView dequeueReusableCellWithIdentifier:OATitleRightIconCell.getCellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleRightIconCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleRightIconCell *)[nib objectAtIndex:0];
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.titleView.font = [UIFont systemFontOfSize:17.];
        }
        cell.titleView.text = item[@"title"];
        [cell.iconView setImage:[UIImage templateImageNamed:item[@"image"]]];
        return cell;
    }
    else if ([cellId isEqualToString:OALargeImageTitleDescrTableViewCell.getCellIdentifier])
    {
        OALargeImageTitleDescrTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:OALargeImageTitleDescrTableViewCell.getCellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OALargeImageTitleDescrTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OALargeImageTitleDescrTableViewCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., CGFLOAT_MAX, 0., 0.);
        }
        cell.titleLabel.text = item[@"title"];
        cell.descriptionLabel.text = item[@"description"];
        [cell.cellImageView setImage:[UIImage imageNamed:item[@"image"]]];
        return cell;
    }
    else if ([cellId isEqualToString:OAFilledButtonCell.getCellIdentifier])
    {
        OAFilledButtonCell* cell = [tableView dequeueReusableCellWithIdentifier:OAFilledButtonCell.getCellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAFilledButtonCell getCellIdentifier] owner:self options:nil];
            cell = (OAFilledButtonCell *)[nib objectAtIndex:0];
            cell.button.backgroundColor = UIColorFromRGB(color_primary_purple);
            [cell.button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
            cell.button.titleLabel.font = [UIFont systemFontOfSize:15. weight:UIFontWeightSemibold];
            cell.button.layer.cornerRadius = 9.;
            cell.topMarginConstraint.constant = 9.;
            cell.bottomMarginConstraint.constant = 20.;
            cell.heightConstraint.constant = 42.;
            cell.separatorInset = UIEdgeInsetsMake(0., CGFLOAT_MAX, 0., 0.);
        }
        [cell.button setTitle:item[@"title"] forState:UIControlStateNormal];
        [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
        [cell.button addTarget:self action:@selector(onSetUpBackupButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    }
    else if ([cellId isEqualToString:OATwoFilledButtonsTableViewCell.getCellIdentifier])
    {
        OATwoFilledButtonsTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:OATwoFilledButtonsTableViewCell.getCellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATwoFilledButtonsTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATwoFilledButtonsTableViewCell *)[nib objectAtIndex:0];
            cell.separatorInset = UIEdgeInsetsMake(0., CGFLOAT_MAX, 0., 0.);
        }
        [cell.topButton setTitle:item[@"topTitle"] forState:UIControlStateNormal];
        [cell.topButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
        [cell.topButton addTarget:self action:@selector(onRestoreButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [cell.bottomButton setTitle:item[@"bottomTitle"] forState:UIControlStateNormal];
        [cell.bottomButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
        [cell.bottomButton addTarget:self action:@selector(onSetUpBackupButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    }
    else if ([cellId isEqualToString:OAMultiIconTextDescCell.getCellIdentifier])
    {
        OAMultiIconTextDescCell* cell = [tableView dequeueReusableCellWithIdentifier:OAMultiIconTextDescCell.getCellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMultiIconTextDescCell getCellIdentifier] owner:self options:nil];
            cell = (OAMultiIconTextDescCell *)[nib objectAtIndex:0];
            cell.iconView.tintColor = UIColorFromRGB(nav_bar_day);
            [cell setOverflowVisibility:YES];
        }
        cell.textView.text = item[@"title"];
        cell.descView.text = item[@"description"];
        [cell.iconView setImage:[UIImage templateImageNamed:item[@"image"]]];
        return cell;
    }
    else if ([cellId isEqualToString:OAButtonRightIconCell.getCellIdentifier])
    {
        OAButtonRightIconCell* cell = [tableView dequeueReusableCellWithIdentifier:OAButtonRightIconCell.getCellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAButtonRightIconCell getCellIdentifier] owner:self options:nil];
            cell = (OAButtonRightIconCell *)[nib objectAtIndex:0];
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
        }
        [cell.button setTitle:item[@"title"] forState:UIControlStateNormal];
        [cell.iconView setImage:[UIImage templateImageNamed:item[@"image"]]];
        return cell;
    }
    else if ([cellId isEqualToString:OATitleDescrRightIconTableViewCell.getCellIdentifier])
    {
        OATitleDescrRightIconTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:OATitleDescrRightIconTableViewCell.getCellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleDescrRightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleDescrRightIconTableViewCell *)[nib objectAtIndex:0];
        }
        cell.titleLabel.text = item[@"title"];
        cell.descriptionLabel.text = item[@"description"];
        cell.iconView.tintColor = item[@"imageColor"];
        [cell.iconView setImage:[UIImage templateImageNamed:item[@"image"]]];
        return cell;
    }
    else if ([cellId isEqualToString:OAIconTitleValueCell.getCellIdentifier])
    {
        OAIconTitleValueCell* cell = [tableView dequeueReusableCellWithIdentifier:OAIconTitleValueCell.getCellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleValueCell *)[nib objectAtIndex:0];
            cell.textView.font = [UIFont systemFontOfSize:17. weight:UIFontWeightMedium];
            cell.textView.textColor = UIColorFromRGB(color_primary_purple);
            cell.descriptionView.font = [UIFont systemFontOfSize:17.];
            cell.descriptionView.textColor = UIColorFromRGB(color_text_footer);
            cell.rightIconView.tintColor = UIColorFromRGB(color_tint_gray);
            cell.rightIconView.image = [UIImage templateImageNamed:@"ic_custom_arrow_right"];
            [cell showLeftIcon:NO];
            [cell showRightIcon:YES];
        }
        cell.textView.text = item[@"title"];
        cell.descriptionView.text = item[@"value"];
        return cell;
    }
    return nil;
}

// MARK: UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = _data[indexPath.section][@"rows"][indexPath.row];
    NSString *itemId = item[@"name"];
    if ([itemId isEqualToString:@"backupIntoFile"])
    {
        [self onBackupIntoFilePressed];
    }
    else if ([itemId isEqualToString:@"restoreFromFile"])
    {
        [self onRestoreFromFilePressed];
    }
    else if ([itemId isEqualToString:@"backupNow"])
    {
        
    }
    else if ([itemId isEqualToString:@"retry"])
    {
        
    }
    else if ([itemId isEqualToString:@"viewConflicts"])
    {
        
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
