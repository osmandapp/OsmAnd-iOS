//
//  OABaseCloudBackupViewController.m
//  OsmAnd Maps
//
//  Created by Yuliia Stetsenko on 18.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OABaseCloudBackupViewController.h"
#import "Localization.h"
#import "OASettingsHelper.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OAExportItemsViewController.h"

@interface OABaseCloudBackupViewController () <UIDocumentPickerDelegate>

@end

@implementation OABaseCloudBackupViewController {
    NSString *_titleText;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.backButton.hidden = YES;
    self.backImageButton.hidden = NO;

}

- (void)applyLocalization
{
    _titleText = OALocalizedString(@"backup_and_restore");
}

@end
