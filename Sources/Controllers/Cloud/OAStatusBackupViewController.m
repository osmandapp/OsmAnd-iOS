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
#import "OASyncBackupTask.h"
#import "OANetworkSettingsHelper.h"
#import "OAProfileSettingsItem.h"
#import "OAExportSettingsType.h"
#import "OAApplicationMode.h"
#import "OABackupDbHelper.h"
#import "OATableRowData.h"
#import "OAOsmAndFormatter.h"
#import "OAColors.h"
#import "OABackupHelper.h"
#import "OABackupError.h"
#import "Localization.h"

@interface OAStatusBackupViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate, OAOnPrepareBackupListener>

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
    NSMutableArray<OAStatusBackupTableViewController *> *_controllers;
    
    OABackupHelper *_backupHelper;
    OANetworkSettingsHelper *_settingsHelper;
    
    EOARecentChangesType _startType;
    NSInteger _prevTab;
}

- (instancetype) initWithType:(EOARecentChangesType)type
{
    self = [super init];
    if (self) {
        _startType = type;
        _settingsHelper = [OANetworkSettingsHelper sharedInstance];
        _backupHelper = OABackupHelper.sharedInstance;
        [self setupNotificationListeners];
        [_backupHelper addPrepareBackupListener:self];
    }
    return self;
}

- (void)applyLocalization
{
    self.titleLabel.text = OALocalizedString(@"cloud_recent_changes");
    [self.segmentControl setTitle:OALocalizedString(@"download_tab_local") forSegmentAtIndex:EOARecentChangesLocal];
    [self.segmentControl setTitle:OALocalizedString(@"shared_string_file_cloud") forSegmentAtIndex:EOARecentChangesRemote];
    [self.segmentControl setTitle:OALocalizedString(@"cloud_conflicts") forSegmentAtIndex:EOARecentChangesConflicts];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImage *backImage = [UIImage templateImageNamed:@"ic_navbar_chevron"];
    [self.backButton setImage:[self.backButton isDirectionRTL] ? backImage.imageFlippedForRightToLeftLayoutDirection : backImage
                     forState:UIControlStateNormal];
    [_segmentControl setTitleTextAttributes:@{NSForegroundColorAttributeName : UIColor.whiteColor} forState:UIControlStateNormal];
    [_segmentControl setTitleTextAttributes:@{NSForegroundColorAttributeName : UIColor.blackColor} forState:UIControlStateSelected];
}

- (void)setupNotificationListeners
{
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onBackupFinished:) name:kBackupSyncFinishedNotification object:nil];
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_backupHelper removePrepareBackupListener:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _controllers = [NSMutableArray array];
    for (EOARecentChangesType i = 0; i <= EOARecentChangesConflicts; i++)
    {
        [_controllers addObject:[[OAStatusBackupTableViewController alloc] initWithTableType:i]];
    }
    [self setupPageController];
    _segmentControl.selectedSegmentIndex = _startType;
    [self setupBottomButtons];
    _prevTab = _segmentControl.selectedSegmentIndex;
    [_pageController setViewControllers:@[_controllers[_startType]]
                              direction:_startType == EOARecentChangesConflicts ? UIPageViewControllerNavigationDirectionReverse : UIPageViewControllerNavigationDirectionForward
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
    NSInteger currTab = self.segmentControl.selectedSegmentIndex;
    [_pageController setViewControllers:@[_controllers[currTab]]
                              direction:_prevTab > currTab ? UIPageViewControllerNavigationDirectionReverse : UIPageViewControllerNavigationDirectionForward
                               animated:YES
                             completion:nil];
    _prevTab = currTab;
    [self setupBottomButtons];
}

- (void)setupBottomButtons
{
    BOOL isSyncing = [_settingsHelper isBackupSyncing];
    BOOL isPreparing = [_backupHelper isBackupPreparing];
    
    self.leftBottomButton.userInteractionEnabled = isSyncing && !isPreparing;
    [self.leftBottomButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.leftBottomButton setTintColor:isSyncing && !isPreparing ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_text_footer)];
    [self.leftBottomButton setTitleColor:isSyncing && !isPreparing ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_text_footer)
                              forState:UIControlStateNormal];

    BOOL isEnabled = !isSyncing && !isPreparing && self.rightButtonEnabled;
    self.rightBottomButton.userInteractionEnabled = isEnabled;
    [self.rightBottomButton setTitle:self.rightButtonTitle forState:UIControlStateNormal];
    [self.rightBottomButton setTintColor:isEnabled ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_text_footer)];
    [self.rightBottomButton setTitleColor:isEnabled ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_text_footer)
                               forState:UIControlStateNormal];
}

- (BOOL) rightButtonEnabled
{
    return [_controllers[_segmentControl.selectedSegmentIndex] hasItems];
}

- (NSString *) rightButtonTitle
{
    switch (_segmentControl.selectedSegmentIndex)
    {
        case EOARecentChangesLocal:
            return OALocalizedString(@"upload_all");
        case EOARecentChangesRemote:
            return OALocalizedString(@"download_all");
        default:
            return @"";
    }
}

- (IBAction)leftButtonPressed:(UIButton *)sender
{
    [_settingsHelper cancelSync];
}

- (IBAction)rightButtonPressed:(UIButton *)sender
{
    switch (_segmentControl.selectedSegmentIndex)
    {
        case EOARecentChangesRemote:
            return [_settingsHelper syncSettingsItems:kSyncItemsKey operation:EOABackupSyncOperationDownload];
        case EOARecentChangesLocal:
            return [_settingsHelper syncSettingsItems:kSyncItemsKey operation:EOABackupSyncOperationUpload];
        default:
            return;
    }
}

- (void)setRowIcon:(OATableRowData *)rowData item:(OASettingsItem *)item
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

- (NSString *)generateTimeString:(long)timeMs summary:(NSString *)summary
{
    if (timeMs != -1)
    {
        NSString *time = [OAOsmAndFormatter getFormattedPassedTime:(timeMs / 1000)
                                                               def:OALocalizedString(@"shared_string_never")];
        return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_colon"), summary, time];
    }
    else
    {
        return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_colon"), summary, OALocalizedString(@"shared_string_never")];
    }
}

- (NSString *)getDescriptionForItemType:(EOASettingsItemType)type fileName:(NSString *)fileName summary:(NSString *)summary
{
    OAUploadedFileInfo *info = [[OABackupDbHelper sharedDatabase] getUploadedFileInfo:[OASettingsItemType typeName:type] name:fileName];
    return [self generateTimeString:info.uploadTime summary:summary];
}

#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
      viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSInteger idx = [_controllers indexOfObject:(OAStatusBackupTableViewController *)viewController];
    if (idx < 1)
        return nil;
    else
        return _controllers[idx - 1];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController
       viewControllerAfterViewController:(UIViewController *)viewController
{
    NSInteger idx = [_controllers indexOfObject:(OAStatusBackupTableViewController *)viewController];
    if (idx == _controllers.count - 1)
        return nil;
    else
        return _controllers[idx + 1];
}

#pragma mark - UIPageViewControllerDelegate

-(void)pageViewController:(UIPageViewController *)pageViewController
       didFinishAnimating:(BOOL)finished
  previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers
      transitionCompleted:(BOOL)completed
{
    NSInteger idx = [_controllers indexOfObject:(OAStatusBackupTableViewController *)pageViewController.viewControllers[0]];
    _segmentControl.selectedSegmentIndex = idx;
    [self setupBottomButtons];
}

// MARK: Sync callbacks

- (void)onBackupFinished:(NSNotification *)notification
{
    NSString *error = notification.userInfo[@"error"];
    if (error != nil)
    {
        [OAUtilities showToast:nil details:[[OABackupError alloc] initWithError:error].getLocalizedError duration:.4 inView:self.view];
    }
    else if (!_settingsHelper.isBackupSyncing && !_backupHelper.isBackupPreparing)
    {
        [_backupHelper prepareBackup];
    }
}

// MARK: OAOnPrepareBackupListener

- (void)onBackupPreparing
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupBottomButtons];
    });
}

- (void)onBackupPrepared:(OAPrepareBackupResult *)backupResult
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupBottomButtons];
    });
}

@end
