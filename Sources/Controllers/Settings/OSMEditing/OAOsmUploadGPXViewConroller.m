//
//  OAOsmUploadGPXViewConroller.m
//  OsmAnd Maps
//
//  Created by nnngrach on 31.01.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAOsmUploadGPXViewConroller.h"
#import "OAOsmUploadGPXVisibilityViewConroller.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OASizes.h"
#import "OAValueTableViewCell.h"
#import "OAInputTableViewCell.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OAOsmAccountSettingsViewController.h"
#import "OAMappersViewController.h"
#import "OAUploadGPXFilesTask.h"
#import "OAPlugin.h"
#import "OAOsmEditingPlugin.h"
#import "OAProgressBarCell.h"
#import "OAValueTableViewCell.h"
#import "OATitleIconProgressbarCell.h"
#import "OABackupListeners.h"
#import "OATextMultilineTableViewCell.h"
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"
#import "OAPluginsHelper.h"

#define kDefaultTag @"osmand"
#define kDescriptionTextFieldTag 0
#define kTagsTextFieldsTag 1
#define kUploadingValueCell @"kUploadingValueCell"

typedef NS_ENUM(NSInteger, EOAOsmUploadGPXViewConrollerMode) {
    EOAOsmUploadGPXViewConrollerModeInitial = 0,
    EOAOsmUploadGPXViewConrollerModeUploading,
    EOAOsmUploadGPXViewConrollerModeSuccess,
    EOAOsmUploadGPXViewConrollerModeFailed,
    EOAOsmUploadGPXViewConrollerModeNoInternet
};

@interface OAOsmUploadGPXViewConroller () <UITextFieldDelegate, OAOsmUploadGPXVisibilityDelegate, OAAccountSettingDelegate, OAOnUploadFileListener>

@end

@implementation OAOsmUploadGPXViewConroller
{
    OAAppSettings *_settings;
    NSArray<OASTrackItem *> *_gpxItemsToUpload;
    OATableDataModel *_data;
    NSString *_descriptionText;
    NSString *_tagsText;
    EOAOsmUploadGPXVisibility _selectedVisibility;
    BOOL _isAuthorised;
    BOOL _isOAuthAllowed;
    OAProgressBarCell *_progressBarCell;
    OAValueTableViewCell *_progressValueCell;
    OAUploadGPXFilesTask *_uploadTask;
    NSMutableDictionary<NSString *, NSNumber *> *_filesUploadingProgress;
    NSMutableArray<NSString *> *_failedFileNames;
    EOAOsmUploadGPXViewConrollerMode _mode;
    OAAutoObserverProxy *_oauthAccountUpdatedObserver;
}

#pragma mark - Initialization

- (instancetype)initWithGPXItems:(NSArray<OASTrackItem *> *)gpxItemsToUpload
{
    self = [super init];
    if (self)
    {
        _gpxItemsToUpload = gpxItemsToUpload;
    }
    return self;
}

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
    _mode = EOAOsmUploadGPXViewConrollerModeInitial;
    _selectedVisibility = EOAOsmUploadGPXVisibilityPublic;
    _descriptionText = @"";
    _tagsText = kDefaultTag;
    _isAuthorised = [OAOsmOAuthHelper isAuthorised];
    _isOAuthAllowed = [OAOsmOAuthHelper isOAuthAllowed];
}

#pragma mark - UIViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAccountInformationUpdated) name:OAOsmOAuthHelper.notificationKey object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _isAuthorised = [OAOsmOAuthHelper isAuthorised];
    if (!_isAuthorised && _isOAuthAllowed)
        [OAOsmOAuthHelper showOAuthScreenWithHostVC:self];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    if (_gpxItemsToUpload.count > 1)
        return [NSString stringWithFormat:@"%@ (%lu)", OALocalizedString(@"upload_to_openstreetmap"), (unsigned long)_gpxItemsToUpload.count];
    else
        return OALocalizedString(@"upload_to_openstreetmap");
        
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

- (NSString *)getBottomButtonTitle
{
    switch (_mode)
    {
        case EOAOsmUploadGPXViewConrollerModeInitial:
            return OALocalizedString(@"shared_string_upload");
        case EOAOsmUploadGPXViewConrollerModeUploading:
        case EOAOsmUploadGPXViewConrollerModeSuccess:
            return OALocalizedString(@"shared_string_done");
        case EOAOsmUploadGPXViewConrollerModeFailed:
        case EOAOsmUploadGPXViewConrollerModeNoInternet:
            return OALocalizedString(@"retry");
        default:
            return @"";
    }
}

- (EOABaseButtonColorScheme)getBottomButtonColorScheme
{
    if (!_isAuthorised || !_isOAuthAllowed)
        return EOABaseButtonColorSchemeInactive;
    
    switch (_mode)
    {
        case EOAOsmUploadGPXViewConrollerModeUploading:
            return EOABaseButtonColorSchemeInactive;
        case EOAOsmUploadGPXViewConrollerModeInitial:
        case EOAOsmUploadGPXViewConrollerModeFailed:
        case EOAOsmUploadGPXViewConrollerModeNoInternet:
            return EOABaseButtonColorSchemePurple;
        default:
            return EOABaseButtonColorSchemeGraySimple;
    }
}

- (void)updateScreenMode:(EOAOsmUploadGPXViewConrollerMode)mode
{
    _mode = mode;
    [self setupBottomButtons];
}

#pragma mark - Table data

- (void)generateData
{
    _data = [[OATableDataModel alloc] init];
    __weak OAOsmUploadGPXViewConroller *weakSelf = self;
    
    if (_mode == EOAOsmUploadGPXViewConrollerModeInitial)
    {
        OATableSectionData *descriptionSection = [_data createNewSection];
        descriptionSection.headerText = OALocalizedString(@"shared_string_description");
        descriptionSection.footerText = OALocalizedString(@"osm_upload_gpx_description_footer");
        OATableRowData *descriptionTextInputCell = [descriptionSection createNewRow];
        [descriptionTextInputCell setCellType:[OAInputTableViewCell getCellIdentifier]];
        [descriptionTextInputCell setTitle:_descriptionText];
        [descriptionTextInputCell setObj:@(kDescriptionTextFieldTag) forKey:@"tag"];
        
        OATableSectionData *tagsSection = [_data createNewSection];
        tagsSection.headerText = OALocalizedString(@"gpx_tags_txt");
        tagsSection.footerText = OALocalizedString(@"osm_upload_gpx_tags_footer");
        OATableRowData *tagsTextInputCell = [tagsSection createNewRow];
        [tagsTextInputCell setCellType:[OAInputTableViewCell getCellIdentifier]];
        [tagsTextInputCell setTitle:_tagsText];
        [tagsTextInputCell setObj:@(kTagsTextFieldsTag) forKey:@"tag"];
        
        OATableSectionData *visibilitySection = [_data createNewSection];
        OATableRowData *visibilityCell = [visibilitySection createNewRow];
        [visibilityCell setCellType:[OAValueTableViewCell getCellIdentifier]];
        [visibilityCell setTitle:OALocalizedString(@"visibility")];
        [visibilityCell setDescr:[OAOsmUploadGPXVisibilityViewConroller localizedNameForVisibilityType:_selectedVisibility]];
        [visibilityCell setObj: (^void(){ [weakSelf onVisibilityButtonClicked]; }) forKey:@"actionBlock"];
        
        OATableSectionData *accountSection = [_data createNewSection];
        accountSection.headerText = OALocalizedString(@"login_account");
        OATableRowData *accountCell = [accountSection createNewRow];
        if (_isOAuthAllowed)
        {
            [accountCell setCellType:[OASimpleTableViewCell getCellIdentifier]];
            [accountCell setTitle: _isAuthorised ? [OAOsmOAuthHelper getUserDisplayName] : OALocalizedString(@"login_open_street_map_org")];
            [accountCell setIconName:@"ic_custom_user_profile"];
            [accountCell setObj:(_isAuthorised ? [UIColor colorNamed:ACColorNameTextColorPrimary] : [UIColor colorNamed:ACColorNameTextColorActive]) forKey:@"title_color"];
            [accountCell setObj:([UIFont systemFontOfSize:17. weight:_isAuthorised ? UIFontWeightRegular : UIFontWeightMedium]) forKey:@"title_font"];
            [accountCell setObj:(_isAuthorised ? @(UITableViewCellAccessoryDisclosureIndicator) : @(UITableViewCellAccessoryNone)) forKey:@"accessory_type"];
            [accountCell setObj: (^void(){ [weakSelf onAccountButtonPressed]; }) forKey:@"actionBlock"];
        }
        else
        {
            [accountCell setCellType:[OASimpleTableViewCell getCellIdentifier]];
            [accountCell setTitle: OALocalizedString(@"shared_string_update_required")];
            [accountCell setDescr: OALocalizedString(@"osm_login_needs_ios_16_4")];
            [accountCell setIconName:@"ic_custom_alert"];
            [accountCell setIconTintColor:[UIColor colorNamed:ACColorNameIconColorSelected]];
            [accountCell setObj:[UIColor colorNamed:ACColorNameTextColorPrimary] forKey:@"title_color"];
            [accountCell setObj:[UIFont scaledSystemFontOfSize:17. weight:UIFontWeightRegular] forKey:@"title_font"];
            [accountCell setObj:@(UITableViewCellAccessoryNone) forKey:@"accessory_type"];
        }
    }
    else if (_mode == EOAOsmUploadGPXViewConrollerModeUploading)
    {
        _progressBarCell = [self getProgressBarCell];
        _progressValueCell = [self getProgressValueCell];
        
        OATableSectionData *uploadingSection = [_data createNewSection];
        uploadingSection.headerText = @" ";
        OATableRowData *progressValueCell = [uploadingSection createNewRow];
        [progressValueCell setCellType:[OAValueTableViewCell getCellIdentifier]];
        [progressValueCell setKey:kUploadingValueCell];
        OATableRowData *progressBarCell = [uploadingSection createNewRow];
        [progressBarCell setCellType:[OAProgressBarCell getCellIdentifier]];
    }
    else if (_mode == EOAOsmUploadGPXViewConrollerModeFailed)
    {
        OATableSectionData *section = [_data createNewSection];
        section.headerText = @" ";
        OATableRowData *titleRow = [section createNewRow];
        [titleRow setCellType:[OATextMultilineTableViewCell getCellIdentifier]];
        [titleRow setTitle: OALocalizedString(@"osm_upload_failed_title")];
        [titleRow setObj:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]
             forKey:@"font"];
        
        OATableRowData *descrRow = [section createNewRow];
        [descrRow setCellType:[OATextMultilineTableViewCell getCellIdentifier]];
        [descrRow setTitle: OALocalizedString(@"osm_upload_failed_descr")];
        [descrRow setObj:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
             forKey:@"font"];
    }
    else if (_mode == EOAOsmUploadGPXViewConrollerModeNoInternet)
    {
        OATableSectionData *section = [_data createNewSection];
        section.headerText = @" ";
        OATableRowData *titleRow = [section createNewRow];
        [titleRow setCellType:[OATextMultilineTableViewCell getCellIdentifier]];
        [titleRow setTitle: OALocalizedString(@"no_internet_avail")];
        [titleRow setObj:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]
             forKey:@"font"];
        
        OATableRowData *descrRow = [section createNewRow];
        [descrRow setCellType:[OATextMultilineTableViewCell getCellIdentifier]];
        [descrRow setTitle: OALocalizedString(@"osm_upload_no_internet")];
        [descrRow setObj:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
             forKey:@"font"];
    }
}

- (void) setProgress:(float)progress fileName:(NSString *)fileName
{
    _filesUploadingProgress[fileName] = [NSNumber numberWithFloat:progress];
    
    float progressSum = 0;
    for (NSNumber *value in _filesUploadingProgress.allValues)
        progressSum += value.floatValue;
    
    progressSum = progressSum / _gpxItemsToUpload.count;
    
    _progressValueCell.valueLabel.text = [NSString stringWithFormat:@"%d%%", (int)progressSum];
    [_progressBarCell.progressBar setProgress:progressSum / 100 animated:YES];
    
    if (progressSum == 100)
    {
        if (_failedFileNames.count == 0)
        {
            [self updateScreenMode:EOAOsmUploadGPXViewConrollerModeSuccess];
        }
        else
        {
            [self updateScreenMode:EOAOsmUploadGPXViewConrollerModeFailed];
            [self generateData];
            [self.tableView reloadData];
        }
    }
}

- (OAValueTableViewCell *) getProgressValueCell
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
    OAValueTableViewCell *resultCell = (OAValueTableViewCell *)[nib objectAtIndex:0];
    [resultCell descriptionVisibility:NO];
    [resultCell leftIconVisibility:NO];
    resultCell.titleLabel.text = OALocalizedString(@"local_openstreetmap_uploading");
    resultCell.valueLabel.text = @"0%";
    return resultCell;
}

- (OAProgressBarCell *) getProgressBarCell
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAProgressBarCell getCellIdentifier] owner:self options:nil];
    
    OAProgressBarCell *resultCell = (OAProgressBarCell *)[nib objectAtIndex:0];
    [resultCell.progressBar setProgress:0.0 animated:NO];
    [resultCell.progressBar setProgressTintColor:[UIColor colorNamed:ACColorNameIconColorActive]];
    resultCell.selectionStyle = UITableViewCellSelectionStyleNone;
    return resultCell;
}

- (NSString *)getTitleForHeader:(NSInteger)section;
{
    return [_data sectionDataForIndex:section].headerText;
}

- (NSString *)getTitleForFooter:(NSInteger)section;
{
    return [_data sectionDataForIndex:section].footerText;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return [_data rowCount:section];
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    NSString *cellType = item.cellType;
    
    if ([cellType isEqualToString:[OAInputTableViewCell getCellIdentifier]])
    {
        OAInputTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAInputTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAInputTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAInputTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell titleVisibility:NO];
            [cell clearButtonVisibility:NO];
            [cell.inputField removeTarget:self action:NULL forControlEvents:UIControlEventEditingChanged];
            [cell.inputField addTarget:self action:@selector(textViewDidChange:) forControlEvents:UIControlEventEditingChanged];
            cell.inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            cell.inputField.autocorrectionType = UITextAutocorrectionTypeNo;
            cell.inputField.spellCheckingType = UITextSpellCheckingTypeNo;
            cell.inputField.textAlignment = NSTextAlignmentNatural;
        }
        if (cell)
        {
            cell.inputField.text = item.title;
            cell.inputField.delegate = self;
            cell.inputField.tag = [item integerForKey:@"tag"];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        NSString *key = [item key];
        if (key && [key isEqualToString:kUploadingValueCell])
            return _progressValueCell;
            
        OAValueTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *)[nib objectAtIndex:0];
            [cell descriptionVisibility:NO];
            [cell leftIconVisibility:NO];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
            cell.valueLabel.text = item.descr;
            cell.accessibilityLabel = item.title;
            cell.accessibilityValue = item.descr;
        }
        return cell;
    }
    else if ([cellType isEqualToString:OASimpleTableViewCell.getCellIdentifier])
    {
        OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *) nib[0];
            [cell leftIconVisibility:YES];
        }
        if (cell)
        {
            NSString *title = item.title;
            [cell titleVisibility:title != nil];
            cell.titleLabel.text = title;
            cell.titleLabel.textColor = [item objForKey:@"title_color"];
            cell.titleLabel.font = [item objForKey:@"title_font"];
            [cell descriptionVisibility:item.descr];
            cell.descriptionLabel.text = item.descr;
            cell.leftIconView.image = [UIImage templateImageNamed:item.iconName];
            if (item.iconTintColor)
                cell.leftIconView.tintColor = item.iconTintColor;
            else
                cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
            cell.accessoryType = (UITableViewCellAccessoryType) [item integerForKey:@"accessory_type"];
            cell.accessibilityTraits = UIAccessibilityTraitButton;
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OATextMultilineTableViewCell getCellIdentifier]])
    {
        OATextMultilineTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OATextMultilineTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextMultilineTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATextMultilineTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell clearButtonVisibility:NO];
        }
        if (cell)
        {
            cell.textView.text = item.title;
            cell.textView.font = [item objForKey:@"font"];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OAProgressBarCell getCellIdentifier]])
    {
        return _progressBarCell;
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return _data.sectionCount;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    void (^actionBlock)() = [item objForKey:@"actionBlock"];
    if (actionBlock)
        actionBlock();
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    NSString *cellType = item.cellType;
    if ([cellType isEqualToString:[OAProgressBarCell getCellIdentifier]])
        return 22;
    return UITableViewAutomaticDimension;
}

#pragma mark - Selectors

- (void)onLeftNavbarButtonPressed
{
    if (_mode == EOAOsmUploadGPXViewConrollerModeInitial)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"exit_without_saving") message:OALocalizedString(@"unsaved_changes_will_be_lost") preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_exit") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [super onLeftNavbarButtonPressed];
        }]];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
    else if (_mode == EOAOsmUploadGPXViewConrollerModeUploading)
    {
        if (_uploadTask)
            [_uploadTask setInterrupted:YES];
        [super onLeftNavbarButtonPressed];
    }
    else
    {
        [super onLeftNavbarButtonPressed];
    }
}

- (void)onBottomButtonPressed
{
    if (_mode == EOAOsmUploadGPXViewConrollerModeInitial)
    {
        if (!AFNetworkReachabilityManager.sharedManager.isReachable)
        {
            [self updateScreenMode:EOAOsmUploadGPXViewConrollerModeNoInternet];
            [self generateData];
            [self.tableView reloadData];
            return;
        }
        
        if (_isAuthorised && _isOAuthAllowed)
        {
            [self updateScreenMode:EOAOsmUploadGPXViewConrollerModeUploading];
            [self generateData];
            [self.tableView reloadData];
            
            NSString *visibility = [OAOsmUploadGPXVisibilityViewConroller toUrlParam:_selectedVisibility];
            if (!visibility)
                visibility = [OAOsmUploadGPXVisibilityViewConroller toUrlParam:EOAOsmUploadGPXVisibilityPrivate];
            
            _filesUploadingProgress = [NSMutableDictionary dictionary];
            _failedFileNames = [NSMutableArray array];
            
            OAOsmEditingPlugin *plugin = (OAOsmEditingPlugin *)[OAPluginsHelper getPlugin:OAOsmEditingPlugin.class];
            _uploadTask = [[OAUploadGPXFilesTask alloc] initWithPlugin:plugin gpxItemsToUpload:_gpxItemsToUpload tags:_tagsText visibility:visibility description:_descriptionText listener:self];
            [_uploadTask uploadTracks];
        }
    }
    else if (_mode == EOAOsmUploadGPXViewConrollerModeUploading)
    {
        //button is blocked
    }
    else if (_mode == EOAOsmUploadGPXViewConrollerModeSuccess)
    {
        [super onLeftNavbarButtonPressed];
    }
    else if (_mode == EOAOsmUploadGPXViewConrollerModeFailed)
    {
        _gpxItemsToUpload = [self getFailedFiles];
        [self updateScreenMode:EOAOsmUploadGPXViewConrollerModeInitial];
        [self generateData];
        [self.tableView reloadData];
        [self onBottomButtonPressed];
    }
    else if (_mode == EOAOsmUploadGPXViewConrollerModeNoInternet)
    {
        [self updateScreenMode:EOAOsmUploadGPXViewConrollerModeInitial];
        [self generateData];
        [self.tableView reloadData];
        [self onBottomButtonPressed];
    }
}

- (void)onRotation
{
    [self generateData];
}

- (void)onVisibilityButtonClicked
{
    OAOsmUploadGPXVisibilityViewConroller *vc = [[OAOsmUploadGPXVisibilityViewConroller alloc] initWithVisibility:_selectedVisibility];
    vc.visibilityDelegate = self;
    [self showViewController:vc];
}

- (void)onAccountButtonPressed
{
    if (_isAuthorised)
    {
        OAOsmAccountSettingsViewController *accountSettings = [[OAOsmAccountSettingsViewController alloc] init];
        accountSettings.accountDelegate = self;
        [self showModalViewController:accountSettings];
    }
    else
    {
        if (_isOAuthAllowed)
            [OAOsmOAuthHelper showOAuthScreenWithHostVC:self];
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
    if (textView.tag == kDescriptionTextFieldTag)
    {
        _descriptionText = textView.text;
    }
    else if (textView.tag == kTagsTextFieldsTag)
    {
        _tagsText = textView.text;
    }
}

#pragma mark - Keyboard Notifications

- (void) keyboardWillShow:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    NSValue *keyboardBoundsValue = userInfo[UIKeyboardFrameEndUserInfoKey];
    CGFloat keyboardHeight = [keyboardBoundsValue CGRectValue].size.height;
    
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [[self tableView] contentInset];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        self.buttonsBottomOffsetConstraint.constant = keyboardHeight - [OAUtilities getBottomMargin];
        [[self tableView] setContentInset:UIEdgeInsetsMake(insets.top, insets.left, keyboardHeight, insets.right)];
        [[self view] layoutIfNeeded];
    } completion:nil];
}

- (void) keyboardWillHide:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [[self tableView] contentInset];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        self.buttonsBottomOffsetConstraint.constant = 0;
        [[self tableView] setContentInset:UIEdgeInsetsMake(insets.top, insets.left, 0., insets.right)];
        [[self view] layoutIfNeeded];
    } completion:nil];
}

#pragma mark - OAOsmUploadGPXVisibilityDelegate

- (void) onVisibilityChanged:(EOAOsmUploadGPXVisibility)visibility
{
    _selectedVisibility = visibility;
    [self generateData];
    [self.tableView reloadData];
}

#pragma mark - OAAccontSettingDelegate

- (void)onAccountInformationUpdated
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _isAuthorised = [OAOsmOAuthHelper isAuthorised];
        [self generateData];
        [self.tableView reloadData];
        [self setupBottomButtons];
    });
}

- (void)onAccountInformationUpdatedFromBenefits
{
    [self onAccountInformationUpdated];
    if (_isAuthorised)
    {
        OAMappersViewController *benefitsViewController = [[OAMappersViewController alloc] init];
        [self showModalViewController:benefitsViewController];
    }
}

#pragma mark - OAOnUploadFileListener

- (void)onFileUploadProgress:(NSString *)type fileName:(NSString *)fileName progress:(NSInteger)progress deltaWork:(NSInteger)deltaWork {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setProgress:progress fileName:fileName];
    });
}

- (void)onFileUploadDone:(NSString *)type fileName:(NSString *)fileName uploadTime:(long)uploadTime error:(NSString *)error {
    if (error || error.length > 0)
        [_failedFileNames addObject:fileName];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setProgress: 100 fileName:fileName];
    });
}

- (NSArray<OASTrackItem *> *) getFailedFiles
{
    NSMutableArray<OASTrackItem *> *failledFiles = [NSMutableArray array];
    for (NSString *fileName in _failedFileNames)
    {
        for (OASTrackItem *gpx in _gpxItemsToUpload)
        {
            if ([gpx.gpxFileName isEqualToString:fileName])
                [failledFiles addObject:gpx];
        }
    }
    return failledFiles;
}

@end
