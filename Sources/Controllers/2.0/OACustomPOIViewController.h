//
//  OACustomPOIViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 27/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

@class OAPOIUIFilter;
@class OAPOIType;

@protocol OAPOIFilterViewDelegate;
@protocol OAPOIFilterRefreshDelegate;

@interface OACustomPOIViewController : OACompoundViewController

@property (weak, nonatomic) id<OAPOIFilterViewDelegate> delegate;
@property (weak, nonatomic) id<OAPOIFilterRefreshDelegate> _Nullable refreshDelegate;

- (instancetype)initWithFilter:(OAPOIUIFilter *)filter;

@end
