//
//  OARouteSegmentShieldView.m
//  OsmAnd
//
//  Created by Paul on 13.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARouteSegmentShieldView.h"
#import "OsmAnd_Maps-Swift.h"
#import "OATargetInfoViewController.h"
#import "GeneratedAssetSymbols.h"

static UIFont *_shieldFont;

@implementation OARouteSegmentShieldView
{
    EOATransportShiledType _type;
    UIColor *_color;
    NSString *_title;
    NSString *_iconName;
    
    UITapGestureRecognizer *_tapRecognizer;
    UILongPressGestureRecognizer *_longTapRecognizer;
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
    
    _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onViewTapped:)];
    _tapRecognizer.numberOfTapsRequired = 1;
    _longTapRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onViewPressed:)];
    _longTapRecognizer.numberOfTouchesRequired = 1;
    _longTapRecognizer.minimumPressDuration = .2;
    
    [self addGestureRecognizer:_tapRecognizer];
    [self addGestureRecognizer:_longTapRecognizer];
    
    [self addSubview:_contentView];
    _contentView.frame = self.bounds;
    
    _contentView.layer.cornerRadius = 4.0;
    _shieldLabel.text = _title;
    
    if (_type == EOATransportShiledPedestrian)
    {
        UIColor *primaryColor = [UIColor colorNamed:ACColorNameIconColorActive];
        _contentView.layer.borderColor = primaryColor.CGColor;
        _contentView.layer.borderWidth = 2.0;
        _shieldLabel.textColor = primaryColor;
        _contentView.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
        _shieldImage.image = [UIImage templateImageNamed:_iconName];
        _shieldImage.tintColor = primaryColor;
    }
    else
    {
        UIColor *tintColor = [OAUtilities isColorBright:_color] ? [UIColor.blackColor colorWithAlphaComponent:0.9] : UIColor.whiteColor;
        _contentView.backgroundColor = _color;
        _shieldLabel.textColor = tintColor;
        _shieldImage.image = [[OATargetInfoViewController getIcon:_iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _shieldImage.tintColor = tintColor;
    }

    self.shieldLabel.font = [UIFont scaledSystemFontOfSize:15. weight:UIFontWeightSemibold];
}

- (void) traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection])
        _contentView.layer.borderColor = [UIColor colorNamed:ACColorNameIconColorActive].CGColor;
}

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(6.0 + 20. + 6.0 + _shieldLabel.frame.size.width + 12.0, 32.0);
}

- (void)restoreShieldState {
    [UIView animateWithDuration:.2 animations:^{
        if (_type == EOATransportShiledPedestrian)
        {
            [_shieldImage setTintColor:[UIColor colorNamed:ACColorNameIconColorActive]];
            _shieldLabel.textColor = [UIColor colorNamed:ACColorNameTextColorActive];
            _contentView.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
        }
        else
        {
            [UIView animateWithDuration:.2 animations:^{
                UIColor *tintColor = [OAUtilities isColorBright:_color] ? [UIColor.blackColor colorWithAlphaComponent:0.9] : UIColor.whiteColor;
                _shieldLabel.textColor = tintColor;
                _shieldImage.tintColor = tintColor;
            }];
        }
    }];
}

- (void)animatePress:(BOOL)longPress
{
    [UIView animateWithDuration:.2 animations:^{
        if (_type == EOATransportShiledPedestrian)
        {
            [_shieldImage setTintColor:[UIColor colorNamed:ACColorNameGroupBg]];
            _shieldLabel.textColor = [UIColor colorNamed:ACColorNameGroupBg];
            _contentView.backgroundColor = [UIColor colorNamed:ACColorNameIconColorActive];
        }
        else
        {
            [_shieldImage setTintColor:[UIColor colorNamed:ACColorNameIconColorDefault]];
            _shieldLabel.textColor = [UIColor colorNamed:ACColorNameIconColorDefault];
        }
    } completion:^(BOOL finished) {
        if (!longPress)
        {
            [self restoreShieldState];
        }
    }];
}

- (void) onViewTapped:(UIGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded)
        [self animatePress:NO];
        [_delegate onShieldPressed:self.tag];
}

- (void) onViewPressed:(UIGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan)
    {
        [self animatePress:YES];
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded)
    {
        [self restoreShieldState];
        [_delegate onShieldPressed:self.tag];
    }
}

+ (CGFloat) getViewWidth:(NSString *)text
{
    if (!_shieldFont)
        _shieldFont = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    return 6.0 + 20. + 6.0 + MIN(86.0, [OAUtilities calculateTextBounds:text width:86.0 font:_shieldFont].width) + 12.0;
}

@end
