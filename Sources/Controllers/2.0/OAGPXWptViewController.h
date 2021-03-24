//
//  OAGPXWptViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 08/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAEditTargetViewController.h"
#import "OAGpxWptItem.h"
#import <CoreLocation/CoreLocation.h>


@protocol OAGPXWptViewControllerDelegate <NSObject>

@optional
- (void)changedWptItem;

@end


@class OAMapViewController;

@interface OAGPXWptViewController : OAEditTargetViewController

@property (nonatomic) OAMapViewController *mapViewController;
@property (nonatomic) OAGpxWptItem *wpt;

@property (nonatomic, weak) id<OAGPXWptViewControllerDelegate> wptDelegate;

- (id) initWithItem:(OAGpxWptItem *)wpt headerOnly:(BOOL)headerOnly;
- (id) initWithLocation:(CLLocationCoordinate2D)location andTitle:(NSString *)formattedLocation gpxFileName:(NSString *)gpxFileName;
- (NSString *) getGpxFileName;

@end
