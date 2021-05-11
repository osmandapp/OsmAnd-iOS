//
//  OAGPXRouteWaypointTableViewCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 09/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXRouteWaypointTableViewCell.h"

@implementation OAGPXRouteWaypointTableViewCell

+ (NSString *) getCellIdentifier
{
    return @"OAGPXRouteWaypointTableViewCell";
}

- (void)awakeFromNib {
    // Initialization code
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)hideVDots:(BOOL)hide
{
    if (hide)
    {
        self.vDotsTop.hidden = YES;
        self.vDotsBottom.hidden = YES;
        
        self.vDotsTopHeightHidden.active = YES;
        self.vDotsBottomHeightHidden.active = YES;
        
        self.vDostTopHeightVisible.active = NO;
        self.vDotsBottomHeightVisible.active = NO;
    }
    else
    {
        self.vDotsTop.hidden = !self.topVDotsVisible;
        self.vDotsBottom.hidden = !self.bottomVDotsVisible;
        
        self.vDotsTopHeightHidden.active = !self.topVDotsVisible;
        self.vDotsBottomHeightHidden.active = !self.bottomVDotsVisible;
        
        self.vDostTopHeightVisible.active = self.topVDotsVisible;
        self.vDotsBottomHeightVisible.active = self.bottomVDotsVisible;
    }
    
    [self setNeedsUpdateConstraints];
    [self updateFocusIfNeeded];
}

- (void)hideDescIcon:(BOOL)hide
{
    self.descIcon.hidden = hide;
    
    self.descIconWidthHidden.active = hide;
    self.descIconWidthVisible.active = !hide;
    
    [self setNeedsUpdateConstraints];
    [self updateFocusIfNeeded];
}

- (void)hideRightButton:(BOOL)hide
{
    if (self.rightButton.hidden == hide)
        return;
    
    self.rightButton.hidden = hide;
    
    self.titleTrailingButtonHidden.active = hide;
    self.titleTrailingButtonVisible.active = !hide;
    
    [self setNeedsUpdateConstraints];
    [self updateFocusIfNeeded];
}

@end
