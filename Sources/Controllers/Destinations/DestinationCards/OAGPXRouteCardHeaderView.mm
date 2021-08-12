//
//  OAGPXRouteCardHeaderView.m
//  OsmAnd
//
//  Created by Alexey Kulish on 17/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXRouteCardHeaderView.h"
#import "OAUtilities.h"
#import "OAGPXRouter.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OAGPXRouteDocument.h"


@implementation OAGPXRouteCardHeaderView
{
    UILabel *_statLabel;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.backgroundColor = [UIColor clearColor];
        
        CGFloat w = self.containerView.frame.size.width / 2.0 - DESTINATION_CARD_BORDER * 2.0;
        
        self.title.frame = CGRectMake(DESTINATION_CARD_BORDER, 0.0, w, 34.0);
        self.rightButton.frame = CGRectMake(self.containerView.frame.size.width - w - DESTINATION_CARD_BORDER, 0.0, w, 34.0);
        
        _statLabel = [[UILabel alloc] initWithFrame:CGRectMake(DESTINATION_CARD_BORDER, 27.0, self.containerView.frame.size.width  - DESTINATION_CARD_BORDER * 2.0, 20.0)];
        _statLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        
        [self.containerView insertSubview:_statLabel belowSubview:self.rightButton];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateStatistics];
        });
        
    }
    return self;
}

- (void)updateStatistics
{
    int wptCount = [OAGPXRouter sharedInstance].routeDoc.activePoints.count;
    double distance = [OAGPXRouter sharedInstance].routeDoc.totalDistance;
    NSTimeInterval tripDuration = [[OAGPXRouter sharedInstance] getRouteDuration];

    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
    UIFont *font = [UIFont systemFontOfSize:12];
    
    NSMutableString *distanceStr = [[[OsmAndApp instance] getFormattedDistance:distance] mutableCopy];
    NSString *waypointsStr = [NSString stringWithFormat:@"%d", wptCount];
    NSString *timeMovingStr = [[OsmAndApp instance] getFormattedTimeInterval:tripDuration shortFormat:NO];
    
    NSMutableAttributedString *stringDistance = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"  %@", distanceStr]];
    NSMutableAttributedString *stringWaypoints = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"    %@", waypointsStr]];
    NSMutableAttributedString *stringTimeMoving;
    if (tripDuration > 0)
        stringTimeMoving = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"    %@", timeMovingStr]];
    
    NSTextAttachment *distanceAttachment = [[NSTextAttachment alloc] init];
    distanceAttachment.image = [UIImage imageNamed:@"ic_gpx_distance.png"];
    
    NSTextAttachment *waypointsAttachment = [[NSTextAttachment alloc] init];
    waypointsAttachment.image = [UIImage imageNamed:@"ic_gpx_points.png"];
    
    NSTextAttachment *timeMovingAttachment;
    if (tripDuration > 0)
    {
        NSString *imageName = [[OAGPXRouter sharedInstance] getRouteVariantTypeSmallIconName];
        timeMovingAttachment = [[NSTextAttachment alloc] init];
        timeMovingAttachment.image = [UIImage imageNamed:imageName];
    }
    
    NSAttributedString *distanceStringWithImage = [NSAttributedString attributedStringWithAttachment:distanceAttachment];
    NSAttributedString *waypointsStringWithImage = [NSAttributedString attributedStringWithAttachment:waypointsAttachment];
    NSAttributedString *timeMovingStringWithImage;
    if (tripDuration > 0)
        timeMovingStringWithImage = [NSAttributedString attributedStringWithAttachment:timeMovingAttachment];
    
    [stringDistance replaceCharactersInRange:NSMakeRange(0, 1) withAttributedString:distanceStringWithImage];
    [stringDistance addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:-2.0] range:NSMakeRange(0, 1)];
    [stringWaypoints replaceCharactersInRange:NSMakeRange(2, 1) withAttributedString:waypointsStringWithImage];
    [stringWaypoints addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:-2.0] range:NSMakeRange(2, 1)];
    if (tripDuration > 0)
    {
        [stringTimeMoving replaceCharactersInRange:NSMakeRange(2, 1) withAttributedString:timeMovingStringWithImage];
        [stringTimeMoving addAttribute:NSBaselineOffsetAttributeName value:[NSNumber numberWithFloat:-2.0] range:NSMakeRange(2, 1)];
    }
    
    [string appendAttributedString:stringDistance];
    [string appendAttributedString:stringWaypoints];
    if (stringTimeMoving)
        [string appendAttributedString:stringTimeMoving];
    
    [string addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, string.length)];
    
    [_statLabel setAttributedText:string];
    [_statLabel setTextColor:UIColorFromRGB(0x969696)];

}

- (void)setRightButtonTitle:(NSString *)title
{
    CGFloat w = [OAUtilities calculateTextBounds:title width:1000.0 font:self.rightButton.titleLabel.font].width + DESTINATION_CARD_BORDER * 2.0;
    self.rightButton.frame = CGRectMake(self.containerView.frame.size.width - w, self.rightButton.frame.origin.y, w, self.rightButton.frame.size.height);
    [self.rightButton setTitle:title forState:UIControlStateNormal];
    self.rightButton.hidden = NO;
    
    self.title.frame = CGRectMake(DESTINATION_CARD_BORDER, 0.0, self.rightButton.frame.origin.x - DESTINATION_CARD_BORDER * 2.0, 34.0);
}

@end
