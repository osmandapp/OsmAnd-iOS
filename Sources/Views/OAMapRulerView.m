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
#import "OAAppSettings.h"
#import "OAOsmAndFormatter.h"

@interface OAMapRulerView()

@property (strong, nonatomic) UILabel* textLabel;

@property CALayer *bottomBorder;
@property CALayer *leftBorder;
@property CALayer *rightBorder;

@end

@implementation OAMapRulerView

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        
        // Add a bottomBorder.
        self.bottomBorder = [CALayer layer];
        self.bottomBorder.frame = CGRectMake(0, self.frame.size.height, self.frame.size.width, 1.0f);
        [self.layer addSublayer:self.bottomBorder];
        
        // Add a leftBorder.
        self.leftBorder = [CALayer layer];
        self.leftBorder.frame = CGRectMake(0, self.frame.size.height - 10, 1.0f, 10);
        [self.layer addSublayer:self.leftBorder];
        
        // Add a rightBorder.
        self.rightBorder = [CALayer layer];
        self.rightBorder.frame = CGRectMake(self.frame.size.width-1, self.frame.size.height - 10, 1.0f, 10);
        [self.layer addSublayer:self.rightBorder];
        
        self.textLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, self.frame.size.height - 20, self.frame.size.width - 10, 15)];
        [self.textLabel setFont:[UIFont systemFontOfSize:12]];
        [self addSubview:self.textLabel];
        CGRect frame = self.frame;
        frame.size.width = 0;
        self.frame = frame;
        self.hidden = true;
        
        [self updateColors];
    }

    return self;
}

- (BOOL) hasNoData
{
    return self.textLabel.text.length == 0;
}

- (void) updateColors
{
    if([OAAppSettings sharedManager].nightMode)
        [self setNight];
    else
        [self setDay];
}

- (void) setDay
{
    self.bottomBorder.backgroundColor = [UIColor colorWithWhite:0.3f alpha:1.0f].CGColor;
    self.leftBorder.backgroundColor = [UIColor colorWithWhite:0.3f alpha:1.0f].CGColor;
    self.rightBorder.backgroundColor = [UIColor colorWithWhite:0.3f alpha:1.0f].CGColor;
    self.textLabel.textColor = [UIColor colorWithWhite:0.0f alpha:1.0f];
}

- (void) setNight
{
    self.bottomBorder.backgroundColor = [UIColor colorWithWhite:0.6f alpha:1.0f].CGColor;
    self.leftBorder.backgroundColor = [UIColor colorWithWhite:0.6f alpha:1.0f].CGColor;
    self.rightBorder.backgroundColor = [UIColor colorWithWhite:0.6f alpha:1.0f].CGColor;
    self.textLabel.textColor = [UIColor colorWithWhite:0.7f alpha:1.0f];
}

- (void) invalidateLayout
{
    // Add a bottomBorder.
    self.bottomBorder.frame = CGRectMake(0, self.frame.size.height, self.frame.size.width, 1.0f);
    self.leftBorder.frame = CGRectMake(0, self.frame.size.height - 10, 1.0f, 10);
    self.rightBorder.frame = CGRectMake(self.frame.size.width-1, self.frame.size.height - 10, 1.0f, 10);
}

- (void) setRulerData:(float)metersPerPixel
{
    double metersPerMaxSize = metersPerPixel * kMapRulerMaxWidth * [[UIScreen mainScreen] scale];
    int rulerWidth = 0;
    NSString * vl = @"";
    if (metersPerPixel > 0 && metersPerPixel < 10000000.0)
    {
        double roundedDist = [OAOsmAndFormatter calculateRoundedDist:metersPerMaxSize];
        rulerWidth =  (roundedDist / metersPerPixel) / [[UIScreen mainScreen] scale];
        if (rulerWidth < 0)
            rulerWidth = 0;
        else
            vl = [OAOsmAndFormatter getFormattedDistance: roundedDist];
    }
    CGRect frame = self.frame;
    self.hidden = rulerWidth == 0 ? true : false;
    frame.size.width = rulerWidth;
    self.frame = frame;
    [self invalidateLayout];
    [self.textLabel setText:vl];
    
    CGFloat labelWidth = [OAUtilities calculateTextBounds:_textLabel.text width:DeviceScreenWidth font:_textLabel.font].width;
    CGRect textLabelFrame = _textLabel.frame;
    textLabelFrame.size.width = labelWidth;
    _textLabel.frame = textLabelFrame;
}


@end
