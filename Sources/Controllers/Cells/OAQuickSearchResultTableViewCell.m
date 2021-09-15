//
//  OAQuickSearchResultTableViewCell.m
//  OsmAnd
//
//  Created by nnngrach on 6/09/21.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAQuickSearchResultTableViewCell.h"

@implementation OAQuickSearchResultTableViewCell

- (void) setDesriptionLablesVisible:(BOOL)isVisible;
{
    if (isVisible)
    {
        _directionIcon.hidden = NO;
        _distanceLabel.hidden = NO;
        _coordinateLabel.hidden = NO;
        _titleLabelTopConstraint.constant = 9;
    }
    else
    {
        _directionIcon.hidden = YES;
        _distanceLabel.hidden = YES;
        _coordinateLabel.hidden = YES;
        _titleLabelTopConstraint.constant = 20;
    }
}

@end
