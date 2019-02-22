//
//  OAOsmEditingViewController.m
//  OsmAnd
//
//  Created by Paul on 2/20/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOsmEditingViewController.h"
#import "OABasicEditingViewController.h"
#import "OASizes.h"
#import "OAEditPOIData.h"
#import "OAEntity.h"
#import "OANode.h"


typedef NS_ENUM(NSInteger, EditingTab)
{
    BASIC = 0,
    ADVANCED
};

@interface OAOsmEditingViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate, OAOsmEditingDataProtocol>

@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentControl;
@property (weak, nonatomic) IBOutlet UIView *contentView;

@end

@implementation OAOsmEditingViewController
{
    UIPanGestureRecognizer *_tblMoveRecognizer;
    
    UIPageViewController *_pageController;
    OABasicEditingViewController *_basicEditingController;
    
    OAEditPOIData *_editPoiData;
    
    BOOL _isAddingNewPOI;
}

-(id) initWithLat:(double)latitude lon:(double)longitude
{
    _isAddingNewPOI = YES;
    OANode *node = [[OANode alloc] initWithId:-1 latitude:latitude longitude:longitude];
    self = [self initWithEntity:node];
    return self;
}

-(id) initWithEntity:(OAEntity *)entity
{
    self = [super init];
    if (self) {
        _editPoiData = [[OAEditPOIData alloc] initWithEntity:entity];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupView];
}

-(UIView *) getTopView
{
    return _navBarView;
}

-(UIView *) getMiddleView
{
    return _contentView;
}

-(CGFloat) getNavBarHeight
{
    return osmAndLiveNavBarHeight;
}

- (void)setupPageController {
    _pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    _pageController.dataSource = self;
    _pageController.delegate = self;
    CGRect frame = CGRectMake(0, 0, _contentView.frame.size.width, _contentView.frame.size.height);
    _pageController.view.frame = frame;
    _pageController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addChildViewController:_pageController];
    [_contentView addSubview:_pageController.view];
    [_pageController didMoveToParentViewController:self];
}

- (void) setupView
{
    [self applySafeAreaMargins];
    
    [self setupPageController];
    
    _basicEditingController = [[OABasicEditingViewController alloc] initWithFrame:_pageController.view.bounds];
    [_basicEditingController setDataProvider:self];
    
    [_pageController setViewControllers:@[_basicEditingController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}

- (IBAction)segmentChanged:(UISegmentedControl *)sender
{
//    [self moveGestureDetected:nil];
    switch (_segmentControl.selectedSegmentIndex)
    {
        case 0:
        {
            [_pageController setViewControllers:@[_basicEditingController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
            break;
        }
        case 1:
        {
            [_pageController setViewControllers:@[_basicEditingController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
            break;
        }
    }
//    [self processTabChange];
}

#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
//    if (viewController == _historyViewController)
//        return nil;
//    else if (viewController == _addressViewController)
//        return _categoriesViewController;
//    else
//        return _historyViewController;
    return _basicEditingController;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
//    if (viewController == _addressViewController)
//        return nil;
//    else if (viewController == _categoriesViewController)
//        return _addressViewController;
//    else
//        return _categoriesViewController;
    return _basicEditingController;
}

#pragma mark - UIPageViewControllerDelegate

-(void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed
{
    NSInteger prevTabIndex = _segmentControl.selectedSegmentIndex;
//    if (pageViewController.viewControllers[0] == _historyViewController)
//        _tabs.selectedSegmentIndex = 0;
//    else if (pageViewController.viewControllers[0] == _categoriesViewController)
//        _tabs.selectedSegmentIndex = 1;
//    else
//        _tabs.selectedSegmentIndex = 2;
//
//    if (prevTabIndex != _tabs.selectedSegmentIndex)
//        [self processTabChange];
}

- (IBAction)onBackPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - OAOsmEditingDataProtocol
-(OAEditPOIData *)getData
{
    return _editPoiData;
}

@end
