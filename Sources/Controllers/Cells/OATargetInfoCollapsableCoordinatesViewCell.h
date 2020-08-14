//
//  OATargetInfoCollapsableCoordinatesViewCell.h
//  OsmAnd
//
//  Created by nnngrach on 27.07.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OATargetInfoCollapsableViewCell.h"

@class OACollapsableView;

@interface OATargetInfoCollapsableCoordinatesViewCell : OATargetInfoCollapsableViewCell

-(void) setupCellWithLat:(double)lat lon:(double)lon;

@end
