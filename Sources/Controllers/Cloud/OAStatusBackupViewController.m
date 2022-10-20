//
//  OACloudRecentChangesViewController.m
//  OsmAnd Maps
//
//  Created by Skalii on 16.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAStatusBackupViewController.h"
#import "OAStatusBackupTableViewController.h"
#import "OABaseBackupTypesViewController.h"
#import "OAPrepareBackupResult.h"
#import "OABackupStatus.h"
#import "OABackupInfo.h"
#import "OANetworkSettingsHelper.h"
#import "OAProfileSettingsItem.h"
#import "OAExportSettingsType.h"
#import "OAApplicationMode.h"
#import "OABackupDbHelper.h"
#import "OATableViewRowData.h"
#import "OAOsmAndFormatter.h"
#import "OAColors.h"
#import "Localization.h"

@interface OAStatusBackupViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate, OAStatusBackupTableDelegate>

@property (weak, nonatomic) IBOutlet UIView *navigationBarView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;

@property (weak, nonatomic) IBOutlet UIView *contentView;

@property (weak, nonatomic) IBOutlet UIView *bottomButtonsContainerView;
@property (weak, nonatomic) IBOutlet UIButton *leftBottomButton;
@property (weak, nonatomic) IBOutlet UIButton *rightBottomButton;

@end

@implementation OAStatusBackupViewController
{
    UIPageViewController *_pageController;
    OAStatusBackupTableViewController *_allTableViewController;
    OAStatusBackupTableViewController *_conflictsTableViewController;
    
    OAPrepareBackupResult *_backup;
    OABackupStatus *_status;
    OANetworkSettingsHelper *_settingsHelper;
}

- (instancetype) initWithBackup:(OAPrepareBackupResult *)backup status:(OABackupStatus *)status
{
    self = [super init];
    if (self) {
        _backup = backup;
        _status = status;
    }
    return self;
}

- (void)applyLocalization
{
    self.titleLabel.text = OALocalizedString(@"cloud_recent_changes");
    [self.segmentControl setTitle:OALocalizedString(@"shared_string_all") forSegmentAtIndex:EOARecentChangesAll];
    [self.segmentControl setTitle:OALocalizedString(@"cloud_conflicts") forSegmentAtIndex:EOARecentChangesConflicts];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImage *backImage = [UIImage templateImageNamed:@"ic_navbar_chevron"];
    [self.backButton setImage:[self.backButton isDirectionRTL] ? backImage.imageFlippedForRightToLeftLayoutDirection : backImage
                     forState:UIControlStateNormal];
    _settingsHelper = [OANetworkSettingsHelper sharedInstance];
    [self setupBottomButtons:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _allTableViewController = [[OAStatusBackupTableViewController alloc] initWithTableType:EOARecentChangesAll backup:_backup status:_status];
    [_allTableViewController setDelegate:self];
    _conflictsTableViewController = [[OAStatusBackupTableViewController alloc] initWithTableType:EOARecentChangesConflicts backup:_backup status:_status];
    [_conflictsTableViewController setDelegate:self];
    [self setupPageController];
    [_pageController setViewControllers:@[_allTableViewController]
                              direction:UIPageViewControllerNavigationDirectionForward
                               animated:NO
                             completion:nil];
}

- (void)setupPageController
{
    _pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                      navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                    options:nil];
    _pageController.dataSource = self;
    _pageController.delegate = self;

    [self addChildViewController:_pageController];
    _pageController.view.frame = self.contentView.bounds;
    _pageController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.contentView addSubview:_pageController.view];
    [_pageController didMoveToParentViewController:self];
}

- (IBAction)segmentChanged:(UISegmentedControl *)sender
{
    [self.view endEditing:YES];
    
    switch (self.segmentControl.selectedSegmentIndex)
    {
        case 0:
        {
            [_pageController setViewControllers:@[_allTableViewController]
                                      direction:UIPageViewControllerNavigationDirectionForward
                                       animated:YES
                                     completion:nil];
            break;
        }
        case 1:
        {
            [_pageController setViewControllers:@[_conflictsTableViewController]
                                      direction:UIPageViewControllerNavigationDirectionForward
                                       animated:YES
                                     completion:nil];
            break;
        }
    }
}

- (void)setupBottomButtons:(BOOL)enabled
{
    BOOL isExporting = [_settingsHelper isBackupExporting];
    BOOL isImporting = [_settingsHelper isBackupImporting];

    self.leftBottomButton.userInteractionEnabled = (isExporting || isImporting) && enabled;
    [self.leftBottomButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.leftBottomButton setTintColor:(isExporting || isImporting) && enabled ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_text_footer)];
    [self.leftBottomButton setTitleColor:(isExporting || isImporting) && enabled ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_text_footer)
                              forState:UIControlStateNormal];

    self.rightBottomButton.userInteractionEnabled = !isExporting && !isImporting && enabled;
    [self.rightBottomButton setTitle:OALocalizedString(@"cloud_backup_now") forState:UIControlStateNormal];
    [self.rightBottomButton setTintColor:!isExporting && !isImporting && enabled ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_text_footer)];
    [self.rightBottomButton setTitleColor:!isExporting && !isImporting && enabled ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_text_footer)
                               forState:UIControlStateNormal];
}

- (IBAction)leftButtonPressed:(UIButton *)sender
{
    [_settingsHelper cancelImport];
    [_settingsHelper cancelExport];
}

- (IBAction)rightButtonPressed:(UIButton *)sender
{
    @try
    {
        NSArray<OASettingsItem *> *items = _backup.backupInfo.itemsToUpload;
        if (items.count > 0 || _backup.backupInfo.filteredFilesToDelete.count > 0)
        {
            [_settingsHelper exportSettings:kBackupItemsKey
                                      items:items
                              itemsToDelete:_backup.backupInfo.itemsToDelete
                                   listener:self.segmentControl.selectedSegmentIndex == 0 ? _allTableViewController : _conflictsTableViewController];
        }
    }
    @catch (NSException *e)
    {
        NSLog(@"Backup generation error: %@", e.reason);
    }
}

#pragma mark - OAStatusBackupTableDelegate

- (void)disableBottomButtons
{
    [self setupBottomButtons:NO];
}

- (void)updateBackupStatus:(OAPrepareBackupResult *)backupResult
{
    _backup = backupResult;
    _status = [OABackupStatus getBackupStatus:backupResult];
    [self setupBottomButtons:YES];
    if (self.delegate)
        [self.delegate onCompleteTasks];
    [_conflictsTableViewController updateData:_backup status:_status];
    [_allTableViewController updateData:_backup status:_status];
}

- (void)setRowIcon:(OATableViewRowData *)rowData item:(OASettingsItem *)item
{
    if ([item isKindOfClass:OAProfileSettingsItem.class])
    {
        OAProfileSettingsItem *profileItem = (OAProfileSettingsItem *) item;
        OAApplicationMode *mode = profileItem.appMode;
        [rowData setObj:[UIImage templateImageNamed:[mode getIconName]] forKey:@"icon"];
    }
    else
    {
        OAExportSettingsType *type = [OAExportSettingsType getExportSettingsTypeForItem:item];
        if (type != nil)
            [rowData setObj:type.icon forKey:@"icon"];
    }
}

- (NSString *)getDescriptionForItemType:(EOASettingsItemType)type fileName:(NSString *)fileName summary:(NSString *)summary
{
    OAUploadedFileInfo *info = [[OABackupDbHelper sharedDatabase] getUploadedFileInfo:[OASettingsItemType typeName:type] name:fileName];
    if (info)
    {
        NSString *time = [OAOsmAndFormatter getFormattedPassedTime:(info.uploadTime / 1000)
                                                               def:OALocalizedString(@"shared_string_never")];
        return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_colon"), summary, time];
    }
    else
    {
        return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_colon"), summary, OALocalizedString(@"shared_string_never")];
    }
}

#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
      viewControllerBeforeViewController:(UIViewController *)viewController
{
    if (viewController == _allTableViewController)
        return nil;
    else
        return _allTableViewController;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
       viewControllerAfterViewController:(UIViewController *)viewController
{
    if (viewController == _allTableViewController)
        return _conflictsTableViewController;
    else
        return nil;
}

#pragma mark - UIPageViewControllerDelegate

-(void)pageViewController:(UIPageViewController *)pageViewController
       didFinishAnimating:(BOOL)finished
  previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers
      transitionCompleted:(BOOL)completed
{
    if (pageViewController.viewControllers[0] == _allTableViewController)
        _segmentControl.selectedSegmentIndex = EOARecentChangesAll;
    else
       _segmentControl.selectedSegmentIndex = EOARecentChangesConflicts;
}

@end
