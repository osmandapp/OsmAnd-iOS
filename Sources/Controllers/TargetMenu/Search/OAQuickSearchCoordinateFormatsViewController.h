//
//  OAQuickSearchCoordinateFormatsViewController.h
//  OsmAnd
//
//  Created by nnngrach on 25.08.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseTableViewController.h"
#import <CoreLocation/CoreLocation.h>

@protocol OAQuickSearchCoordinateFormatsDelegate <NSObject>

@required

- (void) onCoordinateFormatChanged:(NSInteger)currentFormat;

@end


@interface OAQuickSearchCoordinateFormatsViewController : OABaseTableViewController

@property (nonatomic, weak) id<OAQuickSearchCoordinateFormatsDelegate> delegate;

- (instancetype) initWithCurrentFormat:(NSInteger)currentFormat location:(CLLocation *)location;

@end
