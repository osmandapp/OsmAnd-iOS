//
//  OACustomPOIViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 27/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OABaseButtonsViewController.h"

@class OAPOIUIFilter;
@class OAPOIType;

@protocol OAPOIFilterViewDelegate;
@protocol OAPOIFilterRefreshDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface OACustomPOIViewController : OABaseButtonsViewController

@property (weak, nonatomic) id<OAPOIFilterViewDelegate> delegate;
@property (weak, nonatomic, nullable) id<OAPOIFilterRefreshDelegate> refreshDelegate;

- (instancetype)initWithFilter:(OAPOIUIFilter *)filter;

@end

NS_ASSUME_NONNULL_END

