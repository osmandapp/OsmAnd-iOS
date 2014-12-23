//
//  OAMapRulerView.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 19.10.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAMapRulerView.h"
#import <QuartzCore/QuartzCore.h>

@interface OAMapRulerView()

@property (strong, nonatomic) UILabel* textLabel;
@property NSArray* markerList;

@property CALayer *bottomBorder;
@property CALayer *leftBorder;
@property CALayer *rightBorder;


@end

@implementation OAMapRulerView

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.markerList = @[@1, @2, @5, @10, @20, @50, @100, @200, @500, @1000, @2000, @5000, @10000, @20000, @50000, @100000, @200000, @500000, @1000000, @2000000, @5000000, @10000000];
        
        // Add a bottomBorder.
        self.bottomBorder = [CALayer layer];
        self.bottomBorder.frame = CGRectMake(0, self.frame.size.height, self.frame.size.width, 1.0f);
        self.bottomBorder.backgroundColor = [UIColor colorWithWhite:0.3f alpha:1.0f].CGColor;
        [self.layer addSublayer:self.bottomBorder];
        
        // Add a leftBorder.
        self.leftBorder = [CALayer layer];
        self.leftBorder.frame = CGRectMake(0, self.frame.size.height - 10, 1.0f, 10);
        self.leftBorder.backgroundColor = [UIColor colorWithWhite:0.3f alpha:1.0f].CGColor;
        [self.layer addSublayer:self.leftBorder];
        
        // Add a rightBorder.
        self.rightBorder = [CALayer layer];
        self.rightBorder.frame = CGRectMake(self.frame.size.width-1, self.frame.size.height - 10, 1.0f, 10);
        self.rightBorder.backgroundColor = [UIColor colorWithWhite:0.3f alpha:1.0f].CGColor;
        [self.layer addSublayer:self.rightBorder];
        
        self.textLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, self.frame.size.height - 20, self.frame.size.width - 10, 15)];
        [self.textLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:12]];
        [self.textLabel setText:@"0 m"];
        [self addSubview:self.textLabel];

    }
    return self;
}

-(void)invalidateLayout {

    // Add a bottomBorder.
    self.bottomBorder.frame = CGRectMake(0, self.frame.size.height, self.frame.size.width, 1.0f);
    self.leftBorder.frame = CGRectMake(0, self.frame.size.height - 10, 1.0f, 10);
    self.rightBorder.frame = CGRectMake(self.frame.size.width-1, self.frame.size.height - 10, 1.0f, 10);
}

-(void)setRulerData:(struct RulerData)data {
    

    float metersPerMinSize = data.tileSizeInMeters / data.tileSizeInPixels * kMapRulerMinWidth ;
    
    __block int minScaleSize = 0;
    [self.markerList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if ([obj integerValue] > metersPerMinSize) {
            minScaleSize = [obj integerValue];
            *stop = YES;
        }
    }];

    float xCoof = minScaleSize / metersPerMinSize;
    int rulerWidth = kMapRulerMinWidth * xCoof;

    if (metersPerMinSize < 1) {
        [self.textLabel setText:@"< 1 m"];
        rulerWidth = kMapRulerMaxWidth;
    } else {
        CGRect frame = self.frame;
        frame.size.width = rulerWidth;
        self.frame = frame;
        [self invalidateLayout];
    
        NSString * metricValue = @"m";
        if (minScaleSize >= 1000) {
            minScaleSize /= 1000;
            metricValue = @"km";
        }
        [self.textLabel setText:[NSString stringWithFormat:@"%0.d %@", minScaleSize, metricValue]];
    }

}


@end
