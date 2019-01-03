//
//  OAOsmLiveBanner.m
//  OsmAnd
//
//  Created by Alexey on 03/01/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOsmLiveBannerView.h"
#import "OAColors.h"
#import "OAUtilities.h"
#import "Localization.h"

#define kMarginHor 12.0
#define kMarginVert 12.0
#define kContentMargin 16.0
#define kDivH 1.0

@interface OAOsmLiveBannerView()

@property (nonatomic) UIView *containerView;
@property (nonatomic) UIImageView *imageView;
@property (nonatomic) UILabel *lbTitle;
@property (nonatomic) UILabel *lbDescr;
@property (nonatomic) UIButton *btnSubscribe;

@property (nonatomic) EOAOsmLiveBannerType bannerType;
@property (nonatomic) NSString *minPriceStr;

@end

@implementation OAOsmLiveBannerView

+ (instancetype) bannerWithType:(EOAOsmLiveBannerType)bannerType minPriceStr:(NSString *)minPriceStr;
{
    return [[OAOsmLiveBannerView alloc] initWithType:bannerType minPriceStr:minPriceStr];
}

- (instancetype) initWithType:(EOAOsmLiveBannerType)bannerType minPriceStr:(NSString *)minPriceStr;
{
    self = [super init];
    if (self)
    {
        self.bannerType = bannerType;
        self.minPriceStr = minPriceStr;
        [self commonInit];
    }
    return self;
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
    self.containerView.backgroundColor = UIColorFromRGB(color_osm_banner);
    self.containerView.clipsToBounds = YES;
    
    self.imageView = [[UIImageView alloc] init];
    self.imageView.image = [UIImage imageNamed:@"ic_action_osmand_logo_banner"];

    self.lbTitle = [[UILabel alloc] init];
    self.lbTitle.font = [UIFont boldSystemFontOfSize:16.0];
    self.lbTitle.textColor = UIColor.whiteColor;
    self.lbTitle.numberOfLines = 0;
    self.lbTitle.text = self.bannerType == EOAOsmLiveBannerUnlockAll ? OALocalizedString(@"osm_live_unlock_all") : OALocalizedString(@"osm_live_unlock_updates");

    self.lbDescr = [[UILabel alloc] init];
    self.lbDescr.numberOfLines = 0;
    NSString *descr = [NSString stringWithFormat:OALocalizedString(@"osm_live_banner_descr"), self.minPriceStr];
    NSMutableAttributedString *descrStr = [[NSMutableAttributedString alloc] initWithData:[descr dataUsingEncoding:NSUTF8StringEncoding]
                                                                                  options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                                                            NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)}
                                                                       documentAttributes:nil error:nil];
    [descrStr enumerateAttributesInRange:NSMakeRange(0, descrStr.length) options:0 usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
        UIFont *newFont = nil;
        if (attrs[@"NSFont"])
        {
            UIFont *f = (UIFont *)attrs[@"NSFont"];
            BOOL bold = NO;
            if (f)
                bold = [[f.fontName lowerCase] containsString:@"bold"];
            
            newFont = bold ? [UIFont boldSystemFontOfSize:14.0] : [UIFont systemFontOfSize:14.0];
        }
        for (NSAttributedStringKey key in attrs.allKeys)
            [descrStr removeAttribute:attrs[key] range:range];
        
        if (newFont)
            [descrStr addAttribute:NSFontAttributeName value:newFont range:range];
    }];
    [descrStr addAttribute:NSForegroundColorAttributeName value:UIColor.whiteColor range:NSMakeRange(0, descrStr.length)];
    self.lbDescr.attributedText = descrStr;
    
    self.btnSubscribe = [UIButton buttonWithType:UIButtonTypeSystem];
    self.btnSubscribe.backgroundColor = UIColorFromRGB(color_osmand_orange);
    self.btnSubscribe.layer.cornerRadius = 3;
    [self.btnSubscribe setTintColor:UIColor.whiteColor];
    [self.btnSubscribe setTitle:OALocalizedString(@"osm_live_get_title") forState:UIControlStateNormal];
    self.btnSubscribe.titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
    self.btnSubscribe.contentEdgeInsets = UIEdgeInsetsMake(0, kContentMargin, 0, kContentMargin);
    [self.btnSubscribe addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.containerView addSubview:self.imageView];
    [self.containerView addSubview:self.lbTitle];
    [self.containerView addSubview:self.lbDescr];
    [self.containerView addSubview:self.btnSubscribe];
    
    self.containerView.layer.cornerRadius = 5;
    
    [self addSubview:self.containerView];
}

- (void) onButtonPressed:(id)sender
{
    if (self.delegate)
        [self.delegate osmLiveBannerPressed];
}

- (CGFloat) updateLayout:(CGFloat)width margin:(CGFloat)margin
{
    CGFloat w = width - kMarginHor * 2 - margin * 2;
    
    [self.imageView sizeToFit];
    CGRect mf = self.imageView.frame;
    mf.origin.x = kContentMargin;
    mf.origin.y = kContentMargin + 4.0;
    self.imageView.frame = mf;
    
    CGFloat tw = w - 64.0 - kContentMargin;
    CGFloat th = [OAUtilities calculateTextBounds:self.lbTitle.text width:tw font:self.lbTitle.font].height;
    CGRect tf = CGRectMake(64.0, kContentMargin, tw, th);
    self.lbTitle.frame = tf;
    
    CGFloat dw = w - 64.0 - kContentMargin;
    CGFloat dh = [OAUtilities calculateTextBounds:self.lbDescr.attributedText width:dw].height;
    CGRect df = CGRectMake(64.0, CGRectGetMaxY(self.lbTitle.frame) + kMarginVert, dw, dh);
    self.lbDescr.frame = df;
    
    [self.btnSubscribe sizeToFit];
    CGRect bf = self.btnSubscribe.frame;
    bf.origin.x = 64.0;
    bf.origin.y = CGRectGetMaxY(df) + kContentMargin;
    bf.size.height = 36.0;
    bf.size.width = MIN(bf.size.width, w - 64.0 - kMarginHor);
    self.btnSubscribe.frame = bf;
    
    self.containerView.frame = CGRectMake(margin + kMarginHor, kMarginVert, w, CGRectGetMaxY(bf) + kMarginHor);
    
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
