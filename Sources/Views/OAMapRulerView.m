//
//  OAMapRulerView.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 19.10.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAMapRulerView.h"
#import <QuartzCore/QuartzCore.h>
#import "OsmAndApp.h"

@interface OAMapRulerView()

@property (strong, nonatomic) UILabel* textLabel;

@property CALayer *bottomBorder;
@property CALayer *leftBorder;
@property CALayer *rightBorder;


@end

@implementation OAMapRulerView

-(instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
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
        [self addSubview:self.textLabel];
        CGRect frame = self.frame;
        frame.size.width = 0;
        self.frame = frame;
        self.hidden = true;
    }

    return self;
}

-(void)invalidateLayout {

    // Add a bottomBorder.
    self.bottomBorder.frame = CGRectMake(0, self.frame.size.height, self.frame.size.width, 1.0f);
    self.leftBorder.frame = CGRectMake(0, self.frame.size.height - 10, 1.0f, 10);
    self.rightBorder.frame = CGRectMake(self.frame.size.width-1, self.frame.size.height - 10, 1.0f, 10);
}

-(void)setRulerData:(float) metersPerPixel {

    float metersPerMinSize = metersPerPixel * kMapRulerMinWidth * [[UIScreen mainScreen] scale];
    int rulerWidth = 0;
    NSString * vl = @"";
    if(metersPerPixel > 0 && metersPerPixel < 10000000.0)
    {
        double roundedDist = [[OsmAndApp instance] calculateRoundedDist: metersPerMinSize];
        rulerWidth =  (roundedDist / metersPerPixel) / [[UIScreen mainScreen] scale];
        if(rulerWidth > kMapRulerMaxWidth || rulerWidth < kMapRulerMinWidth) {
            rulerWidth = 0;
        } else {
            vl = [[OsmAndApp instance] getFormattedDistance: roundedDist];
        }
    }
    CGRect frame = self.frame;
    self.hidden = rulerWidth == 0 ? true : false;
    frame.size.width = rulerWidth;
    self.frame = frame;
    [self invalidateLayout];
    [self.textLabel setText:vl];

}


@end
