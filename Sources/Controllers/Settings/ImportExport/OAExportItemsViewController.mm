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
#import "OAProgressTitleCell.h"
#import "OAColors.h"
#import "OAExportSettingsCategory.h"
#import "OASettingsCategoryItems.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

#define kDefaultArchiveName @"Export"
#define kSettingsSectionIndex 0
#define kMyPlacesSectionIndex 1
#define kResourcesSectionIndex 2

typedef NS_ENUM(NSInteger, EOAExportItemsViewControllerStateType) {
    EOAExportItemsViewControllerStateTypeInited,
    EOAExportItemsViewControllerStateTypeExportStarted,
    EOAExportItemsViewControllerStateTypeExportDone
};

@implementation OAExportItemsViewController
{
    OASettingsHelper *_settingsHelper;
    OAApplicationMode *_appMode;
    
    EOAExportItemsViewControllerStateType _state;
    BOOL _shouldOpenSettingsOnInit;
    BOOL _shouldOpenMyPlacesOnInit;
    BOOL _shouldOpenResourcesOnInit;
}

#pragma mark - Initialization

- (instancetype)initWithAppMode:(OAApplicationMode *)appMode
{
    self = [super init];
    if (self)
    {
        _appMode = appMode;
        _shouldOpenSettingsOnInit = YES;
        [self postInit];
    }
    return self;
}

- (instancetype)initWithTracks:(NSArray<NSString *> *)tracks
{
    self = [super init];
    if (self)
    {
        self.selectedItemsMap[OAExportSettingsType.TRACKS] = tracks;
        _shouldOpenMyPlacesOnInit = YES;
        [self postInit];
    }
    return self;
}

- (instancetype)initWithType:(OAExportSettingsType *)type selectedItems:(NSArray *)selectedItems
{
    self = [super init];
    if (self)
    {
        self.selectedItemsMap[type] = selectedItems;
        _shouldOpenMyPlacesOnInit = YES;
        [self postInit];
    }
    return self;
}

- (instancetype)initWithTypes:(NSDictionary<OAExportSettingsType *, NSArray<id> *> *)typesItems
{
    self = [super init];
    if (self)
    {
        for (OAExportSettingsType *type in typesItems.allKeys)
        {
            self.selectedItemsMap[type] = typesItems[type];
            if ([type isSettingsCategory])
                _shouldOpenSettingsOnInit = YES;
            else if ([type isMyPlacesCategory])
                _shouldOpenMyPlacesOnInit = YES;
            else if ([type isResourcesCategory])
                _shouldOpenResourcesOnInit = YES;
            [self postInit];
        }
    }
    return self;
}

- (void)commonInit
{
    _settingsHelper = [OASettingsHelper sharedInstance];
    _state = EOAExportItemsViewControllerStateTypeInited;
    self.itemsMap = [_settingsHelper getSettingsByCategory:YES];
    self.itemTypes = self.itemsMap.allKeys;
}

- (void)postInit
{
    if (_appMode)
        [self updateSelectedProfile];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return _state == EOAExportItemsViewControllerStateTypeExportStarted ? OALocalizedString(@"shared_string_preparing") : _appMode ? OALocalizedString(@"export_profile") : OALocalizedString(@"shared_string_export");
}

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    return _state == EOAExportItemsViewControllerStateTypeInited ? [super getRightNavbarButtons] : nil;
}

- (NSAttributedString *)getTableHeaderDescriptionAttr
{
    NSString *exportSelectDescr = _state == EOAExportItemsViewControllerStateTypeInited ? [OALocalizedString(@"export_profile_select_descr") stringByAppendingString:@"\n"] : @"";
    long itemsSize = [self calculateItemsSize:self.getSelectedItems];
    NSString *approximateFileSize = [NSString stringWithFormat:@"%@: %@",
                                        OALocalizedString(@"approximate_file_size"),
                                        [NSByteCountFormatter stringFromByteCount:itemsSize countStyle:NSByteCountFormatterCountStyleFile]];
    NSMutableAttributedString *descriptionAttr = [[NSMutableAttributedString alloc] initWithString:[exportSelectDescr stringByAppendingString:approximateFileSize]];
    [descriptionAttr setColor:[UIColor colorNamed:ACColorNameTextColorSecondary] forString:exportSelectDescr];
    [descriptionAttr setColor:itemsSize > 0 ? [UIColor colorNamed:ACColorNameTextColorPrimary] : [UIColor colorNamed:ACColorNameTextColorSecondary] forString:approximateFileSize];
    [descriptionAttr setFont:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline] forString:descriptionAttr.string];
    [descriptionAttr setMinLineHeight:18. alignment:NSTextAlignmentNatural forString:descriptionAttr.string];
    return descriptionAttr;
}

- (NSString *)getBottomButtonTitle
{
    return _state == EOAExportItemsViewControllerStateTypeInited ? [super getBottomButtonTitle] : @"";
}

#pragma mark - Table data

- (void)generateData
{
    if (_state == EOAExportItemsViewControllerStateTypeInited)
    {
        [super generateData];

        if (_shouldOpenSettingsOnInit)
        {
            self.data[kSettingsSectionIndex].isOpen = YES;
            _shouldOpenSettingsOnInit = NO;
        }
        if (_shouldOpenMyPlacesOnInit)
        {
            self.data[kMyPlacesSectionIndex].isOpen = YES;
            _shouldOpenMyPlacesOnInit = NO;
        }
        if (_shouldOpenResourcesOnInit)
        {
            self.data[kResourcesSectionIndex].isOpen = YES;
            _shouldOpenResourcesOnInit = NO;
        }
    }
    else if (_state == EOAExportItemsViewControllerStateTypeExportStarted)
    {
        OATableCollapsableGroup *group = [[OATableCollapsableGroup alloc] init];
        group.type = [OAProgressTitleCell getCellIdentifier];
        group.groupName = OALocalizedString(@"preparing_file");
        self.data = @[group];
    }
    else if (_state == EOAExportItemsViewControllerStateTypeExportDone)
    {
        self.data = @[];
    }
}

- (BOOL)hideFirstHeader
{
    return YES;
}

#pragma mark - Additions

- (long)getItemSize:(NSString *)item
{
    NSFileManager *defaultManager = NSFileManager.defaultManager;
    NSDictionary *attrs = [defaultManager attributesOfItemAtPath:item error:nil];
    return attrs.fileSize;
}

- (void)updateSelectedProfile
{
    OASettingsCategoryItems *items = self.itemsMap[OAExportSettingsCategory.SETTINGS];
    NSArray<OAApplicationModeBean *> *profileItems = [items getItemsForType:OAExportSettingsType.PROFILE];

    for (OAApplicationModeBean *item in profileItems)
    {
        if ([_appMode.stringKey isEqualToString:(item.stringKey)])
        {
            NSArray<id> *selectedProfiles = @[item];
            self.selectedItemsMap[OAExportSettingsType.PROFILE] = selectedProfiles;
            break;
        }
    }
}

- (void)shareProfile
{
    _state = EOAExportItemsViewControllerStateTypeExportStarted;
    [self updateUI];

    OASettingsHelper *settingsHelper = OASettingsHelper.sharedInstance;
    NSArray<OASettingsItem *> *settingsItems = [settingsHelper prepareSettingsItems:self.getSelectedItems settingsItems:@[] doExport:YES];
    NSString *fileName;
    if (_appMode)
    {
        fileName = _appMode.toHumanString;
    }
    else
    {
        NSDate *date = [NSDate date];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"dd-MM-yy"];
        NSString *dateFormat = [formatter stringFromDate:date];
        fileName = [NSString stringWithFormat:@"%@_%@", kDefaultArchiveName, dateFormat];
    }
    [settingsHelper exportSettings:NSTemporaryDirectory() fileName:fileName items:settingsItems exportItemFiles:YES delegate:self];
}

#pragma mark - Selectors

- (void)onBottomButtonPressed
{
    [self shareProfile];
}

#pragma mark - OASettingItemsSelectionDelegate

- (void)onItemsSelected:(NSArray *)items type:(OAExportSettingsType *)type
{
    self.selectedItemsMap[type] = items;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];

    OAExportSettingsCategory * category = [type getCategory];
    NSInteger indexCategory = [self.itemTypes indexOfObject:category];
    if (category && indexCategory != 0)
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexCategory] withRowAnimation:UITableViewRowAnimationNone];

    [self applyLocalization];
    [self updateNavbar];
    [self updateBottomButtons];
}

#pragma mark - OASettingsImportExportDelegate

- (void)onSettingsCollectFinished:(BOOL)succeed empty:(BOOL)empty items:(NSArray<OASettingsItem *> *)items
{
    if (succeed)
    {
        [self shareProfile];
    }
    else
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"export_failed") preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.navigationController popViewControllerAnimated:YES];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - OASettingsImportExportDelegate

- (void)onSettingsExportFinished:(NSString *)file succeed:(BOOL)succeed
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _state = EOAExportItemsViewControllerStateTypeExportDone;
        [self updateUI];
        
        if (succeed)
        {
            NSURL *fileUrl = [NSURL fileURLWithPath:file];            
            CGRect bottomScreenCenterPoint = CGRectMake(CGRectGetMidX(self.view.bounds), self.view.bounds.size.height, 0, 0);
            [self showActivity:@[fileUrl] applicationActivities:nil excludedActivityTypes:nil sourceView:self.view sourceRect:bottomScreenCenterPoint barButtonItem:nil permittedArrowDirections:UIPopoverArrowDirectionDown completionWithItemsHandler:^{
                [self.navigationController popViewControllerAnimated:YES];
                [NSFileManager.defaultManager removeItemAtURL:fileUrl error:nil];
            }];
        }
    });
}

@end
