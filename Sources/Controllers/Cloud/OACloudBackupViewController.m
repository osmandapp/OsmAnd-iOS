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
#import "OAIAPHelper.h"
#import "OABackupHelper.h"
#import "OAButtonRightIconCell.h"
#import "OAMultiIconTextDescCell.h"
#import "OAIconTitleValueCell.h"
#import "OATitleIconProgressbarCell.h"
#import "OATitleDescrRightIconTableViewCell.h"
#import "OAMainSettingsViewController.h"
#import "OARestoreBackupViewController.h"
#import "OANetworkSettingsHelper.h"
#import "OAPrepareBackupResult.h"
#import "OABackupHelper.h"
#import "OABackupInfo.h"
#import "OABackupStatus.h"
#import "OAAppSettings.h"
#import "OAChoosePlanHelper.h"
#import "OAOsmAndFormatter.h"
#import "OABackupError.h"

#import "OAExportSettingsType.h"

@interface OACloudBackupViewController () <UITableViewDelegate, UITableViewDataSource, OABackupExportListener, OAImportListener, OAOnPrepareBackupListener>

@property (weak, nonatomic) IBOutlet UIView *navBarBackgroundView;
@property (weak, nonatomic) IBOutlet UILabel *navBarTitle;
@property (weak, nonatomic) IBOutlet UIButton *backImgButton;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;
@property (weak, nonatomic) IBOutlet UITableView *tblView;

@end

@implementation OACloudBackupViewController
{
    NSArray<NSDictionary *> *_data;
    OANetworkSettingsHelper *_settingsHelper;
    OABackupHelper *_backupHelper;
    
    EOACloudScreenSourceType _sourceType;
    OAPrepareBackupResult *_backup;
    OABackupInfo *_info;
    OABackupStatus *_status;
    NSString *_error;
    
    OATitleIconProgressbarCell *_backupProgressCell;
}

- (instancetype) initWithSourceType:(EOACloudScreenSourceType)type
{
    self = [self init];
    if (self) {
        _sourceType = type;
    }
    return self;
}

- (instancetype)init
{
    self = [super initWithNibName:@"OACloudBackupViewController" bundle:nil];
    if (self) {
        _sourceType = EOACloudScreenSourceTypeDirect;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [OAIAPHelper.sharedInstance checkBackupPurchase];
    _settingsHelper = OANetworkSettingsHelper.sharedInstance;
    _backupHelper = OABackupHelper.sharedInstance;
    [_settingsHelper updateExportListener:self];
    [_settingsHelper updateImportListener:self];
    [_backupHelper addPrepareBackupListener:self];
    if (!_settingsHelper.isBackupExporting)
        [_backupHelper prepareBackup];
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
    
    if (!_status)
        _status = [OABackupStatus getBackupStatus:_backup];
    
    BOOL backupSaved = _backup.remoteFiles.count != 0;
    BOOL showIntroductionItem = _info != nil && ((_sourceType == EOACloudScreenSourceTypeSignUp && !backupSaved)
                    || (_sourceType == EOACloudScreenSourceTypeSignIn && (backupSaved || _backup.localFiles.count > 0)));
    
    if (showIntroductionItem)
    {
        if (_sourceType == EOACloudScreenSourceTypeSignIn)
        {
            // Existing backup case
            NSMutableArray<NSDictionary *> *existingBackupRows = [NSMutableArray array];
            [existingBackupRows addObject:@{
                @"cellId": OALargeImageTitleDescrTableViewCell.getCellIdentifier,
                @"name": @"existingOnlineBackup",
                @"title": OALocalizedString(@"cloud_welcome_back"),
                @"description": OALocalizedString(@"cloud_description"),
                @"image": @"ic_action_cloud_smile_face_colored"
            }];
            BOOL showBothButtons = [self shouldShowBackupButton] && [self shouldShowRestoreButton];
            if (showBothButtons)
            {
                [existingBackupRows addObject:@{
                    @"cellId": OATwoFilledButtonsTableViewCell.getCellIdentifier,
                    @"name": @"backupAndRestore",
                    @"topTitle": OALocalizedString(@"cloud_restore_now"),
                    @"bottomTitle": OALocalizedString(@"cloud_set_up_backup")
                }];
            }
            if ([self shouldShowRestoreButton] && !showBothButtons)
            {
                [existingBackupRows addObject:@{
                    @"cellId": OAFilledButtonCell.getCellIdentifier,
                    @"name": @"onRestoreButtonPressed",
                    @"title": OALocalizedString(@"cloud_restore_now")
                }];
            }
            if ([self shouldShowBackupButton] && !showBothButtons)
            {
                [existingBackupRows addObject:@{
                    @"cellId": OAFilledButtonCell.getCellIdentifier,
                    @"name": @"onSetUpBackupButtonPressed",
                    @"title": OALocalizedString(@"cloud_set_up_backup")
                }];
            }
            NSDictionary *backupSection = @{
                @"sectionHeader": OALocalizedString(@"cloud_backup"),
                @"rows": existingBackupRows
            };
            [result addObject:backupSection];
        }
        else if (_sourceType == EOACloudScreenSourceTypeSignUp)
        {
            // No backup case
            NSMutableArray<NSDictionary *> *noBackupRows = [NSMutableArray array];
            [noBackupRows addObject:@{
                @"cellId": OALargeImageTitleDescrTableViewCell.getCellIdentifier,
                @"name": @"noOnlineBackup",
                @"title": OALocalizedString(@"cloud_no_online_backup"),
                @"description": OALocalizedString(@"cloud_no_online_backup_descr"),
                @"image": @"ic_custom_cloud_neutral_face_colored"
            }];
            
            if ([self shouldShowBackupButton])
            {
                [noBackupRows addObject:@{
                    @"cellId": OAFilledButtonCell.getCellIdentifier,
                    @"name": @"onSetUpBackupButtonPressed",
                    @"title": OALocalizedString(@"cloud_set_up_backup")
                }];
            }
            NSDictionary *backupSection = @{
                @"sectionHeader": OALocalizedString(@"cloud_backup"),
                @"rows": noBackupRows
            };
            [result addObject:backupSection];
        }
    }
    else
    {
        OAExportBackupTask *exportTask = [_settingsHelper getExportTask:kBackupItemsKey];
        NSMutableArray<NSDictionary *> *backupRows = [NSMutableArray array];
        if (exportTask)
        {
            // TODO: show progress from HeaderStatusViewHolder.java
            _backupProgressCell = [self getProgressBarCell];
            NSDictionary *backupProgressCell = @{
                @"cellId": OATitleIconProgressbarCell.getCellIdentifier,
                @"cell": _backupProgressCell
            };
            [backupRows addObject:backupProgressCell];
        }
        else
        {
            NSString *backupTime = [OAOsmAndFormatter getFormattedPassedTime:OAAppSettings.sharedManager.backupLastUploadedTime.get def:OALocalizedString(@"shared_string_never")];
            NSDictionary *lastBackupCell = @{
                @"cellId": OAMultiIconTextDescCell.getCellIdentifier,
                @"name": @"lastBackup",
                @"title": _status.statusTitle,
                @"description": backupTime,
                @"image": _status.statusIconName
            };
            [backupRows addObject:lastBackupCell];
            
            if (_status.warningTitle != nil || _error.length > 0)
            {
                BOOL hasWarningStatus = _status.warningTitle != nil;
                BOOL hasDescr = _error || _status.warningDescription;
                NSString *descr = hasDescr && hasWarningStatus ? _status.warningDescription : _error;
                NSInteger color = _status.iconColor;
                NSDictionary *makeBackupWarningCell = @{
                    @"cellId": OATitleDescrRightIconTableViewCell.getCellIdentifier,
                    @"name": @"makeBackupWarning",
                    @"title": hasWarningStatus ? _status.warningTitle : OALocalizedString(@"osm_failed_uploads"),
                    @"description": descr ? descr : @"",
                    @"imageColor": @(color),
                    @"image": _status.warningIconName
                };
                [backupRows addObject:makeBackupWarningCell];
            }
            
//            if (info != null && uploadItemsVisible) {
//                items.addAll(info.itemsToUpload);
//                items.addAll(info.itemsToDelete);
//                items.addAll(info.filteredFilesToMerge);
//            }
        }
            
        BOOL actionButtonHidden = _status == OABackupStatus.BACKUP_COMPLETE ||
        (_status == OABackupStatus.CONFLICTS
         && (_info == nil || (_info.filteredFilesToUpload.count == 0 && _info.filteredFilesToDelete.count == 0)));
        if (!actionButtonHidden)
        {
            if (_settingsHelper.isBackupExporting)
            {
                NSDictionary *cancellCell = @{
                    @"cellId": OAButtonRightIconCell.getCellIdentifier,
                    @"name": @"cancellBackupPressed",
                    @"title": OALocalizedString(@"shared_string_cancel"),
                    @"image": @"ic_custom_cancel"
                };
                [backupRows addObject:cancellCell];
            }
            else if (_status == OABackupStatus.MAKE_BACKUP || _status == OABackupStatus.CONFLICTS)
            {
                NSDictionary *backupNowCell = @{
                    @"cellId": OAButtonRightIconCell.getCellIdentifier,
                    @"name": @"onSetUpBackupButtonPressed",
                    @"title": OALocalizedString(@"cloud_backup_now"),
                    @"image": @"ic_custom_cloud_upload"
                };
                [backupRows addObject:backupNowCell];
            }
            else if (_status == OABackupStatus.NO_INTERNET_CONNECTION || _status == OABackupStatus.ERROR)
            {
                NSDictionary *retryCell = @{
                    @"cellId": OAButtonRightIconCell.getCellIdentifier,
                    @"name": @"onRetryPressed",
                    @"title": _status.actionTitle,
                    @"image": @"ic_custom_reset"
                };
                [backupRows addObject:retryCell];
            }
            else if (_status == OABackupStatus.SUBSCRIPTION_EXPIRED)
            {
                NSDictionary *purchaseCell = @{
                    @"cellId": OAButtonRightIconCell.getCellIdentifier,
                    @"name": @"onSubscriptionExpired",
                    @"title": _status.actionTitle,
                    @"image": @"ic_custom_osmand_pro_logo_colored"
                };
                [backupRows addObject:purchaseCell];
            }
        }
        
        NSDictionary *backupSection = @{
            @"sectionHeader": OALocalizedString(@"cloud_backup"),
            @"rows": backupRows
        };
        [result addObject:backupSection];
    }
    NSDictionary *restoreSection = @{
        @"sectionHeader" : OALocalizedString(@"restore"),
        @"sectionFooter" : OALocalizedString(@"restore_backup_descr"),
        @"rows" : @[@{
            @"cellId": OAButtonRightIconCell.getCellIdentifier,
            @"name": @"onRestoreButtonPressed",
            @"title": OALocalizedString(@"restore_data"),
            @"image": @"ic_custom_restore"
        }]
    };
    [result addObject:restoreSection];

//    // View conflicts cell
//    NSDictionary *viewConflictsCell = @{
//        @"cellId": OAIconTitleValueCell.getCellIdentifier,
//        @"name": @"viewConflicts",
//        @"title": OALocalizedString(@"cloud_view_conflicts"),
//        @"value": @"13" // TODO: insert conflicts count
//    };
    [result addObject:[self getLocalBackupSectionData]];
    _data = result;
}

- (OATitleIconProgressbarCell *) getProgressBarCell
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleIconProgressbarCell getCellIdentifier] owner:self options:nil];
    OATitleIconProgressbarCell *resultCell = (OATitleIconProgressbarCell *)[nib objectAtIndex:0];
    [resultCell.progressBar setProgress:0.0 animated:NO];
    [resultCell.progressBar setProgressTintColor:UIColorFromRGB(color_primary_purple)];
    resultCell.textView.text = OALocalizedString(@"osm_edit_uploading");
    resultCell.imgView.image = [UIImage imageNamed:@"ic_custom_cloud_upload"];
    resultCell.selectionStyle = UITableViewCellSelectionStyleNone;
    return resultCell;
}

- (BOOL) shouldShowBackupButton
{
    return _backup.localFiles.count > 0;
}

- (BOOL) shouldShowRestoreButton
{
    return _backup.remoteFiles.count > 0;
}

- (void) refreshContent
{
    [self generateData];
    [self.tblView reloadData];
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
    // TODO: remove
    [OABackupHelper.sharedInstance logout];
}

- (void)onSetUpBackupButtonPressed
{
    @try
    {
        NSArray<OASettingsItem *> *items = _info.itemsToUpload;
        if (items.count > 0 || _info.filteredFilesToDelete.count > 0)
        {
            [_settingsHelper exportSettings:kBackupItemsKey items:items itemsToDelete:_info.itemsToDelete listener:self];
            [self refreshContent];
        }
    }
    @catch (NSException *e)
    {
        NSLog(@"Backup generation error: %@", e.reason);
    }
}

- (void)onRetryPressed
{
    [_backupHelper prepareBackup];
}

- (void) cancellBackupPressed
{
    [_settingsHelper cancelImport];
    [_settingsHelper cancelExport];
}

- (void) onSubscriptionExpired
{
    [OAChoosePlanHelper showChoosePlanScreenWithFeature:OAFeature.OSMAND_CLOUD navController:self.navigationController];
}

- (void)onRestoreButtonPressed
{
    OARestoreBackupViewController *restoreVC = [[OARestoreBackupViewController alloc] init];
    [self.navigationController pushViewController:restoreVC animated:YES];
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
            [cell showButton:NO];
        }
        cell.titleLabel.text = item[@"title"];
        cell.descriptionLabel.text = item[@"description"];
        [cell.cellImageView setImage:[UIImage imageNamed:item[@"image"]]];

        if (cell.needsUpdateConstraints)
            [cell updateConstraints];

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
        [cell.button addTarget:self action:NSSelectorFromString(item[@"name"]) forControlEvents:UIControlEventTouchUpInside];
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
        }
        [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
        [cell.button addTarget:self action:NSSelectorFromString(item[@"name"]) forControlEvents:UIControlEventTouchUpInside];
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
        NSInteger color = [item[@"imageColor"] integerValue];
        if (color != -1)
        {
            cell.iconView.tintColor = UIColorFromRGB(color);
            [cell.iconView setImage:[UIImage templateImageNamed:item[@"image"]]];
        }
        else
        {
            [cell.iconView setImage:[UIImage imageNamed:item[@"image"]]];
        }
        
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
    else if ([cellId isEqualToString:OATitleIconProgressbarCell.getCellIdentifier])
    {
        return item[@"cell"];
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

// MARK: OABackupExportListener

- (void)onBackupExportFinished:(nonnull NSString *)error
{
    if (error != nil)
    {
        [self refreshContent];
        [OAUtilities showToast:nil details:[[OABackupError alloc] initWithError:error].getLocalizedError duration:.4 inView:self.view];
    }
    else if (!_settingsHelper.isBackupExporting)
    {
        [_backupHelper prepareBackup];
    }
}

- (void)onBackupExportItemFinished:(nonnull NSString *)type fileName:(nonnull NSString *)fileName
{
    
}

- (void)onBackupExportItemProgress:(nonnull NSString *)type fileName:(nonnull NSString *)fileName value:(NSInteger)value
{
    
}

- (void)onBackupExportItemStarted:(nonnull NSString *)type fileName:(nonnull NSString *)fileName work:(NSInteger)work
{
    
}

- (void)onBackupExportProgressUpdate:(NSInteger)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_backupProgressCell && !isnan(value))
            _backupProgressCell.progressBar.progress = value / 1000;
    });
}

- (void)onBackupExportStarted
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self refreshContent];
    });
}

// MARK: OAImportListener

- (void)onImportFinished:(BOOL)succeed needRestart:(BOOL)needRestart items:(NSArray<OASettingsItem *> *)items {
    
}

- (void)onImportItemFinished:(NSString *)type fileName:(NSString *)fileName {
    
}

- (void)onImportItemProgress:(NSString *)type fileName:(NSString *)fileName value:(int)value {
    
}

- (void)onImportItemStarted:(NSString *)type fileName:(NSString *)fileName work:(int)work {
    
}

// MARK: OAOnPrepareBackupListener

- (void)onBackupPrepared:(nonnull OAPrepareBackupResult *)backupResult
{
    _backup = backupResult;
    _info = _backup.backupInfo;
    _status = [OABackupStatus getBackupStatus:_backup];
    _error = _backup.error;
    [self refreshContent];
}

- (void)onBackupPreparing
{
    // Show progress bar
}

@end
