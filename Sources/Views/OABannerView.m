//
//  OABannerView.m
//  OsmAnd
//
//  Created by Alexey Kulish on 08/05/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OABannerView.h"

@implementation OABannerView
{
    UILabel *_freeTextLabel;
    UILabel *_freeTextDescLabel;
    UIButton *_btnBanner;
    
    BOOL _landscape;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)layoutSubviews
{
    if (_landscape)
    {
        CGSize btnSize = [self getButtonSize];
        _btnBanner.frame = CGRectMake(self.frame.size.width - btnSize.width - 20.0, self.frame.size.height / 2.0 - btnSize.height / 2.0, btnSize.width, btnSize.height);

        _freeTextLabel.frame = CGRectMake(_freeTextLabel.frame.origin.x, _freeTextLabel.frame.origin.y, _btnBanner.frame.origin.x - 80.0 - 12.0, 36.0);
        [_freeTextLabel sizeToFit];
        _freeTextDescLabel.frame = CGRectMake(_freeTextDescLabel.frame.origin.x, _freeTextDescLabel.frame.origin.y, _btnBanner.frame.origin.x - 80.0 - 12.0, 36.0);
        [_freeTextDescLabel sizeToFit];
        
    }
    else
    {
        _freeTextLabel.frame = CGRectMake(_freeTextLabel.frame.origin.x, _freeTextLabel.frame.origin.y, self.frame.size.width - 80.0, 36.0);
        [_freeTextLabel sizeToFit];
        _freeTextDescLabel.frame = CGRectMake(_freeTextDescLabel.frame.origin.x, _freeTextDescLabel.frame.origin.y, self.frame.size.width - 80.0, 36.0);
        [_freeTextDescLabel sizeToFit];
        
        CGSize btnSize = [self getButtonSize];
        _btnBanner.frame = CGRectMake(60.0, _freeTextDescLabel.frame.origin.y + _freeTextDescLabel.frame.size.height + 6.0, btnSize.width, btnSize.height);
    }
}

- (CGSize)getButtonSize
{
    CGSize s = [_buttonTitle boundingRectWithSize:CGSizeMake(240.0, 36.0)
                                          options:NSStringDrawingUsesLineFragmentOrigin
                                       attributes:@{NSFontAttributeName : _btnBanner.titleLabel.font}
                                          context:nil].size;
    return CGSizeMake(MAX(80.0, s.width + 25.0), _btnBanner.bounds.size.height);
}

- (CGFloat) getHeightByWidth:(CGFloat)width
{
    CGSize btnSize = [self getButtonSize];
    CGSize titleSize = [_title boundingRectWithSize:CGSizeMake(10000.0, 20.0)
                                          options:NSStringDrawingUsesLineFragmentOrigin
                                       attributes:@{NSFontAttributeName : _freeTextLabel.font}
                                          context:nil].size;

    _landscape = (width - btnSize.width - 20.0 > _freeTextLabel.frame.origin.x + titleSize.width + 12.0) && width > 320.0;
    
    if (_landscape)
    {
        CGSize descSize = [_desc boundingRectWithSize:CGSizeMake(width - 80.0 - 12.0 - btnSize.width - 20.0, 36.0)
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:@{NSFontAttributeName : _freeTextDescLabel.font}
                                              context:nil].size;
        if (descSize.height > 20.0)
            return 85.0;
        else
            return 75.0;
    }
    else
    {
        CGSize descSize = [_desc boundingRectWithSize:CGSizeMake(width - 80.0, 36.0)
                                              options:NSStringDrawingUsesLineFragmentOrigin
                                           attributes:@{NSFontAttributeName : _freeTextDescLabel.font}
                                              context:nil].size;
        return _freeTextDescLabel.frame.origin.y + descSize.height + 6.0 + btnSize.height + 12.0;
    }
}

- (void)commonInit
{
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.clipsToBounds = YES;
    
    UIImageView *background = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"img_purchase_banner_portrait"]];
    background.frame = self.frame;
    background.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:background];
    
    UIImageView *leftIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"map_banner"]];
    leftIcon.frame = CGRectMake(20.0, 20.0, 25.0, 25.0);
    [self addSubview:leftIcon];
    
    
    _freeTextLabel = [[UILabel alloc] initWithFrame:CGRectMake(60.0, 19.0, 240.0, 20.0)];
    _freeTextLabel.textColor = [UIColor whiteColor];
    _freeTextLabel.font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:17.5];
    _freeTextLabel.numberOfLines = 1;
    [self addSubview:_freeTextLabel];
    
    _freeTextDescLabel = [[UILabel alloc] initWithFrame:CGRectMake(60.0, 43.0, 240.0, 36.0)];
    _freeTextDescLabel.textColor = [UIColor colorWithRed:0.882f green:0.890f blue:0.890f alpha:1.00f];
    _freeTextDescLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:12.5];
    _freeTextDescLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _freeTextDescLabel.numberOfLines = 2;
    [self addSubview:_freeTextDescLabel];
    
    _btnBanner = [UIButton buttonWithType:UIButtonTypeSystem];
    _btnBanner.frame = CGRectMake(60.0, 85.0, 100.0, 27.0);
    [_btnBanner setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_btnBanner.titleLabel setFont:[UIFont fontWithName:@"AvenirNext-DemiBold" size:12.5]];
    [_btnBanner addTarget:self action:@selector(btnBannerClicked:) forControlEvents:UIControlEventTouchUpInside];
    _btnBanner.backgroundColor = [UIColor colorWithRed:0.992f green:0.561f blue:0.149f alpha:1.00f];
    _btnBanner.layer.cornerRadius = 2;
    _btnBanner.layer.masksToBounds = YES;
    [self addSubview:_btnBanner];
}

- (void)btnBannerClicked:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(bannerButtonPressed)])
        [self.delegate bannerButtonPressed];
}

-(void)setTitle:(NSString *)title
{
    _title = [title copy];
    _freeTextLabel.text = title;
}

-(void)setDesc:(NSString *)desc
{
    _desc = [desc copy];
    _freeTextDescLabel.text = desc;
}

-(void)setButtonTitle:(NSString *)buttonTitle
{
    _buttonTitle = [[buttonTitle copy] uppercaseStringWithLocale:[NSLocale currentLocale]];
    [_btnBanner setTitle:self.buttonTitle forState:UIControlStateNormal];
}

@end
