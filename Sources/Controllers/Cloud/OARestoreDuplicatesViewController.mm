//
//  OARestoreDuplicatesViewControllers.m
//  OsmAnd Maps
//
//  Created by Paul on 30.06.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OARestoreDuplicatesViewController.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAImportBackupTask.h"
#import "OASettingsHelper.h"
#import "OANetworkSettingsHelper.h"
#import "OASettingsItem.h"
#import "OsmAndApp.h"
#import "OAImportCompleteViewController.h"

@interface OARestoreDuplicatesViewController () <OAImportListener>

@end

@implementation OARestoreDuplicatesViewController
{
    OANetworkSettingsHelper *_helper;
}

- (void) fetchData
{
    _helper = OANetworkSettingsHelper.sharedInstance;
    OAImportBackupTask *importTask = [_helper getImportTask:kRestoreItemsKey];
    if (importTask)
    {
        if (self.settingsItems == nil)
            self.settingsItems = importTask.selectedItems;
        if (self.duplicatesList == nil)
            self.duplicatesList = importTask.duplicates;
        [importTask setImportListener:self];
    }
}


- (void) applyLocalization
{
    self.screenTitle = OALocalizedString(@"shared_string_restoring");
    self.screenDescription = OALocalizedString(@"restoring_from");
    [self.backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
}

- (void) importItems:(BOOL)shouldReplace
{
    if (self.settingsItems)
    {
        [self setupImportingUI];
        for (OASettingsItem *item in self.settingsItems)
        {
            [item setShouldReplace:shouldReplace];
        }
        @try {
            [_helper importSettings:kRestoreItemsKey items:self.settingsItems forceReadData:NO listener:self];
        } @catch (NSException *exception) {
            NSLog(@"Restore duplicates error: %@", exception.reason);
        }
    }
}

- (IBAction)backImageButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)backButtonPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Actions

- (IBAction)primaryButtonPressed:(id)sender
{
    [self importItems:YES];
}

- (IBAction)secondaryButtonPressed:(id)sender
{
    [self importItems:NO];
}

#pragma mark - OAImportListener

- (void)onImportFinished:(BOOL)succeed needRestart:(BOOL)needRestart items:(NSArray<OASettingsItem *> *)items {
    if (succeed)
    {
        OsmAndAppInstance app = OsmAndApp.instance;
        app.resourcesManager->rescanUnmanagedStoragePaths();
        [app.localResourcesChangedObservable notifyEvent];
        [app loadRoutingFiles];
        
//        reloadIndexes(items);
//        AudioVideoNotesPlugin plugin = OsmandPlugin.getPlugin(AudioVideoNotesPlugin.class);
//        if (plugin != null) {
//            plugin.indexingFiles(true, true);
//        }
        OAImportCompleteViewController *importVC = [[OAImportCompleteViewController alloc] initWithSettingsItems:[OASettingsHelper getSettingsToOperate:items importComplete:YES] fileName:OALocalizedString(@"osmand_cloud")];
        [self.navigationController pushViewController:importVC animated:YES];
    }
}

- (void)onImportItemFinished:(NSString *)type fileName:(NSString *)fileName {
    
}

- (void)onImportItemProgress:(NSString *)type fileName:(NSString *)fileName value:(int)value {
    
}

- (void)onImportItemStarted:(NSString *)type fileName:(NSString *)fileName work:(int)work {
    
}

@end
