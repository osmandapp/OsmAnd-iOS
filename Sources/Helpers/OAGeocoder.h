//
//  OAGeocoder.h
//  OsmAnd
//
//  Created by Alexey Kulish on 18/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAGeocoder : NSObject

+ (OAGeocoder *)instance;

- (NSString *) geocodeLat:(double)lat lon:(double)lon;

@end
