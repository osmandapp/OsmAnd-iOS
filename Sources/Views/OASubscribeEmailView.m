//
//  OASubscribeEmailView.m
//  OsmAnd
//
//  Created by Alexey on 28/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OASubscribeEmailView.h"
#import "OAColors.h"
#import "OALinks.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

#define kMarginHor 6.0
#define kMarginVert 0.0
#define kContentMargin 16.0
#define kDivH 1.0

@interface OACustomTextView : UITextView

@end

@implementation OACustomTextView

- (UITextRange *) selectedTextRange
{
    return nil;
}

@end

@interface OASubscribeEmailView()

@property (nonatomic) UIView *containerView;
@property (nonatomic) UIImageView *imageView;
@property (nonatomic) OACustomTextView *lbTitle;
@property (nonatomic) UIButton *btnSubscribe;

@end

@implementation OASubscribeEmailView
{
    CALayer *_div;
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
    self.containerView.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
    self.imageView = [[UIImageView alloc] init];
    self.imageView.image = [UIImage templateImageNamed:@"ic_action_message"];
    self.imageView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
    [self.imageView sizeToFit];
    
    self.lbTitle = [[OACustomTextView alloc] init];
    self.lbTitle.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
    self.lbTitle.userInteractionEnabled = YES;
    self.lbTitle.editable = NO;
    self.lbTitle.textContainerInset = UIEdgeInsetsZero;
    self.lbTitle.contentInset = UIEdgeInsetsZero;
    self.lbTitle.textContainer.lineFragmentPadding = 0;
    NSMutableAttributedString *titleStr = [[NSMutableAttributedString alloc] initWithData:[OALocalizedString(@"subscribe_email_desc") dataUsingEncoding:NSUTF8StringEncoding]
                                                                   options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                                             NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)}
                                                        documentAttributes:nil error:nil];
    [titleStr addAttribute:NSFontAttributeName value:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline] range:NSMakeRange(0, titleStr.length)];
    [titleStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorNamed:ACColorNameTextColorPrimary] range:NSMakeRange(0, titleStr.length)];
    [titleStr enumerateAttributesInRange:NSMakeRange(0, titleStr.length) options:0 usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
        if (attrs[@"NSLink"])
        {
            [titleStr removeAttribute:attrs[@"NSLink"] range:range];
            [titleStr addAttribute:NSLinkAttributeName value:kOsmAndGiveaway range:range];
            [titleStr addAttribute:NSForegroundColorAttributeName value:[UIColor colorNamed:ACColorNameTextColorPrimary] range:range];
            *stop = YES;
        }
    }];
    self.lbTitle.attributedText = titleStr;
    self.lbTitle.adjustsFontForContentSizeCategory = YES;
    
    self.btnSubscribe = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.btnSubscribe setTintColor:[UIColor colorNamed:ACColorNameIconColorActive]];
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
    _div.backgroundColor = [UIColor colorNamed:ACColorNameCustomSeparator].CGColor;
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
    CGFloat lbh = [OAUtilities calculateTextBounds:self.lbTitle.attributedText width:lbw].height;
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

- (void) updateColorForCALayer
{
    _div.backgroundColor = [UIColor colorNamed:ACColorNameCustomSeparator].CGColor;
}

@end
