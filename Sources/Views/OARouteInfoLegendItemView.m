//
//  OARouteInfoLegendView.m
//  OsmAnd
//
//  Created by Paul on 24.12.2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OARouteInfoLegendItemView.h"
#import "OARouteStatistics.h"
#import "OsmAndApp.h"
#import "OAColors.h"

@interface OARouteInfoLegendItemView ()

@property (weak, nonatomic) IBOutlet UIView *colorView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UILabel *distanceView;
@property (strong, nonatomic) IBOutlet UIView *contentView;

@end

@implementation OARouteInfoLegendItemView
{
    UIColor *_color;
    NSString *_title;
    NSString *_distance;
}

- (instancetype) initWithTitle:(NSString *)title color:(UIColor *)color distance:(NSString *)distance
{
    self = [super init];
    if (self) {
        _color = color;
        _title = title;
        _distance = distance;
        [self commonInit];
    }
    
    return self;
}

- (void)setSelected:(BOOL)selected
{
    if (_selected == selected)
        return;

    _selected = selected;
    _titleView.font = [UIFont preferredFontForTextStyle:selected ? UIFontTextStyleHeadline : UIFontTextStyleBody];
    self.accessibilityTraits = selected ? UIAccessibilityTraitStaticText | UIAccessibilityTraitSelected : UIAccessibilityTraitStaticText;
}

- (void)commonInit
{
    [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil];
    
    [self addSubview:_contentView];
    _contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [_contentView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [_contentView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_contentView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_contentView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];
    
    _colorView.layer.cornerRadius = 12.;
    _colorView.layer.borderWidth = 0.5;
    _colorView.layer.borderColor = UIColorFromRGB(color_tint_gray).CGColor;
    _colorView.backgroundColor = _color;
    
    _titleView.text = _title;
    _distanceView.text = _distance;
    self.isAccessibilityElement = YES;
    self.accessibilityLabel = _title;
    self.accessibilityValue = _distance;
    self.accessibilityTraits = UIAccessibilityTraitStaticText;
}

@end
