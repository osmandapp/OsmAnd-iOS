//
//  OAGPXRouteTableViewCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 08/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXRouteTableViewCell.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OAGPXRouter.h"

@implementation OAGPXRouteTableViewCell

+ (NSString *) getCellIdentifier
{
    return @"OAGPXRouteTableViewCell";
}

- (void)awakeFromNib {
    // Initialization code
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) setDistance:(double)distance wptCount:(NSInteger)wptCount tripDuration:(NSTimeInterval)tripDuration
{
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] init];
    UIFont *font = [UIFont systemFontOfSize:11];
    
    NSMutableString *distanceStr = [[[OsmAndApp instance] getFormattedDistance:distance] mutableCopy];
    NSString *waypointsStr = [NSString stringWithFormat:@"%d", (int) wptCount];
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
    
    [_detailsView setAttributedText:string];
    //[_detailsView setTextColor:UIColorFromRGB(0x969696)];
    
    
}

@end
