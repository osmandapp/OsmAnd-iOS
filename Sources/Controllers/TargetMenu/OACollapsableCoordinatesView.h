//
//  OACollapsableCoordinatesView.h
//  OsmAnd
//
//  Created by Paul on 07/1/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OACollapsableView.h"

@class OAPOI;
@class FormattedCoordinateItem;

@interface OACollapsableCoordinatesView : OACollapsableView

@property (nonatomic, readonly) double lat;
@property (nonatomic, readonly) double lon;
@property (nonatomic, readonly) NSArray<FormattedCoordinateItem *> *coordinates;

- (instancetype) initWithFrame:(CGRect)frame lat:(double)lat lon:(double)lon;

@end
