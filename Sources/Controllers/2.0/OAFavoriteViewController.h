//
//  OAFavoriteViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 01/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAEditTargetViewController.h"
#import "OAFavoriteItem.h"
#import <CoreLocation/CoreLocation.h>

@interface OAFavoriteViewController : OAEditTargetViewController

@property (nonatomic) OAFavoriteItem *favorite;
- (id) initWithItem:(OAFavoriteItem *)favorite headerOnly:(BOOL)headerOnly;
- (id) initWithLocation:(CLLocationCoordinate2D)location andTitle:(NSString *)formattedLocation headerOnly:(BOOL)headerOnly;

- (UIImage *) getBackgroundIcon;

@end
