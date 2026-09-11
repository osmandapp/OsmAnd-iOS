//
//  OATargetInfoCollapsableCoordinatesViewCell.m
//  OsmAnd Maps
//
//  Created by nnngrach on 27.07.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OATargetInfoCollapsableCoordinatesViewCell.h"
#import "OACollapsableCoordinatesView.h"
#import "OAPointDescription.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OATargetInfoCollapsableCoordinatesViewCell

-(void) setupCellWithLat:(double)lat lon:(double)lon
{
    self.textView.text = [CoordinateFormatBridge formatPrimaryWithLat:lat lon:lon];
    self.textView.numberOfLines = 1;
    self.iconView.contentMode = UIViewContentModeScaleAspectFit;
    [self setImage:[UIImage imageNamed:@"ic_coordinates_location.png"]];
}

@end
