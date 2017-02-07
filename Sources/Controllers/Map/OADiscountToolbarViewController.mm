//
//  OADiscountToolbarViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 07/02/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OADiscountToolbarViewController.h"
#import "OAUtilities.h"

@interface OADiscountToolbarViewController ()

@end

@implementation OADiscountToolbarViewController
{
    NSString *_title;
    NSString *_description;
    UIImage *_icon;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.titleLabel.text = _title;
    self.descriptionLabel.text = _description;
    [self.backButton setImage:_icon forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void) setTitle:(NSString *)title description:(NSString *)description icon:(UIImage *)icon
{
    _title = title;
    _description = description;
    _icon = icon;
    
    if (self.viewLoaded)
    {
        self.titleLabel.text = title;
        self.descriptionLabel.text = description;
        [self.backButton setImage:icon forState:UIControlStateNormal];
    }
}

-(int)getPriority
{
    return DISCOUNT_TOOLBAR_PRIORITY;
}

- (IBAction)backPress:(id)sender
{
    if (self.discountDelegate)
        [self.discountDelegate discountToolbarPress];
}

- (IBAction)closePress:(id)sender
{
    if (self.discountDelegate)
        [self.discountDelegate discountToolbarClose];
}

- (IBAction)shadowPress:(id)sender
{
    if (self.discountDelegate)
        [self.discountDelegate discountToolbarPress];
}

-(UIStatusBarStyle)getPreferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

-(UIColor *)getStatusBarColor
{
    return UIColorFromRGB(0x357ef2);
}

-(void)updateFrame:(BOOL)animated
{
    CGFloat height;

    CGSize titleSize = [OAUtilities calculateTextBounds:self.titleLabel.text width:self.view.bounds.size.width - 90.0 font:[UIFont fontWithName:@"AvenirNext-Regular" size:17.0]];
    
    BOOL hasDescription = self.descriptionLabel.text.length > 0;
    if (hasDescription)
    {
        CGSize descSize = [OAUtilities calculateTextBounds:self.descriptionLabel.text width:self.view.bounds.size.width - 90.0 font:[UIFont fontWithName:@"AvenirNext-Regular" size:12.0]];
        
        height = MAX(44, titleSize.height + descSize.height + 22);

        self.titleLabel.frame = CGRectMake(self.titleLabel.frame.origin.x, 10, titleSize.width, titleSize.height);
        self.descriptionLabel.frame = CGRectMake(self.descriptionLabel.frame.origin.x, height - 10 - descSize.height, descSize.width, descSize.height);
    }
    else
    {
        height = MAX(44, titleSize.height + 20);
        self.titleLabel.frame = CGRectMake(self.titleLabel.frame.origin.x, 0, titleSize.width, height);
    }
    
    self.view.frame = CGRectMake(0.0, [self.delegate toolbarTopPosition], DeviceScreenWidth, height);
    self.navBarView.frame = self.view.bounds;
    
    [self.delegate toolbarLayoutDidChange:self animated:animated];
}

@end
