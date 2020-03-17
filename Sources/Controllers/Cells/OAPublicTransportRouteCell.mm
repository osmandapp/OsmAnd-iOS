//
//  OAPublicTransportRouteCell.m
//  OsmAnd
//
//  Created by Paul on 13/03/2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAPublicTransportRouteCell.h"
#import "OAUtilities.h"
#import "Localization.h"

@implementation OAPublicTransportRouteCell

- (void) awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
    _detailsButton.layer.cornerRadius = 6.;
    _showOnMapButton.layer.cornerRadius = 6.;
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

@end
