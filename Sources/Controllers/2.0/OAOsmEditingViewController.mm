//
//  OAOsmEditingViewController.m
//  OsmAnd
//
//  Created by Paul on 2/20/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOsmEditingViewController.h"
#import "OABasicEditingViewController.h"
#import "OAAdvancedEditingViewController.h"
#import "OASizes.h"
#import "OAEditPOIData.h"
#import "OAEntity.h"
#import "OANode.h"
#import "OAWay.h"
#import "OAPOIType.h"
#import "OAPlugin.h"
#import "OAOsmEditingPlugin.h"
#import "OAOpenStreetMapLocalUtil.h"
#import "OAOpenStreetMapRemoteUtil.h"
#import "Localization.h"


typedef NS_ENUM(NSInteger, EditingTab)
{
    BASIC = 0,
    ADVANCED
};

@interface OAOsmEditingViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate, OAOsmEditingDataProtocol, UIGestureRecognizerDelegate>

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
    UIPageViewController *_pageController;
    OABasicEditingViewController *_basicEditingController;
    OAAdvancedEditingViewController *_advancedEditingController;
    
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
           callback:(void(^)(void))callback
{
    if (!info && CREATE != action && [util isKindOfClass:OAOpenStreetMapRemoteUtil.class]) {
        NSLog(@"Entity info was not loaded");
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [util commitEntityImpl:action entity:entity entityInfo:info comment:comment closeChangeSet:closeCnageset changedTags:changedTags];
        if (callback)
            callback();
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
    [_buttonApply setTitle:OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
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
    _advancedEditingController = [[OAAdvancedEditingViewController alloc] initWithFrame:_pageController.view.bounds];
    [_advancedEditingController setDataProvider:self];
    
    [_pageController setViewControllers:@[_basicEditingController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}

- (IBAction)segmentChanged:(UISegmentedControl *)sender
{
    switch (_segmentControl.selectedSegmentIndex)
    {
        case 0:
        {
            [_pageController setViewControllers:@[_basicEditingController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
            break;
        }
        case 1:
        {
            [_pageController setViewControllers:@[_advancedEditingController] direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:nil];
            break;
        }
    }
}

- (IBAction)deletePressed:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"osm_delete_confirmation_descr") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [OAOsmEditingViewController commitEntity:DELETE entity:_editPoiData.getEntity entityInfo:[_editingUtil getEntityInfo:_editPoiData.getEntity.getId] comment:@"" shouldClose:NO editingUtil:_editingPlugin.getOfflineModificationUtil changedTags:nil callback:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.navigationController popViewControllerAnimated:YES];
            });
        }];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
    
}

- (IBAction)applyPressed:(id)sender {
    [self.class savePoi:@"" poiData:_editPoiData editingUtil:_editingPlugin.getOfflineModificationUtil closeChangeSet:NO];
    [self.navigationController popViewControllerAnimated:YES];
}

+ (void) savePoi:(NSString *) comment poiData:(OAEditPOIData *)poiData editingUtil:(id<OAOpenStreetMapUtilsProtocol>)editingUtil closeChangeSet:(BOOL)closeChangeset
{
    OAEntity *original = poiData.getEntity;
    
    BOOL offlineEdit = [editingUtil isKindOfClass:OAOpenStreetMapLocalUtil.class];
    OAEntity *entity;
    if ([original isKindOfClass:OANode.class])
        entity = [[OANode alloc] initWithId:original.getId latitude:original.getLatitude longitude:original.getLongitude];
    else if ([original isKindOfClass:OAWay.class])
        entity = [[OAWay alloc] initWithId:original.getId latitude:original.getLatitude longitude:original.getLongitude ids:((OAWay *)original).getNodeIds];
    else
        return;
    [poiData.getTagValues enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSString * _Nonnull value, BOOL * _Nonnull stop) {
        if (key.length > 0 && value.length > 0 && ![key isEqualToString:POI_TYPE_TAG])
            [entity putTagNoLC:key value:value];
        
    }];
    
    NSString *poiTypeTag = poiData.getTagValues[POI_TYPE_TAG];
    if (poiTypeTag) {
        NSString *formattedType = [[poiTypeTag stringByTrimmingCharactersInSet:
                                    [NSCharacterSet whitespaceAndNewlineCharacterSet]] lowerCase];
        OAPOIType *poiType = poiData.getAllTranslatedSubTypes[formattedType];
        if (poiType) {
            [entity putTagNoLC:poiType.getEditOsmTag value:poiType.getEditOsmValue];
            [entity removeTag:[REMOVE_TAG_PREFIX stringByAppendingString:poiType.getEditOsmTag]];
            if (poiType.getOsmTag2)
            {
                [entity putTagNoLC:poiType.getOsmTag2 value:poiType.getOsmValue2];
                [entity removeTag:[REMOVE_TAG_PREFIX stringByAppendingString:poiType.getOsmTag2]];
            }
        }
        else if (poiTypeTag.length > 0)
        {
            OAPOICategory *category = poiData.getPoiCategory;
            if (category)
                [entity putTagNoLC:category.tag value:poiTypeTag];
        }
        if (offlineEdit && poiTypeTag.length > 0)
            [entity putTagNoLC:POI_TYPE_TAG value:poiTypeTag];
        
        comment = comment ? comment : @"";
    }
    EOAAction action = original.getId <= 0 ? CREATE : MODIFY;
    [OAOsmEditingViewController commitEntity:action entity:entity entityInfo:[editingUtil getEntityInfo:poiData.getEntity.getId] comment:comment shouldClose:closeChangeset editingUtil:editingUtil changedTags:action == MODIFY ? poiData.getChangedTags : nil callback:nil];
}


#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    if (viewController == _basicEditingController)
        return nil;
    else
        return _basicEditingController;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    if (viewController == _basicEditingController)
        return _advancedEditingController;
    else
        return nil;
}

#pragma mark - UIPageViewControllerDelegate

-(void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (pageViewController.viewControllers[0] == _basicEditingController)
        _segmentControl.selectedSegmentIndex = 0;
    else
       _segmentControl.selectedSegmentIndex = 1;
}

- (IBAction)onBackPressed:(id)sender {
    if ([_editPoiData hasChangesBeenMade])
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"osm_editing_lost_changes_title") message:OALocalizedString(@"osm_editing_lost_changes_descr") preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        }]];
        [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self.navigationController popViewControllerAnimated:YES];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
    else
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
