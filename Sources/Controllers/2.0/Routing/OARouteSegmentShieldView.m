//
//  OARouteSegmentShieldView.m
//  OsmAnd
//
//  Created by Paul on 13.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARouteSegmentShieldView.h"

@implementation OARouteSegmentShieldView
{
    EOATransportShiledType _type;
    UIColor *_color;
    NSString *_title;
    NSString *_iconName;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self customInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self customInit];
    }
    return self;
}

- (instancetype) initWithColor:(UIColor *)color title:(NSString *)title iconName:(NSString *)iconName type:(EOATransportShiledType)type
{
    self = [super init];
    if (self) {
        _color = color;
        _title = title;
        _iconName = iconName;
        _type = type;
        [self customInit];
    }
    return self;
}

- (void) customInit
{
    [NSBundle.mainBundle loadNibNamed:NSStringFromClass([self class]) owner:self options:nil];
    
    [self addSubview:_contentView];
    _contentView.frame = self.bounds;
    
    _contentView.layer.cornerRadius = 4.0;
    _shieldImage.image = [[UIImage imageNamed:_iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _shieldLabel.text = _title;
    
    if (_type == EOATransportShiledPedestrian)
    {
        _contentView.layer.borderColor = _color.CGColor;
        _contentView.layer.borderWidth = 2.0;
        _shieldLabel.textColor = _color;
        _contentView.backgroundColor = UIColor.whiteColor;
        _shieldImage.tintColor = _color;
    }
    else
    {
        UIColor *tintColor = [OAUtilities colorIsBright:_color] ? [UIColor.blackColor colorWithAlphaComponent:0.9] : UIColor.whiteColor;
        _contentView.backgroundColor = _color;
        _shieldLabel.textColor = tintColor;
        _shieldImage.tintColor = tintColor;
    }
}

@end
