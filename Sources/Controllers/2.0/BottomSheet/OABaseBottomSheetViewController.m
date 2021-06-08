//
//  OABaseBottomSheetViewController.m
//  OsmAnd
//
//  Created by Paul on 28.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseBottomSheetViewController.h"
#import "OAColors.h"

#define kOABottomSheetWidth 320.0
#define kOABottomSheetWidthIPad (DeviceScreenWidth / 2)
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
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *headerViewCollapsedHeight;

@end

@implementation OABaseBottomSheetViewController
{
    UIPanGestureRecognizer *_panGesture;
    EOAScrollableMenuState _currentState;
    CGFloat _initialTouchPoint;
    BOOL _isDragging;
    BOOL _isHiding;
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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onDragged:)];
    _panGesture.maximumNumberOfTouches = 1;
    _panGesture.minimumNumberOfTouches = 1;
    _panGesture.delaysTouchesBegan = NO;
    _panGesture.delaysTouchesEnded = NO;
    _panGesture.delegate = self;
    [self.bottomSheetView addGestureRecognizer:_panGesture];
    
    _sliderView.layer.cornerRadius = 2.;
    
    [self.bottomSheetView.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.bottomSheetView.layer setShadowOpacity:0.3];
    [self.bottomSheetView.layer setShadowRadius:3.0];
    [self.bottomSheetView.layer setShadowOffset:CGSizeMake(0.0, 0.0)];
    [self.bottomSheetView.layer setCornerRadius:12.];
    
    self.leftButton.layer.cornerRadius = 9.;
    self.rightButton.layer.cornerRadius = 9.;
    
    [self.closeButton setImage:[UIImage templateImageNamed:@"ic_custom_close"] forState:UIControlStateNormal];
    self.closeButton.tintColor = UIColorFromRGB(color_primary_purple);
    
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

- (BOOL) animateShow
{
    return YES;
}

- (void) setHeaderViewVisibility:(BOOL)hidden
{
    self.headerView.hidden = hidden;
    self.headerViewCollapsedHeight.active = !hidden;
    [self.contentContainer setNeedsLayout];
    [self.contentContainer layoutIfNeeded];
}

- (CGFloat)initialHeight
{
    return DeviceScreenHeight - DeviceScreenHeight / 4;
}

- (CGFloat) buttonsViewHeight
{
    CGFloat bottomPadding = [OAUtilities getBottomMargin];
    bottomPadding = bottomPadding == 0 ? kButtonsNoSafeAreaBottomPadding : bottomPadding;
    return kButtonsHeightWithoutBottomPadding + bottomPadding;
}

- (CGFloat) getViewHeight
{
    switch (_currentState) {
        case EOAScrollableMenuStateInitial:
            return self.initialHeight;
        case EOAScrollableMenuStateFullScreen:
            return DeviceScreenHeight - OAUtilities.getTopMargin;
        default:
            return 0.0;
    }
}

- (CGFloat) getLandscapeHeight
{
    return OAUtilities.isIPad ? [self getViewHeight] : DeviceScreenHeight;
}

- (void) adjustFrame
{
    CGRect f = _bottomSheetView.frame;
    CGFloat bottomMargin = [OAUtilities getBottomMargin];
    if (OAUtilities.isLandscapeIpadAware)
    {
        f.size.height = [self getLandscapeHeight];
        f.size.width = OAUtilities.isIPad ? kOABottomSheetWidthIPad : kOABottomSheetWidth;
        f.origin = CGPointMake(DeviceScreenWidth/2 - f.size.width / 2, DeviceScreenHeight - f.size.height);
        
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
        f.size.width = OAUtilities.isIPad && !OAUtilities.isWindowed ? kOABottomSheetWidthIPad : DeviceScreenWidth;
        f.origin = CGPointMake(0, DeviceScreenHeight - f.size.height);
        
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
    return [UIColor.blackColor colorWithAlphaComponent:0.2];
}

- (void) show:(BOOL)animated
{
    [_tableView setContentOffset:CGPointZero];
    _isHiding = NO;
    _currentState = EOAScrollableMenuStateInitial;
    [_tableView setScrollEnabled:_currentState == EOAScrollableMenuStateFullScreen];
    [self generateData];
    [self adjustFrame];
    [self.tableView reloadData];
    if (animated)
    {
        CGRect frame = _bottomSheetView.frame;
        if (OAUtilities.isLandscapeIpadAware)
        {
            frame.origin.x = DeviceScreenWidth/2 - frame.size.width / 2;
            frame.size.width = OAUtilities.isIPad ? kOABottomSheetWidthIPad : kOABottomSheetWidth;
        }
        else
        {
            frame.origin.x = 0.0;
            frame.size.width = DeviceScreenWidth;
        }
        frame.origin.y = DeviceScreenHeight + 10;
        _bottomSheetView.frame = frame;
        frame.origin.y = DeviceScreenHeight - _bottomSheetView.bounds.size.height;
        [UIView animateWithDuration:.3 animations:^{
            _bottomSheetView.frame = frame;
            self.view.backgroundColor = [self getBackgroundColor];
        }];
    }
    else
    {
        CGRect frame = _bottomSheetView.frame;
        if (OAUtilities.isLandscape)
            frame.origin.y = 0.0;
        else
            frame.origin.y = DeviceScreenHeight - _bottomSheetView.bounds.size.height;
        _bottomSheetView.frame = frame;
    }
}

- (void) hide:(BOOL)animated
{
    _isHiding = YES;
    
    CGRect frame = _bottomSheetView.frame;
    frame.origin.y = DeviceScreenHeight + 10.0;
    
    if (animated)
    {
        [UIView animateWithDuration:0.3 animations:^{
            self.view.backgroundColor = UIColor.clearColor;
            _bottomSheetView.frame = frame;
        } completion:^(BOOL finished) {
            [self dismissViewControllerAnimated:NO completion:nil];
        }];
    }
    else
    {
        _bottomSheetView.frame = frame;
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (CGFloat) heightForLabel:(NSString *)text
{
    UIFont *labelFont = [UIFont systemFontOfSize: 15.0];
    CGFloat textWidth = _bottomSheetView.bounds.size.width - 32;
    return [OAUtilities heightForHeaderViewText:text width:textWidth font:labelFont lineSpacing:6.0];
}

- (void) layoutSubviews
{
    if (_isHiding || _isDragging)
        return;
    [self adjustFrame];

    [_tableView setScrollEnabled:_currentState == EOAScrollableMenuStateFullScreen];

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
    return CGPointMake(0., DeviceScreenHeight - [self getViewHeight]);
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
    
    CGFloat fullScreenAnchor = OAUtilities.getStatusBarHeight + 80.;
    
    switch (recognizer.state)
    {
        case UIGestureRecognizerStateBegan:
            _isDragging = YES;
            _initialTouchPoint = [recognizer locationInView:_bottomSheetView].y;
        case UIGestureRecognizerStateChanged:
        {
            CGFloat newY = touchPoint.y - _initialTouchPoint;
            if (_bottomSheetView.frame.origin.y > OAUtilities.getStatusBarHeight
                || (_initialTouchPoint < _tableView.frame.origin.y && _tableView.contentOffset.y > 0))
            {
                [_tableView setContentOffset:CGPointZero];
            }
            
            if (newY <= OAUtilities.getStatusBarHeight || _tableView.contentOffset.y > 0)
            {
                newY = OAUtilities.getStatusBarHeight;
                if (_tableView.contentOffset.y > 0)
                    _initialTouchPoint = [recognizer locationInView:_bottomSheetView].y;
            }
            else if (DeviceScreenHeight - newY < _buttonsView.frame.size.height)
            {
                return;
            }
            
            CGRect frame = _bottomSheetView.frame;
            frame.origin.y = newY < OAUtilities.getStatusBarHeight ? OAUtilities.getStatusBarHeight : newY;
            frame.size.height = DeviceScreenHeight - newY;
            _bottomSheetView.frame = frame;
            
//            _statusBarBackgroundView.frame = newY == 0 ? CGRectMake(0., 0., DeviceScreenWidth, OAUtilities.getStatusBarHeight) : CGRectZero;
            
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
            else if (newY > DeviceScreenHeight - (DeviceScreenHeight - DeviceScreenHeight / 4) + _buttonsView.frame.size.height + _tableView.frame.origin.y && !fastUpSlide)
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
