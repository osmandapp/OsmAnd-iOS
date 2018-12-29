//
//  OASubscribeEmailView.m
//  OsmAnd
//
//  Created by Alexey on 28/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OASubscribeEmailView.h"
#import "OAColors.h"
#import "OAUtilities.h"
#import "Localization.h"

#define kMarginHor 6.0
#define kMarginVert 0.0
#define kContentMargin 16.0
#define kDivH 1.0

@interface OASubscribeEmailView()

@property (nonatomic) UIView *containerView;
@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UILabel *lbTitle;
@property (nonatomic) UIButton *btnSubscribe;

@end

@implementation OASubscribeEmailView
{
    CALayer *_div;
}

- (instancetype) init
{
    self = [super init];
    if (self)
        [self commonInit];
    
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
        [self commonInit];
    
    return self;
}

- (void) commonInit
{
    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = UIColor.whiteColor;
    self.imageView = [[UIImageView alloc] init];
    self.imageView.image = [UIImage imageNamed:@"ic_action_message"];
    [self.imageView sizeToFit];
    
    self.lbTitle = [[UILabel alloc] init];
    self.lbTitle.font = [UIFont systemFontOfSize:15.0];
    self.lbTitle.numberOfLines = 0;
    self.lbTitle.lineBreakMode = NSLineBreakByWordWrapping;
    self.lbTitle.textColor = UIColorFromARGB(color_primary_text_light_argb);
    self.lbTitle.text = OALocalizedString(@"subscribe_email_desc");
    
    self.btnSubscribe = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.btnSubscribe setTintColor:UIColorFromRGB(color_dialog_buttons_light)];
    [self.btnSubscribe setTitle:OALocalizedString(@"osm_live_subscribe_btn") forState:UIControlStateNormal];
    self.btnSubscribe.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    self.btnSubscribe.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    self.btnSubscribe.contentEdgeInsets = UIEdgeInsetsMake(0, kContentMargin, 0, 0);
    [self.btnSubscribe addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.containerView addSubview:self.imageView];
    [self.containerView addSubview:self.lbTitle];
    [self.containerView addSubview:self.btnSubscribe];
    
    self.containerView.layer.cornerRadius = 3;
    self.containerView.layer.shadowColor = UIColor.blackColor.CGColor;
    self.containerView.layer.shadowOpacity = 0.2;
    self.containerView.layer.shadowRadius = 1.5;
    self.containerView.layer.shadowOffset = CGSizeMake(0.0, 0.5);
    
    _div = [[CALayer alloc] init];
    _div.backgroundColor = UIColorFromRGB(color_card_divider_light).CGColor;
    [self.containerView.layer addSublayer:_div];
    [self addSubview:self.containerView];
}

- (void) onButtonPressed:(id)sender
{
    if (self.delegate)
        [self.delegate subscribeEmailButtonPressed];
}

- (CGFloat) updateLayout:(CGFloat)width margin:(CGFloat)margin
{
    CGFloat w = width - kMarginHor * 2 - margin * 2;
    
    CGRect mf = self.imageView.frame;
    mf.origin.x = kContentMargin;
    mf.origin.y = kContentMargin + 4.0;
    self.imageView.frame = mf;
    
    CGFloat lbw = w - 64.0 - kContentMargin;
    CGFloat lbh = [OAUtilities calculateTextBounds:self.lbTitle.text width:lbw font:self.lbTitle.font].height;
    CGRect lbf = CGRectMake(64.0, kContentMargin, lbw, lbh);
    self.lbTitle.frame = lbf;

    _div.frame = CGRectMake(64.0, CGRectGetMaxY(lbf) + kContentMargin, w - 64.0, kDivH);
    
    CGRect bf = CGRectMake(64.0 - kContentMargin, CGRectGetMaxY(lbf) + kContentMargin + 1.0, w - 64.0, 50.0);
    self.btnSubscribe.frame = bf;
    
    self.containerView.frame = CGRectMake(margin + kMarginHor, kMarginVert, w, CGRectGetMaxY(bf));
    
    return self.containerView.frame.size.height + kMarginVert * 2;
}

- (CGRect) updateFrame:(CGFloat)width margin:(CGFloat)margin
{
    CGFloat h = [self updateLayout:width margin:margin];
    CGRect f = self.frame;
    f.size.width = width;
    f.size.height = h;
    self.frame = f;
    return f;
}

@end
