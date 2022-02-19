//
//  PXAlertView.m
//  PXAlertViewDemo
//
//  Created by Alex Jarvis on 25/09/2013.
//  Copyright (c) 2013 Panaxiom Ltd. All rights reserved.
//

#import "PXAlertView.h"
#import "PXAlertView+Customization.h"

@interface PXAlertViewStack : NSObject

@property (nonatomic) NSMutableArray *alertViews;

+ (PXAlertViewStack *)sharedInstance;

- (void)push:(PXAlertView *)alertView;
- (void)pop:(PXAlertView *)alertView;

@end

static const CGFloat AlertViewWidth = 270.0;
static const CGFloat AlertViewContentMargin = 15;
static const CGFloat AlertViewVerticalElementSpace = 10;
static const CGFloat AlertViewButtonHeight = 44;
static const CGFloat AlertViewLineLayerWidth = 0.5;
static const CGFloat AlertViewVerticalEdgeMinMargin = 25;
static const CGFloat AlertViewVerticalMargin = 20;


@interface PXAlertView ()

@property (nonatomic) BOOL buttonsShouldStack;
@property (nonatomic) UIWindow *mainWindow;
@property (nonatomic) UIWindow *alertWindow;
@property (nonatomic) UIView *backgroundView;
@property (nonatomic) UIView *alertView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIView *contentView;
@property (nonatomic) UIScrollView *messageScrollView;
@property (nonatomic) UIScrollView *buttonsScrollView;
@property (nonatomic) UILabel *messageLabel;
@property (nonatomic) UIButton *cancelButton;
@property (nonatomic) UIButton *otherButton;
@property (nonatomic) NSArray *buttons;
@property (nonatomic) CGFloat buttonsY;
@property (nonatomic) CALayer *verticalLine;
@property (nonatomic) CALayer *lastLine;
@property (nonatomic) UITapGestureRecognizer *tap;
@property (nonatomic, copy) void (^completion)(BOOL cancelled, NSInteger buttonIndex);

@end

@implementation PXAlertView

- (UIWindow *)windowWithLevel:(UIWindowLevel)windowLevel
{
    NSArray *windows = [[UIApplication sharedApplication] windows];
    for (UIWindow *window in windows) {
        if (window.windowLevel == windowLevel) {
            return window;
        }
    }
    return nil;
}

- (id)initWithTitle:(NSString *)title
            message:(NSString *)message
        cancelTitle:(NSString *)cancelTitle
         otherTitle:(NSString *)otherTitle
          otherDesc:(NSString *)otherDesc
         otherImage:(NSString *)otherImage
 buttonsShouldStack:(BOOL)shouldstack
        contentView:(UIView *)contentView
         completion:(PXAlertViewCompletionBlock)completion
{
    return [self initWithTitle:title
                       message:message
                   cancelTitle:cancelTitle
                   otherTitles:(otherTitle) ? @[ otherTitle ] : nil
                     otherDesc:(otherDesc) ? @[ otherDesc ] : nil
                   otherImages:(otherImage) ? @[ otherImage ] : nil
            buttonsShouldStack:(BOOL)shouldstack
                   contentView:contentView
                    completion:completion];
}

- (id)initWithTitle:(NSString *)title
            message:(NSString *)message
        cancelTitle:(NSString *)cancelTitle
        otherTitles:(NSArray *)otherTitles
          otherDesc:(NSArray *)otherDesc
        otherImages:(NSArray *)otherImages
 buttonsShouldStack:(BOOL)shouldstack
        contentView:(UIView *)contentView
         completion:(PXAlertViewCompletionBlock)completion
{
    self = [super init];
    if (self) {
        self.mainWindow = [self windowWithLevel:UIWindowLevelNormal];
        
        self.alertWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        self.alertWindow.windowLevel = UIWindowLevelNormal;
        self.alertWindow.backgroundColor = [UIColor clearColor];
        self.alertWindow.rootViewController = self;
        
        CGRect frame = [self frameForOrientation];
        self.view.frame = frame;
        
        self.backgroundView = [[UIView alloc] initWithFrame:frame];
        self.backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        self.backgroundView.alpha = 0;
        [self.view addSubview:self.backgroundView];
        
        self.alertView = [[UIView alloc] init];
        self.alertView.backgroundColor = [UIColor colorWithWhite:0.25 alpha:1];
        self.alertView.layer.cornerRadius = 3.0;
        self.alertView.layer.opacity = .95;
        self.alertView.clipsToBounds = YES;
        [self.view addSubview:self.alertView];
        
        if (!shouldstack && ((cancelTitle && otherTitles.count > 1) || (otherTitles.count > 2)))
            shouldstack = YES;
        
        CGFloat messageLabelY = 0.0;
        
        // Title
        if (title)
        {
            self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(AlertViewContentMargin,
                                                                        0.0,
                                                                        AlertViewWidth - AlertViewContentMargin*2,
                                                                        44)];
            self.titleLabel.text = [title uppercaseStringWithLocale:[NSLocale currentLocale]];
            self.titleLabel.backgroundColor = [UIColor clearColor];
            self.titleLabel.textColor = [UIColor whiteColor];
            if ([self.titleLabel isDirectionRTL])
                self.titleLabel.textAlignment = NSTextAlignmentRight;
            else
                self.titleLabel.textAlignment = NSTextAlignmentLeft;
            self.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightBold];
            self.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
            self.titleLabel.numberOfLines = 0;
            [self.alertView addSubview:self.titleLabel];
            
            messageLabelY = self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height;
            
            // Line
            CALayer *lineLayer = [self lineLayer];
            CGFloat lineY = messageLabelY - 2.0;
            lineLayer.frame = CGRectMake(0, lineY, AlertViewWidth, 2.0);
            lineLayer.backgroundColor = [UIColor colorWithRed:1.000f green:0.733f blue:0.012f alpha:1.00f].CGColor;
            [self.alertView.layer addSublayer:lineLayer];
            
        }
        
        
        // Optional Content View
        if (contentView)
        {
            self.contentView = contentView;
            self.contentView.frame = CGRectMake(0,
                                                messageLabelY,
                                                self.contentView.frame.size.width,
                                                self.contentView.frame.size.height);
            self.contentView.center = CGPointMake(AlertViewWidth/2, self.contentView.center.y);
            [self.alertView addSubview:self.contentView];
            messageLabelY += contentView.frame.size.height;
        }
        
        if (message)
        {
            messageLabelY += AlertViewVerticalElementSpace;
            
            // Message
            self.messageScrollView = [[UIScrollView alloc] initWithFrame:(CGRect) {
                AlertViewContentMargin,
                messageLabelY,
                AlertViewWidth - AlertViewContentMargin*2,
                44}];
            self.messageScrollView.scrollEnabled = YES;
            
            self.messageLabel = [[UILabel alloc] initWithFrame:(CGRect){0, 0,
                self.messageScrollView.frame.size}];
            self.messageLabel.text = message;
            self.messageLabel.backgroundColor = [UIColor clearColor];
            self.messageLabel.textColor = [UIColor whiteColor];
            self.messageLabel.textAlignment = NSTextAlignmentCenter;
            self.messageLabel.font = [UIFont systemFontOfSize:13.0];
            self.messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
            self.messageLabel.numberOfLines = 0;
            self.messageLabel.frame = [self adjustLabelFrameHeight:self.messageLabel];
            self.messageScrollView.contentSize = self.messageLabel.frame.size;
            
            [self.messageScrollView addSubview:self.messageLabel];
            [self.alertView addSubview:self.messageScrollView];
        }
        
        // Get total button height
        CGFloat totalBottomHeight = AlertViewLineLayerWidth;
        if (shouldstack)
        {
            if (cancelTitle)
                totalBottomHeight += AlertViewButtonHeight;

            if (otherTitles && [otherTitles count] > 0)
                totalBottomHeight += (AlertViewButtonHeight + AlertViewLineLayerWidth) * [otherTitles count];
        }
        else
        {
            totalBottomHeight += AlertViewButtonHeight;
        }
        
        CGFloat messageScrollViewHeight = 0.0;
        
        if (message)
        {
            messageScrollViewHeight = MIN(self.messageLabel.frame.size.height, self.alertWindow.frame.size.height - self.messageScrollView.frame.origin.y - totalBottomHeight - AlertViewVerticalEdgeMinMargin * 2);
            self.messageScrollView.frame = (CGRect) {
                self.messageScrollView.frame.origin,
                self.messageScrollView.frame.size.width,
                messageScrollViewHeight
            };
        }
        
        // Line
        CALayer *lineLayer = [self lineLayer];
        
        CGFloat lineY = messageLabelY;
        if (self.contentView || self.messageScrollView)
        {
            lineY = messageLabelY + messageScrollViewHeight + (self.messageScrollView ? AlertViewVerticalElementSpace : 0);
            
            lineLayer.frame = CGRectMake(0, lineY, AlertViewWidth, AlertViewLineLayerWidth);
            [self.alertView.layer addSublayer:lineLayer];
            self.lastLine = lineLayer;
            
            self.buttonsY = lineLayer.frame.origin.y + lineLayer.frame.size.height;
        }
        else
        {
            self.buttonsY = lineY;
        }
        
        if (!contentView && shouldstack && otherTitles && otherTitles.count > 0)
        {
            self.buttonsScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, self.buttonsY, AlertViewWidth,AlertViewButtonHeight * otherTitles.count)];
            [self.alertView addSubview:self.buttonsScrollView];
        }

        // Buttons
        self.buttonsShouldStack = shouldstack;
        
        if (shouldstack)
        {
            if (otherTitles && [otherTitles count] > 0)
            {
                for (int i = 0; i < otherTitles.count; i++)
                {
                    id otherTitle = otherTitles[i];
                    id desc = nil;
                    if (otherDesc.count > 0)
                        desc = otherDesc[i];
                    
                    NSParameterAssert([otherTitle isKindOfClass:[NSString class]]);
                    NSString *imageName;
                    if (i < otherImages.count)
                        imageName = otherImages[i];
                    [self addButtonWithTitle:(NSString *)otherTitle cmdButton:NO cancelButton:NO imageName:imageName desc:desc];
                }
            }
            
            if (cancelTitle)
                [self addButtonWithTitle:cancelTitle cmdButton:YES cancelButton:YES imageName:nil desc:nil];
        }
        else
        {
            if (cancelTitle)
                [self addButtonWithTitle:cancelTitle cmdButton:YES cancelButton:YES imageName:nil desc:nil];
            
            if (otherTitles && [otherTitles count] > 0)
            {
                for (int i = 0; i < otherTitles.count; i++)
                {
                    id otherTitle = otherTitles[i];
                    id desc = nil;
                    if (otherDesc.count > 0)
                        desc = otherDesc[i];

                    NSParameterAssert([otherTitle isKindOfClass:[NSString class]]);
                    NSString *imageName;
                    if (i < otherImages.count)
                        imageName = otherImages[i];
                    [self addButtonWithTitle:(NSString *)otherTitle cmdButton:YES cancelButton:NO imageName:imageName desc:desc];
                }
            }
        }
        
        self.alertView.bounds = CGRectMake(0, 0, AlertViewWidth, 150);
        
        if (completion)
            self.completion = completion;
        
        [self resizeViews];
        
        self.alertView.center = [self centerWithFrame:frame];
        
        [self setupGestures];
        
        [self setTapToDismissEnabled:YES];
        [self setAllButtonsTextColor:[UIColor darkGrayColor]];
        [self setTitleColor:[UIColor blackColor]];
        [self setMessageColor:[UIColor blackColor]];
        UIColor *defaultBackgroundColor = [UIColor colorWithRed:217/255.0 green:217/255.0 blue:217/255.0 alpha:1.0];
        [self setAllButtonsBackgroundColor:defaultBackgroundColor];
        [self setBackgroundColor:[UIColor whiteColor]];
        
        if ((self = [super init])) {
            NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
            [center addObserver:self selector:@selector(keyboardWillShown:) name:UIKeyboardWillShowNotification object:nil];
            [center addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        }
        return self;
    }
    return self;
}

- (void)keyboardWillShown:(NSNotification*)notification
{
    if(self.isVisible)
    {
        CGRect keyboardFrameBeginRect = [[[notification userInfo] valueForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
        if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8 && (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft || self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)) {
            keyboardFrameBeginRect = (CGRect){keyboardFrameBeginRect.origin.y, keyboardFrameBeginRect.origin.x, keyboardFrameBeginRect.size.height, keyboardFrameBeginRect.size.width};
        }
        CGRect interfaceFrame = [self frameForOrientation];
        
        if(interfaceFrame.size.height -  keyboardFrameBeginRect.size.height <= _alertView.frame.size.height + _alertView.frame.origin.y)
        {
            [UIView animateWithDuration:.35 delay:0 options:0x70000 animations:^(void)
             {
                 _alertView.frame = (CGRect){_alertView.frame.origin.x, interfaceFrame.size.height - keyboardFrameBeginRect.size.height - _alertView.frame.size.height - 20, _alertView.frame.size};
             } completion:nil];
        }
    }
}

- (void)keyboardWillHide:(NSNotification*)notification
{
    if(self.isVisible)
    {
        [UIView animateWithDuration:.35 delay:0 options:0x70000 animations:^(void)
         {
             _alertView.center = [self centerWithFrame:[self frameForOrientation]];
         } completion:nil];
    }
}

- (CGRect)frameForOrientation
{
    UIWindow *window = [[UIApplication sharedApplication].windows count] > 0 ? [[UIApplication sharedApplication].windows objectAtIndex:0] : nil;
    if (!window)
        window = [UIApplication sharedApplication].keyWindow;
    if([[window subviews] count] > 0)
    {
        return [[[window subviews] objectAtIndex:0] bounds];
    }
    return [[self windowWithLevel:UIWindowLevelNormal] bounds];
}

- (CGRect)adjustLabelFrameHeight:(UILabel *)label
{
    CGFloat height;
    
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        CGSize size = [label.text sizeWithFont:label.font
                             constrainedToSize:CGSizeMake(label.frame.size.width, FLT_MAX)
                                 lineBreakMode:NSLineBreakByWordWrapping];
        
        height = size.height;
#pragma clang diagnostic pop
    } else {
        NSStringDrawingContext *context = [[NSStringDrawingContext alloc] init];
        context.minimumScaleFactor = 1.0;
        CGRect bounds = [label.text boundingRectWithSize:CGSizeMake(label.frame.size.width, FLT_MAX)
                                                 options:NSStringDrawingUsesLineFragmentOrigin
                                              attributes:@{NSFontAttributeName:label.font}
                                                 context:context];
        height = bounds.size.height;
    }
    
    return CGRectMake(label.frame.origin.x, label.frame.origin.y, label.frame.size.width, height);
}

- (UIButton *)genericButton:(BOOL)cmdButton imageName:(NSString *)imageName
{
    UIImage *image;
    if (imageName)
        image = [[UIImage imageNamed:imageName] imageFlippedForRightToLeftLayoutDirection];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor clearColor];
    if (cmdButton)
        button.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightSemibold];
    else
        button.titleLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
    button.titleLabel.adjustsFontSizeToFitWidth = YES;
    button.titleEdgeInsets = UIEdgeInsetsMake(2, 2, 2, 2);
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor colorWithWhite:0.25 alpha:1] forState:UIControlStateHighlighted];
    
    if (image)
    {
        CGFloat leftInset;
        CGFloat rightInset;
        [button setImage:image forState:UIControlStateNormal];
        if ([button isDirectionRTL])
        {
            button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
            leftInset = 0;
            rightInset = 15;
        }
        else
        {
            button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            leftInset = 15;
            rightInset = 0;
        }
        button.contentEdgeInsets = (UIEdgeInsets) {0.0, leftInset, 0.0, rightInset};
        button.titleEdgeInsets = (UIEdgeInsets) {0.0, leftInset, 0.0, rightInset};
    }
    
    [button addTarget:self action:@selector(dismiss:) forControlEvents:UIControlEventTouchUpInside];
    [button addTarget:self action:@selector(setBackgroundColorForButton:) forControlEvents:UIControlEventTouchDown];
    [button addTarget:self action:@selector(setBackgroundColorForButton:) forControlEvents:UIControlEventTouchDragEnter];
    [button addTarget:self action:@selector(clearBackgroundColorForButton:) forControlEvents:UIControlEventTouchDragExit];
    return button;
}

- (CGPoint)centerWithFrame:(CGRect)frame
{
    return CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame) - [self statusBarOffset]);
}

- (CGFloat)statusBarOffset
{
    CGFloat statusBarOffset = 0;
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        statusBarOffset = 20;
    }
    return statusBarOffset;
}

- (void)setupGestures
{
    self.tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismiss:)];
    [self.tap setNumberOfTapsRequired:1];
    [self.backgroundView setUserInteractionEnabled:YES];
    [self.backgroundView setMultipleTouchEnabled:NO];
    [self.backgroundView addGestureRecognizer:self.tap];
}

- (void)resizeViews
{
    CGFloat totalHeight = 0;
    CGFloat maxHeight = [self getMaxAlertViewHeight];
    for (UIView *view in [self.alertView subviews])
    {
        if ([view class] != [UIButton class])
        {
            totalHeight += view.frame.size.height + (self.messageScrollView ? AlertViewVerticalElementSpace : 0.0);
        }
    }
    //totalHeight += (self.messageScrollView ? AlertViewVerticalElementSpace : 0.0);

    if (self.buttonsScrollView)
    {
        if (self.cancelButton)
            totalHeight += AlertViewButtonHeight;
            
        if (totalHeight > maxHeight)
        {
            CGFloat d = totalHeight - maxHeight;
            self.buttonsScrollView.contentSize = self.buttonsScrollView.bounds.size;
            CGRect f = self.buttonsScrollView.frame;
            f.size.height -= d;
            self.buttonsScrollView.frame = f;
            
            BOOL move = NO;
            for (UIView *view in [self.alertView subviews])
            {
                if (view == self.buttonsScrollView)
                {
                    move = YES;
                    continue;
                }
                if (move)
                    [self shiftVert:view dy:-d];
            }
            if (self.verticalLine)
                [self shiftVert:self.verticalLine dy:-d];
            if (self.lastLine)
                [self shiftVert:self.lastLine dy:-d];
            
            self.buttonsScrollView.scrollEnabled = YES;
            
        }
    }
    else if (self.buttons)
    {
        NSUInteger otherButtonsCount = [self.buttons count];
        if (self.buttonsShouldStack)
            totalHeight += AlertViewButtonHeight * otherButtonsCount;
        else
            totalHeight += AlertViewButtonHeight * (otherButtonsCount > 2 ? otherButtonsCount : 1);
    }
    
    if (self.contentView && totalHeight > maxHeight)
    {
        CGFloat d = totalHeight - maxHeight;
        CGRect f = self.contentView.frame;
        f.size.height -= d;
        self.contentView.frame = f;
        
        BOOL move = NO;
        for (UIView *view in [self.alertView subviews])
        {
            if (view == self.contentView)
            {
                move = YES;
                continue;
            }
            if (move)
                [self shiftVert:view dy:-d];
        }
        if (self.verticalLine)
            [self shiftVert:self.verticalLine dy:-d];
        if (self.lastLine)
            [self shiftVert:self.lastLine dy:-d];
    }
    
    self.alertView.frame = CGRectMake(self.alertView.frame.origin.x,
                                      self.alertView.frame.origin.y,
                                      self.alertView.frame.size.width,
                                      MIN(totalHeight, maxHeight));
}

- (void)shiftVert:(id)view dy:(CGFloat)dy
{
    if ([view isKindOfClass:[UIView class]])
    {
        UIView *v = (UIView *)view;
        CGRect f = v.frame;
        f.origin.y += dy;
        v.frame = f;
    }
    else if ([view isKindOfClass:[CALayer class]])
    {
        CALayer *l = (CALayer *)view;
        CGRect f = l.frame;
        f.origin.y += dy;
        l.frame = f;
    }
}

- (CGFloat) getMaxAlertViewHeight
{
    return self.alertWindow.frame.size.height - AlertViewVerticalMargin * 2;
}

- (void)setBackgroundColorForButton:(id)sender
{
    [sender setBackgroundColor:[UIColor colorWithRed:94/255.0 green:196/255.0 blue:221/255.0 alpha:1.0]];
}

- (void)clearBackgroundColorForButton:(id)sender
{
    [sender setBackgroundColor:[UIColor clearColor]];
}

- (void)show
{
    [[PXAlertViewStack sharedInstance] push:self];
}

- (void)showInternal
{
    [self.alertWindow addSubview:self.view];
    [self.alertWindow makeKeyAndVisible];
    self.visible = YES;
    [self showBackgroundView];
    [self showAlertAnimation];
}

- (void)showBackgroundView
{
    if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
        //self.mainWindow.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;
        //[self.mainWindow tintColorDidChange];
    }
    [UIView animateWithDuration:0.3 animations:^{
        self.backgroundView.alpha = 1;
    }];
}

- (void)hide
{
    [self.view removeFromSuperview];
}

- (void)dismiss:(id)sender
{
    [self dismiss:sender animated:YES];
}

- (void)dismiss:(id)sender animated:(BOOL)animated
{
    self.visible = NO;
    
    [UIView animateWithDuration:(animated ? 0.2 : 0) animations:^{
        self.alertView.alpha = 0;
        self.alertWindow.alpha = 0;
    } completion:^(BOOL finished) {
        if (self.completion) {
            BOOL cancelled = NO;
            if (sender == self.cancelButton || sender == self.tap) {
                cancelled = YES;
            }
            NSInteger buttonIndex = -1;
            if (self.buttons) {
                NSUInteger index = [self.buttons indexOfObject:sender];
                if (buttonIndex != NSNotFound) {
                    buttonIndex = index;
                }
            }
            self.completion(cancelled, buttonIndex);
        }
        
        if ([[[PXAlertViewStack sharedInstance] alertViews] count] == 1) {
            if (animated) {
                [self dismissAlertAnimation];
            }
            if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1) {
                //self.mainWindow.tintAdjustmentMode = UIViewTintAdjustmentModeAutomatic;
                //[self.mainWindow tintColorDidChange];
            }
            [UIView animateWithDuration:(animated ? 0.2 : 0) animations:^{
                self.backgroundView.alpha = 0;
                [self.alertWindow setHidden:YES];
                [self.alertWindow removeFromSuperview];
                self.alertWindow.rootViewController = nil;
                self.alertWindow = nil;
            } completion:^(BOOL finished) {
                [self.mainWindow makeKeyAndVisible];
            }];
        }
        
        [[PXAlertViewStack sharedInstance] pop:self];
    }];
}

- (void)showAlertAnimation
{
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    
    animation.values = @[[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.2, 1.2, 1)],
                         [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.05, 1.05, 1)],
                         [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1)]];
    animation.keyTimes = @[ @0, @0.5, @1 ];
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    animation.duration = .3;
    
    [self.alertView.layer addAnimation:animation forKey:@"showAlert"];
}

- (void)dismissAlertAnimation
{
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    
    animation.values = @[[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1)],
                         [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.95, 0.95, 1)],
                         [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.8, 0.8, 1)]];
    animation.keyTimes = @[ @0, @0.5, @1 ];
    animation.fillMode = kCAFillModeRemoved;
    animation.duration = .2;
    
    [self.alertView.layer addAnimation:animation forKey:@"dismissAlert"];
}

- (CALayer *)lineLayer
{
    CALayer *lineLayer = [CALayer layer];
    lineLayer.backgroundColor = [[UIColor colorWithWhite:0.50 alpha:0.3] CGColor];
    return lineLayer;
}

#pragma mark -
#pragma mark UIViewController

- (BOOL)prefersStatusBarHidden
{
    return [UIApplication sharedApplication].statusBarHidden;
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    CGRect frame = [self frameForOrientation];
    self.backgroundView.frame = frame;
    self.alertView.center = [self centerWithFrame:frame];
}

#pragma mark -
#pragma mark Public

+ (instancetype)showAlertWithTitle:(NSString *)title
{
    return [[self class] showAlertWithTitle:title message:nil cancelTitle:NSLocalizedString(@"OK", nil) completion:nil];
}

+ (instancetype)showAlertWithTitle:(NSString *)title
                           message:(NSString *)message
{
    return [[self class] showAlertWithTitle:title message:message cancelTitle:NSLocalizedString(@"OK", nil) completion:nil];
}

+ (instancetype)showAlertWithTitle:(NSString *)title
                           message:(NSString *)message
                        completion:(PXAlertViewCompletionBlock)completion
{
    return [[self class] showAlertWithTitle:title message:message cancelTitle:NSLocalizedString(@"OK", nil) completion:completion];
}

+ (instancetype)showAlertWithTitle:(NSString *)title
                           message:(NSString *)message
                       cancelTitle:(NSString *)cancelTitle
                        completion:(PXAlertViewCompletionBlock)completion
{
    PXAlertView *alertView = [[self alloc] initWithTitle:title
                                                 message:message
                                             cancelTitle:cancelTitle
                                              otherTitle:nil
                                               otherDesc:nil
                                              otherImage:nil
                                      buttonsShouldStack:NO
                                             contentView:nil
                                              completion:completion];
    [alertView show];
    return alertView;
}

+ (instancetype)showAlertWithTitle:(NSString *)title
                           message:(NSString *)message
                       cancelTitle:(NSString *)cancelTitle
                        otherTitle:(NSString *)otherTitle
                         otherDesc:(NSString *)otherDesc
                        otherImage:(NSString *)otherImage
                        completion:(PXAlertViewCompletionBlock)completion
{
    PXAlertView *alertView = [[self alloc] initWithTitle:title
                                                 message:message
                                             cancelTitle:cancelTitle
                                              otherTitle:otherTitle
                                               otherDesc:otherDesc
                                              otherImage:otherImage
                                      buttonsShouldStack:NO
                                             contentView:nil
                                              completion:completion];
    [alertView show];
    return alertView;
}

+ (instancetype)showAlertWithTitle:(NSString *)title
                           message:(NSString *)message
                       cancelTitle:(NSString *)cancelTitle
                        otherTitle:(NSString *)otherTitle
                         otherDesc:(NSString *)otherDesc
                        otherImage:(NSString *)otherImage
                buttonsShouldStack:(BOOL)shouldStack
                        completion:(PXAlertViewCompletionBlock)completion
{
    PXAlertView *alertView = [[self alloc] initWithTitle:title
                                                 message:message
                                             cancelTitle:cancelTitle
                                              otherTitle:otherTitle
                                               otherDesc:otherDesc
                                              otherImage:otherImage
                                      buttonsShouldStack:shouldStack
                                             contentView:nil
                                              completion:completion];
    [alertView show];
    return alertView;
}

+ (instancetype)showAlertWithTitle:(NSString *)title
                           message:(NSString *)message
                       cancelTitle:(NSString *)cancelTitle
                       otherTitles:(NSArray *)otherTitles
                         otherDesc:(NSArray *)otherDesc
                       otherImages:(NSArray *)otherImages
                        completion:(PXAlertViewCompletionBlock)completion
{
    PXAlertView *alertView = [[self alloc] initWithTitle:title
                                                 message:message
                                             cancelTitle:cancelTitle
                                             otherTitles:otherTitles
                                               otherDesc:otherDesc
                                             otherImages:otherImages
                                      buttonsShouldStack:YES
                                             contentView:nil
                                              completion:completion];
    [alertView show];
    return alertView;
}

+ (instancetype)showAlertWithTitle:(NSString *)title
                           message:(NSString *)message
                       cancelTitle:(NSString *)cancelTitle
                        otherTitle:(NSString *)otherTitle
                         otherDesc:(NSString *)otherDesc
                        otherImage:(NSString *)otherImage
                       contentView:(UIView *)view
                        completion:(PXAlertViewCompletionBlock)completion
{
    PXAlertView *alertView = [[self alloc] initWithTitle:title
                                                 message:message
                                             cancelTitle:cancelTitle
                                              otherTitle:otherTitle
                                               otherDesc:otherDesc
                                              otherImage:otherImage
                                      buttonsShouldStack:NO
                                             contentView:view
                                              completion:completion];
    [alertView show];
    return alertView;
}

+ (instancetype)showAlertWithTitle:(NSString *)title
                           message:(NSString *)message
                       cancelTitle:(NSString *)cancelTitle
                        otherTitle:(NSString *)otherTitle
                         otherDesc:(NSString *)otherDesc
                        otherImage:(NSString *)otherImage
                buttonsShouldStack:(BOOL)shouldStack
                       contentView:(UIView *)view
                        completion:(PXAlertViewCompletionBlock)completion
{
    PXAlertView *alertView = [[self alloc] initWithTitle:title
                                                 message:message
                                             cancelTitle:cancelTitle
                                              otherTitle:otherTitle
                                               otherDesc:otherDesc
                                              otherImage:otherImage
                                      buttonsShouldStack:shouldStack
                                             contentView:view
                                              completion:completion];
    [alertView show];
    return alertView;
}


+ (instancetype)showAlertWithTitle:(NSString *)title
                           message:(NSString *)message
                       cancelTitle:(NSString *)cancelTitle
                       otherTitles:(NSArray *)otherTitles
                         otherDesc:(NSArray *)otherDesc
                       otherImages:(NSArray *)otherImages
                       contentView:(UIView *)view
                        completion:(PXAlertViewCompletionBlock)completion
{
    PXAlertView *alertView = [[self alloc] initWithTitle:title
                                                 message:message
                                             cancelTitle:cancelTitle
                                             otherTitles:otherTitles
                                               otherDesc:otherDesc
                                             otherImages:otherImages
                                      buttonsShouldStack:NO
                                             contentView:view
                                              completion:completion];
    [alertView show];
    return alertView;
}

- (NSInteger)addButtonWithTitle:(NSString *)title cmdButton:(BOOL)cmdButton cancelButton:(BOOL)cancelButton imageName:(NSString *)imageName desc:(NSString *)desc
{
    UIButton *button = [self genericButton:cmdButton imageName:imageName];
    if (cmdButton)
        [button setTitle:[title uppercaseStringWithLocale:[NSLocale currentLocale]] forState:UIControlStateNormal];
    else
        [button setTitle:title forState:UIControlStateNormal];
    
    UIView *container = self.buttonsScrollView && !cancelButton ? self.buttonsScrollView : self.alertView;
    
    if (cancelButton)
        self.cancelButton = button;
    
    if (self.buttonsShouldStack)
    {
        CGRect frame = CGRectMake(0, self.buttonsY * (self.buttons.count + 1), AlertViewWidth, AlertViewButtonHeight);
        if (self.buttonsScrollView)
        {
            if (cancelButton)
                frame = CGRectMake(0, self.buttonsScrollView.frame.origin.y + self.buttonsScrollView.frame.size.height, AlertViewWidth, AlertViewButtonHeight);
            else
                frame = CGRectMake(0, AlertViewButtonHeight * self.buttons.count, AlertViewWidth, AlertViewButtonHeight);
        }
        else
        {
            frame = CGRectMake(0, self.buttonsY * (self.buttons.count + 1), AlertViewWidth, AlertViewButtonHeight);
        }
        
        button.frame = frame;
        
        if (self.buttons.count > 0)
        {
            CALayer *lineLayer = [self lineLayer];
            lineLayer.frame = CGRectMake(0, frame.origin.y - AlertViewLineLayerWidth, AlertViewWidth, AlertViewLineLayerWidth);
            [container.layer addSublayer:lineLayer];
            self.lastLine = lineLayer;
        }
    }
    else if (self.buttons)
    {
        UIButton *lastButton = (UIButton *)[self.buttons lastObject];
        
        self.verticalLine = [self lineLayer];
        self.verticalLine.frame = CGRectMake(AlertViewWidth/2, self.buttonsY, AlertViewLineLayerWidth, AlertViewButtonHeight);
        [container.layer addSublayer:self.verticalLine];
        
        lastButton.frame = CGRectMake(0, self.buttonsY, AlertViewWidth/2, AlertViewButtonHeight);
        button.frame = CGRectMake(AlertViewWidth/2, self.buttonsY, AlertViewWidth/2, AlertViewButtonHeight);
    }
    else
    {
        CGRect frame = CGRectMake(0, self.buttonsY, AlertViewWidth, AlertViewButtonHeight);
        button.frame = frame;
    }
    
    [container addSubview:button];
    
    if (desc)
    {
        CGRect f = button.bounds;
        f.size.width -= 10.0;
        UILabel *descLabel = [[UILabel alloc] initWithFrame:f];
        descLabel.userInteractionEnabled = NO;
        descLabel.backgroundColor = [UIColor clearColor];
        descLabel.font = [UIFont systemFontOfSize:15.0];
        descLabel.textColor = [UIColor grayColor];
        descLabel.textAlignment = NSTextAlignmentRight;
        descLabel.text = desc;
        [button addSubview:descLabel];
    }
    
    self.buttons = (self.buttons) ? [self.buttons arrayByAddingObject:button] : @[ button ];
    return [self.buttons count] - 1;
}

- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated
{
    if (buttonIndex >= 0 && buttonIndex < [self.buttons count]) {
        [self dismiss:self.buttons[buttonIndex] animated:animated];
    }
}

- (NSInteger) getCancelButtonIndex
{
    for (int i = 0; i < self.buttons.count; i++)
    {
        UIButton *btn = self.buttons[i];
        if (btn == self.cancelButton)
            return i;
    }
    return -1;
}

- (void)setTapToDismissEnabled:(BOOL)enabled
{
    self.tap.enabled = enabled;
}

@end

@implementation PXAlertViewStack

+ (instancetype)sharedInstance
{
    static PXAlertViewStack *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[PXAlertViewStack alloc] init];
        _sharedInstance.alertViews = [NSMutableArray array];
    });
    
    return _sharedInstance;
}

- (void)push:(PXAlertView *)alertView
{
    for (PXAlertView *av in self.alertViews) {
        if (av != alertView) {
            [av hide];
        }
        else {
            return;
        }
    }
    [self.alertViews addObject:alertView];
    [alertView showInternal];
}

- (void)pop:(PXAlertView *)alertView
{
    [alertView hide];
    [self.alertViews removeObject:alertView];
    PXAlertView *last = [self.alertViews lastObject];
    if (last && !last.view.superview) {
        [last showInternal];
    }
}

@end
