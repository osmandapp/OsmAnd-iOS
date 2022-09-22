//
//  OACloudRecentChangesViewController.m
//  OsmAnd Maps
//
//  Created by Skalii on 16.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAStatusBackupViewController.h"
#import "OAStatusBackupTableViewController.h"
#import "OAPrepareBackupResult.h"
#import "OABackupStatus.h"
#import "Localization.h"

@interface OAStatusBackupViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *navigationBarView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;

@property (weak, nonatomic) IBOutlet UIView *contentView;

@property (weak, nonatomic) IBOutlet UIView *bottomButtonsContainerView;
@property (weak, nonatomic) IBOutlet UIButton *pauseAllButton;
@property (weak, nonatomic) IBOutlet UIButton *backupNowButton;

@end

@implementation OAStatusBackupViewController
{
    UIPageViewController *_pageController;
    OAStatusBackupTableViewController *_allTableViewController;
    OAStatusBackupTableViewController *_conflictsTableViewController;
    
    OAPrepareBackupResult *_backup;
    OABackupStatus *_status;
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
    [self.backupNowButton setTitle:OALocalizedString(@"cloud_backup_now") forState:UIControlStateNormal];
    [self.pauseAllButton setTitle:OALocalizedString(@"cloud_pause_all") forState:UIControlStateNormal];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImage *backImage = [UIImage templateImageNamed:@"ic_navbar_chevron"];
    [self.backButton setImage:[self.backButton isDirectionRTL] ? backImage.imageFlippedForRightToLeftLayoutDirection : backImage
                     forState:UIControlStateNormal];

    _allTableViewController = [[OAStatusBackupTableViewController alloc] initWithTableType:EOARecentChangesAll backup:_backup status:_status];
    _conflictsTableViewController = [[OAStatusBackupTableViewController alloc] initWithTableType:EOARecentChangesConflicts backup:_backup status:_status];

    [self.segmentControl setTitle:OALocalizedString(@"shared_string_all") forSegmentAtIndex:EOARecentChangesAll];
    [self.segmentControl setTitle:OALocalizedString(@"cloud_conflicts") forSegmentAtIndex:EOARecentChangesConflicts];

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
    [self.contentView addSubview:_pageController.view];

    [NSLayoutConstraint constraintWithItem:self.contentView
                                 attribute:NSLayoutAttributeTop
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_pageController.view
                                 attribute:NSLayoutAttributeTop
                                multiplier:1.
                                  constant:0.];

    [NSLayoutConstraint constraintWithItem:self.contentView
                                 attribute:NSLayoutAttributeBottom
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_pageController.view
                                 attribute:NSLayoutAttributeBottom
                                multiplier:1.
                                  constant:0.];

    [NSLayoutConstraint constraintWithItem:self.contentView
                                 attribute:NSLayoutAttributeLeading
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_pageController.view
                                 attribute:NSLayoutAttributeLeading
                                multiplier:1.
                                  constant:0.];

    [NSLayoutConstraint constraintWithItem:self.contentView
                                 attribute:NSLayoutAttributeTrailing
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:_pageController.view
                                 attribute:NSLayoutAttributeTrailing
                                multiplier:1.
                                  constant:0.];

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
