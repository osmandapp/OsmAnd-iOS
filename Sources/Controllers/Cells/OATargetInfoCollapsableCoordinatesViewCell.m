//
//  OATargetInfoCollapsableCoordinatesViewCell.m
//  OsmAnd Maps
//
//  Created by nnngrach on 27.07.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OATargetInfoCollapsableCoordinatesViewCell.h"
#import "OACollapsableView.h"
#import "OACollapsableCoordinatesView.h"
#import "OAPointDescription.h"

@implementation OATargetInfoCollapsableCoordinatesViewCell

+ (NSString *) getCellIdentifier
{
    return @"OATargetInfoCollapsableCoordinatesViewCell";
}

-(void) setupCellWithLat:(double)lat lon:(double)lon
{
    self.textView.text = [OAPointDescription getLocationName:lat lon:lon sh:YES];
    self.textView.numberOfLines = 1;
    self.iconView.contentMode = UIViewContentModeScaleAspectFit;
    [self setImage:[UIImage imageNamed:@"ic_coordinates_location.png"]];
}

@end
