//
//  OASubscriptionCancelViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 27/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASubscriptionCancelViewController.h"
#import "OAUtilities.h"

#include "Localization.h"

#define textMarginVertical 5.0

@interface OASubscriptionCancelViewController ()
@property (weak, nonatomic) IBOutlet UIButton *subscribeButton;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionView;
@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation OASubscriptionCancelViewController

- (instancetype) init
{
    self = [[OASubscriptionCancelViewController alloc] initWithNibName:@"OASubscriptionCancelViewController" bundle:nil];
    if (self)
    {
        self.view.frame = [UIScreen mainScreen].applicationFrame;
    }
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [[OASubscriptionCancelViewController alloc] initWithNibName:@"OASubscriptionCancelViewController" bundle:nil];
    if (self)
    {
        self.view.frame = [UIScreen mainScreen].applicationFrame;
    }
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
}

- (void)applyLocalization
{
    _titleView.text = OALocalizedString(@"osmand_live_subscription_canceled");
    _descriptionView.text = OALocalizedString(@"osmand_live_cancel_descr");
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL) prefersStatusBarHidden
{
    return YES;
}

- (void) viewWillLayoutSubviews
{
    
    CGFloat w = self.view.frame.size.width;
    if (@available(iOS 11.0, *))
    {
        w -= self.scrollView.safeAreaInsets.left + self.scrollView.safeAreaInsets.right;
        self.scrollView.contentInset = UIEdgeInsetsMake(0, self.scrollView.safeAreaInsets.left, 0, self.scrollView.safeAreaInsets.right);
    }
    
    CGFloat descrHeight = [self.class getDescrViewHeightWithWidth:w text:_descriptionView.text];
    CGFloat titleHeight = [self.class getTitleViewHeightWithWidth:_titleView.frame.size.width text:_titleView.text];
    
    CGFloat topMargin = [OAUtilities getTopMargin];
    CGFloat bottomMargin = [OAUtilities getBottomMargin];
    CGFloat sideMargin = [OAUtilities getLeftMargin];
    
    
    CGRect closeButtonFrame = _closeButton.frame;
    closeButtonFrame.origin.x = 8.0 + sideMargin;
    closeButtonFrame.origin.y = [OAUtilities getStatusBarHeight];
    _closeButton.frame = closeButtonFrame;
    _closeButton.layer.cornerRadius = 5;
    
    CGRect subscribeFrame = _subscribeButton.frame;
    _subscribeButton.frame = subscribeFrame;
    
    CGRect titleFrame = _titleView.frame;
    titleFrame.size.height = titleHeight;
    _titleView.frame = titleFrame;
    
    CGRect descrFrame = _descriptionView.frame;
    descrFrame.size.height = descrHeight;
    _descriptionView.frame = descrFrame;
    
    CGRect frame = CGRectMake(0.0, closeButtonFrame.origin.y + closeButtonFrame.size.height, w, DeviceScreenHeight - closeButtonFrame.size.height - subscribeFrame.size.height);
    _scrollView.frame = frame;

    self.scrollView.contentSize = CGSizeMake(w, titleHeight + descrHeight + _iconView.frame.size.height);
}

+ (CGFloat) getTitleViewHeightWithWidth:(CGFloat)width text:(NSString *)text
{
    UIFont *titleFont = [UIFont systemFontOfSize:20.0];
    return [OAUtilities calculateTextBounds:text width:width font:titleFont].height + textMarginVertical;
}

+ (CGFloat) getDescrViewHeightWithWidth:(CGFloat)width text:(NSString *)text
{
    UIFont *font = [UIFont systemFontOfSize:14.0];
    return [OAUtilities calculateTextBounds:text width:width font:font].height + textMarginVertical;
}

- (IBAction)closeButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)subscribeButtonPressed:(id)sender {
}

@end
