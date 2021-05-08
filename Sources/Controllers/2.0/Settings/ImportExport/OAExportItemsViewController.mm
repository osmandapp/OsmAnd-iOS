//
//  OAExportItemsViewController.m
//  OsmAnd
//
//  Created by Paul on 08.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAExportItemsViewController.h"
#import "OARootViewController.h"
#import "OAExportSettingsType.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAExportSettingsCategory.h"
#import "OASettingsCategoryItems.h"

@implementation OAExportItemsViewController
{
    NSString *_descriptionText;
    NSString *_descriptionBoldText;

    OASettingsHelper *_settingsHelper;
    OAApplicationMode *_appMode;

    BOOL _exportStarted;
    long _itemsSize;
    NSString *_fileSize;
}

- (instancetype)initWithAppMode:(OAApplicationMode *)appMode
{
    self = [super init];
    if (self)
    {
        _appMode = appMode;
    }
    return self;
}

- (void)commonInit
{
    _settingsHelper = OASettingsHelper.sharedInstance;
    _itemsSize = 0;
    [self updateFileSize];
}

- (void)applyLocalization
{
    [super applyLocalization];
    _descriptionText = OALocalizedString(@"export_profile_select_descr");
    _descriptionBoldText = OALocalizedString(@"export_profile");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self setTableHeaderView:_appMode ? OALocalizedString(@"export_profile") : OALocalizedString(@"shared_string_export")];
    } completion:nil];
}

- (void)setupView
{
    [self setTableHeaderView:_appMode ? OALocalizedString(@"export_profile") : OALocalizedString(@"shared_string_export")];

    if (_exportStarted)
    {
        OATableGroupToImport *group = [[OATableGroupToImport alloc] init];
        group.type = @"OAProgressTitleCell";
        group.groupName = OALocalizedString(@"preparing_file");
        self.data = @[group];
        return;
    }
    self.itemsMap = [_settingsHelper getSettingsByCategory:YES];
    self.itemTypes = self.itemsMap.allKeys;
    [self generateData];
    [self updateSelectedProfile];
    [self updateControls];
}

- (NSString *)descriptionText
{
    return _descriptionText;
}

- (NSString *)descriptionBoldText
{
    return _descriptionBoldText;
}

- (NSString *)getDescriptionTextWithSize
{
    return [NSString stringWithFormat: @"%@\n%@", _descriptionText, _fileSize];
}

- (void)onGroupCheckmarkPressed:(UIButton *)sender
{
    [super onGroupCheckmarkPressed:sender];
    [self updateFileSize];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
}

- (void) updateSelectedProfile {
    OASettingsCategoryItems *items = self.itemsMap[OAExportSettingsCategory.SETTINGS];
    NSArray<OAApplicationModeBean *> *profileItems = [items getItemsForType:OAExportSettingsType.PROFILE];

    for (OAApplicationModeBean *item in profileItems) {
        if ([_appMode.stringKey isEqualToString:(item.stringKey)]) {
            NSArray<id> *selectedProfiles = @[item];
            self.selectedItemsMap[OAExportSettingsType.PROFILE] = selectedProfiles;
            break;
        }
    }
}

- (void)shareProfile
{
    _exportStarted = YES;
    [self setupView];
    [self.tableView reloadData];

    OASettingsHelper *settingsHelper = OASettingsHelper.sharedInstance;
    NSArray<OASettingsItem *> *settingsItems = [settingsHelper prepareSettingsItems:self.getSelectedItems settingsItems:@[] doExport:YES];
    [settingsHelper exportSettings:NSTemporaryDirectory() fileName:_appMode.toHumanString items:settingsItems exportItemFiles:YES delegate:self];
}

- (long)getItemSize:(NSString *)item
{
    NSFileManager *defaultManager = NSFileManager.defaultManager;
    NSDictionary *attrs = [defaultManager attributesOfItemAtPath:item error:nil];
    return attrs.fileSize;
}

- (void)updateFileSize
{
    _itemsSize = [self calculateItemsSize:self.getSelectedItems];
    _fileSize = [NSString stringWithFormat:OALocalizedString(@"approximate_file_size"), [NSByteCountFormatter stringFromByteCount:_itemsSize countStyle:NSByteCountFormatterCountStyleFile]];
}

- (UIView *)getHeaderForTableView:(UITableView *)tableView withFirstSectionText:(NSString *)text boldFragment:(NSString *)boldFragment forSection:(NSInteger)section
{
    if (section == 0)
    {
        UIView *headerView = [super getHeaderForTableView:tableView withFirstSectionText:text boldFragment:boldFragment forSection:section];
        UILabel *headerLabel = headerView.subviews[0];
        if (headerLabel)
        {
            NSAttributedString *oldHeaderText = headerLabel.attributedText;
            NSInteger baseHeaderLength = [oldHeaderText.string stringByReplacingOccurrencesOfString:_fileSize withString:@""].length;
            NSMutableAttributedString *newHeaderText = [[NSMutableAttributedString alloc] initWithAttributedString:[oldHeaderText attributedSubstringFromRange:NSMakeRange(0, baseHeaderLength)]];
            UIFont *fontFileSize = [UIFont systemFontOfSize:15];
            UIColor *colorFileSize = _itemsSize == 0 ? UIColorFromRGB(color_text_footer) : [UIColor blackColor];
            NSMutableAttributedString *headerFileSizeText = [[NSMutableAttributedString alloc] initWithString:_fileSize attributes:@{NSFontAttributeName:fontFileSize, NSForegroundColorAttributeName:colorFileSize}];
            [newHeaderText appendAttributedString:headerFileSizeText];
            headerLabel.attributedText = newHeaderText;
        }
        return headerView;
    }
    else
    {
        return nil;
    }
}

- (IBAction)primaryButtonPressed:(id)sender
{
    [self shareProfile];
}

#pragma mark - UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [self getHeaderForTableView:tableView withFirstSectionText:[self getDescriptionTextWithSize] boldFragment:self.descriptionBoldText forSection:section];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self getHeightForHeaderWithFirstHeaderText:[self getDescriptionTextWithSize] boldFragment:self.descriptionBoldText inSection:section];
}

#pragma mark - OASettingItemsSelectionDelegate

- (void)onItemsSelected:(NSArray *)items type:(OAExportSettingsType *)type
{
    self.selectedItemsMap[type] = items;
    [self updateFileSize];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
    [self updateControls];
}

#pragma mark - OASettingsImportExportDelegate

- (void)onSettingsCollectFinished:(BOOL)succeed empty:(BOOL)empty items:(NSArray<OASettingsItem *> *)items {
    if (succeed)
    {
        [self shareProfile];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"export_failed") preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.navigationController popViewControllerAnimated:YES];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - OASettingsImportExportDelegate

- (void)onSettingsExportFinished:(NSString *)file succeed:(BOOL)succeed {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
