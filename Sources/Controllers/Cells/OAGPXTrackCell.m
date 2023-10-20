//
//  OAGPXTrackCell.m
//  OsmAnd
//
//  Created by Anna Bibyk on 15.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAGPXTrackCell.h"
#import "OAUtilities.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OAGPXTrackCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    _leftIconImageView.image = [UIImage templateImageNamed:@"ic_custom_trip"];
    _distanceImageView.image = [UIImage templateImageNamed:@"ic_small_distance"];
    _timeImageView.image = [UIImage templateImageNamed:@"ic_small_time_start"];
    _wptImageView.image = [UIImage templateImageNamed:@"ic_small_waypoints"];
    
    _leftIconImageView.tintColor = UIColor.iconColorSelected;
    _distanceImageView.tintColor = UIColor.textColorSecondary;
    _timeImageView.tintColor = UIColor.textColorSecondary;
    _wptImageView.tintColor = UIColor.textColorSecondary;
    
    _separatorHeightConstraint.constant = 0.5;
    
    [self setRightButtonVisibility:NO];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void) setRightButtonVisibility:(BOOL)visible
{
    _editButton.hidden = !visible;
    if (visible)
    {
        _titleRelativeToMarginConstraint.active = NO;
        _titleRelativeToButtonConstraint.active = YES;
        
        _buttonFullWidthConstraint.active = YES;
        _buttonHiddenWidthConstraint.active = NO;
    }
    else
    {
        _titleRelativeToMarginConstraint.active = YES;
        _titleRelativeToButtonConstraint.active = NO;
        
        _buttonFullWidthConstraint.active = NO;
        _buttonHiddenWidthConstraint.active = YES;
    }
    
    [self setNeedsUpdateConstraints];
    [self updateConstraintsIfNeeded];
}

@end
