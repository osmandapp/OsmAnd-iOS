//
//  OARouteInfoAltitudeCell.m
//  OsmAnd
//
//  Created by Paul on 17.12.2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OARouteInfoAltitudeCell.h"

@implementation OARouteInfoAltitudeCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    if ([self isDirectionRTL])
    {
        [_ascentIcon setImage:_ascentIcon.image.imageFlippedForRightToLeftLayoutDirection];
        [_descentIcon setImage:_descentIcon.image.imageFlippedForRightToLeftLayoutDirection];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
