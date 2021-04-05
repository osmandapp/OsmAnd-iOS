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
    NSString *_buttonText;
    UIImage *_icon;
    
    NSDictionary<NSString *, UIColor *> *_colors;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.titleLabel.text = _title;
    self.descriptionLabel.text = _description;
    [self.backButton setImage:_icon forState:UIControlStateNormal];
    [self setTextButton];
    [self setupColors];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (EOAToolbarAttentionLevel) getAttentionLevel
{
    return EOAToolbarAttentionLevelHigh;
}

- (void) setTitle:(NSString *)title description:(NSString *)description icon:(UIImage *)icon buttonText:(NSString *)buttonText colors:(NSDictionary<NSString *, UIColor *> *) colorDictionary
{
    _title = title;
    _description = description;
    _icon = icon;
    _buttonText = buttonText;
    _colors = colorDictionary;
    
    if (self.viewLoaded)
    {
        self.titleLabel.text = title;
        self.descriptionLabel.text = description;
        [self.backButton setImage:icon forState:UIControlStateNormal];
        [self setTextButton];
        [self setupColors];
    }
}

- (void) setTextButton
{
    if (_buttonText == nil || [_buttonText length] == 0)
    {
        self.additionalButton.hidden = YES;
    }
    else
    {
        [self.additionalButton setTitle:_buttonText forState:UIControlStateNormal];
        self.additionalButton.titleLabel.numberOfLines = 0;
        [self.additionalButton.titleLabel setLineBreakMode:NSLineBreakByWordWrapping];
        [self.additionalButton.titleLabel sizeToFit];
    }
}

- (void) setupColors
{
    UIColor *bgColor = [_colors objectForKey:@"bg_color"];
    UIColor *titleColor = [_colors objectForKey:@"title_color"];
    UIColor *descriptionColor = [_colors objectForKey:@"description_color"];
    UIColor *buttonColor = [_colors objectForKey:@"button_title_color"];
    
    if (bgColor)
        self.navBarView.backgroundColor = bgColor;
    if (titleColor)
        [self.titleLabel setTextColor:titleColor];
    if (descriptionColor)
        [self.descriptionLabel setTextColor:descriptionColor];
    if (buttonColor)
        [self.additionalButton setTitleColor:buttonColor forState:UIControlStateNormal];
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
- (IBAction)additionalButtonPress:(id)sender
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
    UIColor *statusBarColor = [_colors objectForKey:@"status_bar_color"];
    UIColor *bgColor = [_colors objectForKey:@"bg_color"];
    return statusBarColor ? statusBarColor : (bgColor ? bgColor : UIColorFromRGB(0x357ef2));
}

-(void)updateFrame:(BOOL)animated
{
    CGFloat height;
    CGFloat width = DeviceScreenWidth - OAUtilities.getLeftMargin * 2;
    
    CGSize titleSize = [OAUtilities calculateTextBounds:self.titleLabel.text width:width - 90.0 font:[UIFont fontWithName:@"AvenirNext-Regular" size:17.0]];
    
    CGSize descSize;
    CGSize buttonSize;
    BOOL hasDescription = self.descriptionLabel.text.length > 0;
    BOOL hasButton = !self.additionalButton.hidden;
    CGFloat maxHeight = (hasButton && hasDescription) ? 70 : 44;
    if (hasButton && hasDescription)
    {
        buttonSize = [OAUtilities calculateTextBounds:self.additionalButton.titleLabel.text width:width - 90.0 font:[UIFont fontWithName:@"AvenirNext-Regular" size:16.0]];
        descSize = [OAUtilities calculateTextBounds:self.descriptionLabel.text width:width - 90.0 font:[UIFont fontWithName:@"AvenirNext-Regular" size:12.0]];
        height = MAX(maxHeight, titleSize.height + descSize.height + buttonSize.height + 22);
    }
    else if (hasButton)
    {
        buttonSize = [OAUtilities calculateTextBounds:self.additionalButton.titleLabel.text width:width - 90.0 font:[UIFont fontWithName:@"AvenirNext-Regular" size:16.0]];
        height = MAX(maxHeight, titleSize.height + buttonSize.height + 22);
    }
    else if (hasDescription)
    {
        descSize = [OAUtilities calculateTextBounds:self.descriptionLabel.text width:width - 90.0 font:[UIFont fontWithName:@"AvenirNext-Regular" size:12.0]];
        
        height = MAX(maxHeight, titleSize.height + descSize.height + 22);
    }
    else
    {
        height = MAX(maxHeight, titleSize.height + 20);
    }
    
    self.view.frame = CGRectMake(0.0, [self.delegate toolbarTopPosition], width, height);
    self.navBarView.frame = self.view.bounds;
    
    if (hasDescription && hasButton)
    {
        self.titleLabel.frame = CGRectMake(self.titleLabel.frame.origin.x, 10, titleSize.width, titleSize.height);
        self.descriptionLabel.frame = CGRectMake(self.descriptionLabel.frame.origin.x, self.titleLabel.frame.origin.y + titleSize.height + 3.0, descSize.width, descSize.height);
        self.additionalButton.frame = CGRectMake(self.additionalButton.frame.origin.x, self.descriptionLabel.frame.origin.y + self.descriptionLabel.frame.size.height + 3.0, buttonSize.width, buttonSize.height);
    }
    else if (hasButton)
    {
        self.titleLabel.frame = CGRectMake(self.titleLabel.frame.origin.x, 10, titleSize.width, titleSize.height);
        self.additionalButton.frame = CGRectMake(self.additionalButton.frame.origin.x, height - 10 - buttonSize.height, buttonSize.width, buttonSize.height);
    }
    else if (hasDescription)
    {
        self.titleLabel.frame = CGRectMake(self.titleLabel.frame.origin.x, 10, titleSize.width, titleSize.height);
        self.descriptionLabel.frame = CGRectMake(self.descriptionLabel.frame.origin.x, height - 10 - descSize.height, descSize.width, descSize.height);
    }
    else
    {
        self.titleLabel.frame = CGRectMake(self.titleLabel.frame.origin.x, 0, titleSize.width, height);
    }

    [self.delegate toolbarLayoutDidChange:self animated:animated];
}

@end
