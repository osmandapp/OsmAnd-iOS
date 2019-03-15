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
#import "OAPlugin.h"
#import "OAOsmEditingPlugin.h"
#import "OAOpenStreetMapLocalUtil.h"
#import "OAOpenStreetMapRemoteUtil.h"
#import "OAOsmEditingBottomSheetViewController.h"
#import "Localization.h"


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
@property (weak, nonatomic) IBOutlet UIView *toolBarView;
@property (weak, nonatomic) IBOutlet UIButton *buttonDelete;
@property (weak, nonatomic) IBOutlet UIButton *buttonApply;

@end

@implementation OAOsmEditingViewController
{
    UIPanGestureRecognizer *_tblMoveRecognizer;
    
    UIPageViewController *_pageController;
    OABasicEditingViewController *_basicEditingController;
    
    OAEditPOIData *_editPoiData;
    OAOsmEditingPlugin *_editingPlugin;
    id<OAOpenStreetMapUtilsProtocol> _editingUtil;
    
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
        _editingPlugin = (OAOsmEditingPlugin *) [OAPlugin getPlugin:OAOsmEditingPlugin.class];
        _editingUtil = [_editingPlugin getPoiModificationUtil];
    }
    return self;
}

+(void)commitEntity:(EOAAction)action
             entity:(OAEntity *)entity
         entityInfo:(OAEntityInfo *)info
            comment:(NSString *)comment shouldClose:(BOOL)closeCnageset
        editingUtil:(id<OAOpenStreetMapUtilsProtocol>)util
        changedTags:(NSSet *)changedTags
           callback:(void(^)())callback
{
    
    if (!info && CREATE != action && [util isKindOfClass:OAOpenStreetMapRemoteUtil.class]) {
        NSLog(@"Entity info was not loaded");
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [util commitEntityImpl:action entity:entity entityInfo:info comment:comment closeChangeSet:closeCnageset changedTags:changedTags];
    });
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [self setupView];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

-(UIView *) getTopView
{
    return _navBarView;
}

-(UIView *) getMiddleView
{
    return _contentView;
}

-(UIView *) getBottomView
{
    return _toolBarView;
}

-(CGFloat) getToolBarHeight
{
    return customSearchToolBarHeight;
}

-(CGFloat) getNavBarHeight
{
    return osmAndLiveNavBarHeight;
}

-(void) applyLocalization
{
    _titleView.text = _isAddingNewPOI ? OALocalizedString(@"osm_add_place") : OALocalizedString(@"osm_modify_place");
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
    [_buttonDelete setTitle:OALocalizedString(@"shared_string_delete") forState:UIControlStateNormal];
    [_buttonApply setTitle:([_editingUtil isKindOfClass:OAOpenStreetMapLocalUtil.class] ?
                            OALocalizedString(@"shared_string_apply") : OALocalizedString(@"shared_string_upload")) forState:UIControlStateNormal];
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
    
    _buttonApply.layer.cornerRadius = 9.0;
    _buttonDelete.layer.cornerRadius = 9.0;
    
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

- (IBAction)deletePressed:(id)sender {
    OAOsmEditingBottomSheetViewController *dialog = [[OAOsmEditingBottomSheetViewController alloc]
                                                     initWithEditingUtils:_editingUtil data:_editPoiData type:DELETE_EDIT];
    [dialog show];
}

- (IBAction)applyPressed:(id)sender {
    OAOsmEditingBottomSheetViewController *dialog = [[OAOsmEditingBottomSheetViewController alloc]
                                                     initWithEditingUtils:_editingUtil data:_editPoiData type:UPLOAD_EDIT];
    [dialog show];
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

#pragma mark - Keyboard Notifications

- (void) keyboardWillShow:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    NSValue *keyboardBoundsValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGFloat keyboardHeight = [keyboardBoundsValue CGRectValue].size.height;
    
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        _toolBarView.frame = CGRectMake(0, DeviceScreenHeight - keyboardHeight - 44.0, _toolBarView.frame.size.width, 44.0);
        [self applyHeight:32.0 cornerRadius:4.0 toView:_buttonApply];
        [self applyHeight:32.0 cornerRadius:4.0 toView:_buttonDelete];
        [[self view] layoutIfNeeded];
    } completion:nil];
}

- (void) keyboardWillHide:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        [self applySafeAreaMargins];
        [self applyHeight:42.0 cornerRadius:9.0 toView:_buttonApply];
        [self applyHeight:42.0 cornerRadius:9.0 toView:_buttonDelete];
        [[self view] layoutIfNeeded];
    } completion:nil];
}

-(void) applyHeight:(CGFloat)height cornerRadius:(CGFloat)radius toView:(UIView *)button
{
    CGRect buttonFrame = button.frame;
    buttonFrame.size.height = height;
    button.frame = buttonFrame;
    button.layer.cornerRadius = radius;
}

@end
