//
//  OARouteInfoCell.m
//  OsmAnd
//
//  Created by Paul on 17.12.2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OARouteInfoCell.h"
#import "OAColors.h"
#import <Charts/Charts-Swift.h>

@implementation OARouteInfoCell
{
    BOOL _showLegend;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    _showLegend = NO;
    [_expandImageView setImage:[UIImage templateImageNamed:@"ic_custom_arrow_down.png"]];
    [_expandImageView setTintColor:UIColorFromRGB(color_primary_purple)];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) onDetailsPressed
{
    _showLegend = !_showLegend;
    
    [_expandImageView setImage:[UIImage templateImageNamed:(_showLegend ? @"ic_custom_arrow_up.png" : @"ic_custom_arrow_down.png")]];
}


@end
