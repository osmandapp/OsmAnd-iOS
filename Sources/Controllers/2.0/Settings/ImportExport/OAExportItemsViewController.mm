//
//  OAExportItemsViewController.m
//  OsmAnd
//
//  Created by Paul on 08.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAExportItemsViewController.h"
#import "OARootViewController.h"
#import "OASettingsHelper.h"
#import "OAExportSettingsType.h"
#import "Localization.h"
#import "OAProgressTitleCell.h"

@implementation OAExportItemsViewController
{
    NSString *_descriptionText;
    NSString *_descriptionBoldText;
    
    OASettingsHelper *_settingsHelper;
    OAApplicationMode *_appMode;
    
    BOOL _exportStarted;
}

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode
{
    self = [super init];
    if (self)
    {
        _appMode = appMode;
        self.selectedItemsMap[OAExportSettingsType.PROFILE] = @[appMode.toModeBean];
    }
    return self;
}

- (void)commonInit
{
    _settingsHelper = OASettingsHelper.sharedInstance;
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

- (void) setupView
{
    [self setTableHeaderView:OALocalizedString(@"export_profile")];
    
    if (_exportStarted)
    {
        OATableGroupToImport *group = [[OATableGroupToImport alloc] init];
        group.type = [OAProgressTitleCell getCellIdentifier];
        group.groupName = OALocalizedString(@"preparing_file");
        self.data = @[group];
        return;
    }
    self.itemsMap = [_settingsHelper getSettingsByCategory:YES];
    self.itemTypes = self.itemsMap.allKeys;
    [self generateData];
}

- (NSString *) descriptionText
{
    return _descriptionText;
}

- (NSString *) descriptionBoldText
{
    return _descriptionBoldText;
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

- (IBAction) primaryButtonPressed:(id)sender
{
    [self shareProfile];
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


- (void)onSettingsExportFinished:(NSString *)file succeed:(BOOL)succeed {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
