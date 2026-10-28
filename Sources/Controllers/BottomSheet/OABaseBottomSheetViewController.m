//
//  OABaseBottomSheetViewController.m
//  OsmAnd
//
//  Created by Paul on 28.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseBottomSheetViewController.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

#define kOABottomSheetWidth 320.0
#define kButtonsHeightWithoutBottomPadding 51.0
#define kButtonsNoSafeAreaBottomPadding 9.0

typedef NS_ENUM(NSInteger, EOAScrollableMenuState)
{
    EOAScrollableMenuStateInitial = 0,
    EOAScrollableMenuStateFullScreen
};

@interface OABaseBottomSheetViewController () <UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIView *contentContainer;
@property (weak, nonatomic) IBOutlet UIView *statusBarBackgroundView;
@property (weak, nonatomic) IBOutlet UIView *sliderView;

@end

@implementation OABaseBottomSheetViewController
{
    UIPanGestureRecognizer *_panGesture;
    EOAScrollableMenuState _currentState;
    CGFloat _initialTouchPoint;
    BOOL _isDragging;
    BOOL _isHiding;
    CGSize _lastLayoutSize;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:nibNameOrNil == nil ? @"OABaseBottomSheetViewController" : nibNameOrNil bundle:nil];
}

- (void) presentInViewController:(UIViewController *)viewController
{
    [self presentInViewController:viewController animated:NO];
}

- (void) presentInViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [viewController presentViewController:self animated:animated completion:nil];
}

- (void) generateData
{
    
}

- (void) commonInit
{

}

- (void) applyLocalization
{
    
}

- (BOOL) usesCenteredLayout
{
    return ([self.view isLandscapeInScene] || OAUtilities.isIPad) && ![self.view isWindowedInScene];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.separatorColor = [SeparatorAppearance color];
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onDragged:)];
    _panGesture.maximumNumberOfTouches = 1;
    _panGesture.minimumNumberOfTouches = 1;
    _panGesture.delaysTouchesBegan = NO;
    _panGesture.delaysTouchesEnded = NO;
    _panGesture.delegate = self;
    [self.bottomSheetView addGestureRecognizer:_panGesture];
    
    _sliderView.layer.cornerRadius = 2.;
    
    [self.bottomSheetView.layer setShadowColor:[UIColor colorNamed:ACColorNameTextColorPrimary].CGColor];
    [self.bottomSheetView.layer setShadowOpacity:0.3];
    [self.bottomSheetView.layer setShadowRadius:3.0];
    [self.bottomSheetView.layer setShadowOffset:CGSizeMake(0.0, 0.0)];
    [self.bottomSheetView.layer setCornerRadius:12.];
    
    self.leftButton.layer.cornerRadius = 9.;
    self.rightButton.layer.cornerRadius = 9.;
    
    self.leftButton.titleLabel.adjustsFontForContentSizeCategory = YES;
    self.leftButton.titleLabel.font = [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];

    self.rightButton.titleLabel.adjustsFontForContentSizeCategory = YES;
    self.rightButton.titleLabel.font = [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];

    [self.closeButton setImage:[UIImage imageNamed:ACImageNameIcCustomClose] forState:UIControlStateNormal];
    self.closeButton.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
    
    _currentState = EOAScrollableMenuStateInitial;
    _isFullScreenAvailable = YES;
    
    [self applyLocalization];
    [self layoutSubviews];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self show:self.animateShow];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    CGSize size = self.view.bounds.size;
    if (!CGSizeEqualToSize(size, _lastLayoutSize))
    {
        _lastLayoutSize = size;
        [self layoutSubviews];
    }
}

- (BOOL) animateShow
{
    return YES;
}

- (void) setHeaderViewVisibility:(BOOL)hidden
{
    self.headerView.hidden = hidden;
    self.headerViewCollapsedHeight.constant = hidden ? 0. : 57.;
    [self.view setNeedsUpdateConstraints];
    [self.view updateConstraintsIfNeeded];
}

- (CGFloat)initialHeight
{
    return [self.view sceneLayoutHeight] - [self.view sceneLayoutHeight] / 4;
}

- (CGFloat) buttonsViewHeight
{
    CGFloat bottomPadding = [self.view sceneBottomInset];
    bottomPadding = bottomPadding == 0 ? kButtonsNoSafeAreaBottomPadding : bottomPadding;
    return kButtonsHeightWithoutBottomPadding + bottomPadding;
}

- (CGFloat) getViewHeight
{
    switch (_currentState) {
        case EOAScrollableMenuStateInitial:
            return self.initialHeight;
        case EOAScrollableMenuStateFullScreen:
            return [self.view sceneLayoutHeight] - self.view.window.safeAreaInsets.top;
        default:
            return 0.0;
    }
}

- (CGFloat) getLandscapeHeight
{
    return OAUtilities.isIPad ? [self getViewHeight] : [self.view sceneLayoutHeight];
}

- (void) adjustFrame
{
    CGRect f = _bottomSheetView.frame;
    if ([self usesCenteredLayout])
    {
        f.size.height = [self getLandscapeHeight];
        f.size.width = OAUtilities.isIPad ? ([self.view sceneLayoutWidth] / 2) : kOABottomSheetWidth;
        f.origin = CGPointMake(([self.view sceneLayoutWidth] - f.size.width) / 2, [self.view sceneLayoutHeight] - f.size.height);
        
        CGRect buttonsFrame = _buttonsView.frame;
        buttonsFrame.origin.y = f.size.height - self.buttonsViewHeight;
        buttonsFrame.size.height = self.buttonsViewHeight;
        buttonsFrame.size.width = f.size.width;
        _buttonsView.frame = buttonsFrame;
        
        CGRect contentFrame = _contentContainer.frame;
        contentFrame.size.height = f.size.height - buttonsFrame.size.height;
        contentFrame.origin = CGPointZero;
        _contentContainer.frame = contentFrame;
    }
    else
    {
        f.size.height = [self getViewHeight];
        f.size.width = [self.view sceneLayoutWidth];
        f.origin = CGPointMake(0, [self.view sceneLayoutHeight] - f.size.height);
        
        CGRect buttonsFrame = _buttonsView.frame;
        buttonsFrame.size.height = self.buttonsViewHeight;
        buttonsFrame.size.width = f.size.width;
        buttonsFrame.origin.y = f.size.height - buttonsFrame.size.height;
        _buttonsView.frame = buttonsFrame;
        
        CGRect contentFrame = _contentContainer.frame;
        contentFrame.size.height = f.size.height - buttonsFrame.size.height;
        contentFrame.origin = CGPointZero;
        _contentContainer.frame = contentFrame;
    }
    _bottomSheetView.frame = f;
}

- (void) goFullScreen
{
    _currentState = EOAScrollableMenuStateFullScreen;
}

- (void) goMinimized
{
    _currentState = EOAScrollableMenuStateInitial;
}

- (void) applyCornerRadius:(UIView *)view
{
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect: view.bounds byRoundingCorners: UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii: CGSizeMake(12., 12.)].CGPath;
    view.layer.mask = maskLayer;
}

- (UIColor *)getBackgroundColor
{
    return [[UIColor colorNamed:ACColorNameTextColorPrimary] colorWithAlphaComponent:0.2];
}

- (void) show:(BOOL)animated
{
    [_tableView setContentOffset:CGPointZero];
    _isHiding = NO;
    _currentState = EOAScrollableMenuStateInitial;
    [self generateData];
    [self adjustFrame];
    [self.tableView reloadData];
    if (animated)
    {
        CGRect frame = _bottomSheetView.frame;
        if ([self usesCenteredLayout])
        {
            frame.origin.x = ([self.view sceneLayoutWidth] - frame.size.width) / 2;
            frame.size.width = OAUtilities.isIPad ? ([self.view sceneLayoutWidth] / 2) : kOABottomSheetWidth;
        }
        else
        {
            frame.origin.x = 0.0;
            frame.size.width = [self.view sceneLayoutWidth];
        }
        frame.origin.y = [self.view sceneLayoutHeight] + 10;
        _bottomSheetView.frame = frame;
        frame.origin.y = [self.view sceneLayoutHeight] - _bottomSheetView.bounds.size.height;
        [UIView animateWithDuration:.3 animations:^{
            _bottomSheetView.frame = frame;
            self.view.backgroundColor = [self getBackgroundColor];
        } completion:^(BOOL finished) {
            if (finished)
                [self layoutSubviews];
        }];
    }
    else
    {
        CGRect frame = _bottomSheetView.frame;
        frame.origin.y = [self.view sceneLayoutHeight] - _bottomSheetView.bounds.size.height;
        _bottomSheetView.frame = frame;
    }
}

- (void) hide:(BOOL)animated completion:(void (^ __nullable)(void))completion
{
    _isHiding = YES;
    
    CGRect frame = _bottomSheetView.frame;
    frame.origin.y = [self.view sceneLayoutHeight] + 10.0;
    
    if (animated)
    {
        [UIView animateWithDuration:0.3 animations:^{
            self.view.backgroundColor = UIColor.clearColor;
            _bottomSheetView.frame = frame;
        } completion:^(BOOL finished) {
            [self dismissViewControllerAnimated:NO completion:completion];
        }];
    }
    else
    {
        _bottomSheetView.frame = frame;
        [self dismissViewControllerAnimated:YES completion:completion];
    }
}

- (void) hide:(BOOL)animated
{
    [self hide:animated completion:nil];
}

- (void) hideSliderView
{
    [self.sliderView removeFromSuperview];
}

- (CGFloat) heightForLabel:(NSString *)text
{
    UIFont *labelFont = [UIFont scaledSystemFontOfSize: 15.0];
    CGFloat textWidth = _bottomSheetView.bounds.size.width - 32;
    return [OAUtilities heightForHeaderViewText:text width:textWidth font:labelFont lineSpacing:6.0];
}

- (void) layoutSubviews
{
    if (_isHiding || _isDragging)
        return;
    [self adjustFrame];

    CGRect contentFrame = _contentContainer.frame;
    contentFrame.size.width = _bottomSheetView.bounds.size.width;
    contentFrame.origin.y = CGRectGetMaxY(_statusBarBackgroundView.frame);
    contentFrame.size.height -= contentFrame.origin.y;
    _contentContainer.frame = contentFrame;
    
    [self applyCornerRadius:self.headerView];
    [self applyCornerRadius:self.contentContainer];
}

- (BOOL) isDraggingUpAvailable
{
    return YES;  // override
}

- (void) onRightButtonPressed
{
    [self hide:YES];
}

- (void) onBottomSheetDismissed
{
    // Override
}

- (IBAction)rightButtonPressed:(id)sender
{
    [self onRightButtonPressed];
}

- (IBAction)leftButtonPressed:(id)sender
{
    [self hide:YES];
    [self onBottomSheetDismissed];
}

- (IBAction)closeButtonPressed:(id)sender
{
    [self hide:YES];
    [self onBottomSheetDismissed];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self layoutSubviews];
    } completion:nil];
}

#pragma mark - UIPanGestureRecognizer

- (CGPoint) calculateInitialPoint
{
    return CGPointMake(0., [self.view sceneLayoutHeight] - [self getViewHeight]);
}

- (void) onDragged:(UIPanGestureRecognizer *)recognizer
{
    BOOL isDraggedUp = [recognizer translationInView:self.view].y < 0;
    if (!self.isDraggingUpAvailable && isDraggedUp)
        return;
    
    CGFloat velocity = [recognizer velocityInView:self.view].y;
    BOOL fastUpSlide = velocity < -1000.;
    BOOL fastDownSlide = velocity > 1500.;
    CGPoint touchPoint = [recognizer locationInView:self.view];
    CGPoint initialPoint = [self calculateInitialPoint];
    
    CGFloat fullScreenAnchor = [self.view sceneStatusBarHeight] + 80.;
    
    switch (recognizer.state)
    {
        case UIGestureRecognizerStateBegan:
            _isDragging = YES;
            _initialTouchPoint = [recognizer locationInView:_bottomSheetView].y;
        case UIGestureRecognizerStateChanged:
        {
            if (touchPoint.y <= self.tableView.frame.origin.y) 
                return;
            
            CGFloat newY = touchPoint.y - _initialTouchPoint;
            if (_bottomSheetView.frame.origin.y > [self.view sceneStatusBarHeight]
                || (_initialTouchPoint < _tableView.frame.origin.y && _tableView.contentOffset.y > 0))
            {
                [_tableView setContentOffset:CGPointZero];
            }
            
            if (newY <= [self.view sceneStatusBarHeight] || _tableView.contentOffset.y > 0)
            {
                newY = [self.view sceneStatusBarHeight];
                if (_tableView.contentOffset.y > 0)
                    _initialTouchPoint = [recognizer locationInView:_bottomSheetView].y;
            }
            else if ([self.view sceneLayoutHeight] - newY < _buttonsView.frame.size.height)
            {
                return;
            }
            
            CGRect frame = _bottomSheetView.frame;
            frame.origin.y = newY < [self.view sceneStatusBarHeight] ? [self.view sceneStatusBarHeight] : newY;
            frame.size.height = [self.view sceneLayoutHeight] - newY;
            _bottomSheetView.frame = frame;
            
            CGRect buttonsFrame = _buttonsView.frame;
            buttonsFrame.origin.y = frame.size.height - buttonsFrame.size.height;
            _buttonsView.frame = buttonsFrame;
            
            CGRect contentFrame = _contentContainer.frame;
            contentFrame.size.width = _bottomSheetView.bounds.size.width;
            contentFrame.origin.y = CGRectGetMaxY(_statusBarBackgroundView.frame);
            contentFrame.size.height = frame.size.height - buttonsFrame.size.height - contentFrame.origin.y;
            _contentContainer.frame = contentFrame;
            
            [self applyCornerRadius:self.headerView];
            [self applyCornerRadius:self.contentContainer];
            return;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        {
            _isDragging = NO;
            CGFloat newY = touchPoint.y - _initialTouchPoint;
            if ((newY - initialPoint.y > 180 || fastDownSlide) && _currentState == EOAScrollableMenuStateInitial)
            {
                [self onBottomSheetDismissed];
                [self hide:YES];
                break;
            }
            else if (newY > [self.view sceneLayoutHeight] / 4 + _buttonsView.frame.size.height + _tableView.frame.origin.y && !fastUpSlide)
            {
                _currentState = EOAScrollableMenuStateInitial;
            }
            else if (_isFullScreenAvailable && (newY < fullScreenAnchor || fastUpSlide))
            {
                _currentState = EOAScrollableMenuStateFullScreen;
            }
            else
            {
                _currentState = EOAScrollableMenuStateInitial;
            }
            [UIView animateWithDuration: 0.2 animations:^{
                [self layoutSubviews];
            }];
        }
        default:
        {
            break;
        }
    }
}

- (BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

@end
