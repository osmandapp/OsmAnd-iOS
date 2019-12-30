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

- (void) commonInit
{
    [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil];
    
    [self addSubview:_contentView];
    _contentView.frame = self.bounds;
    
    _colorView.layer.cornerRadius = 12.;
    _colorView.layer.borderWidth = 0.5;
    _colorView.layer.borderColor = UIColorFromRGB(color_tint_gray).CGColor;
    _colorView.backgroundColor = _color;
    
    _titleView.text = _title;
    _distanceView.text = _distance;
}

@end
