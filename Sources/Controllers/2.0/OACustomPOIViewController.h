//
//  OACustomPOIViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 27/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

@class OAPOIUIFilter;

@protocol OACustomPOIViewDelegate

@required

- (void) searchByUIFilter:(OAPOIUIFilter *)filter;

@end

@interface OACustomPOIViewController : OACompoundViewController

@property (weak, nonatomic) id<OACustomPOIViewDelegate> delegate;

- (instancetype)initWithFilter:(OAPOIUIFilter *)filter;

@end
