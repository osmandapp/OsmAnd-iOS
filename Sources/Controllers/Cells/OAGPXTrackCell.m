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
#import "GeneratedAssetSymbols.h"

@implementation OAGPXTrackCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    _leftIconImageView.image = [UIImage imageNamed:ACImageNameIcCustomTrip];
    _distanceImageView.image = [UIImage imageNamed:ACImageNameIcCustomLength];
    _timeImageView.image = [UIImage templateImageNamed:ACImageNameIcSmallTimeStart];
    _wptImageView.image = [UIImage templateImageNamed:ACImageNameIcSmallWaypoints];
    
    _leftIconImageView.tintColor = [UIColor colorNamed:ACColorNameIconColorSelected];
    _distanceImageView.tintColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
    _timeImageView.tintColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
    _wptImageView.tintColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
    
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
