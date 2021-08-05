//
//  OADirectionTableViewCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 13/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OADirectionTableViewCell.h"

@implementation OADirectionTableViewCell

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (void) setTitle:(NSString *)title andDescription:(NSString *)description
{
    [_titleLabel setText:title];
    [_descLabel setText:description];
    
    if (description.length > 0)
    {
        _descIcon.hidden = NO;
        _titleLabelTopConstraint.constant = 6;
    }
    else
    {
        _descIcon.hidden = YES;
        _titleLabelTopConstraint.constant = 8;
    }
}

@end
