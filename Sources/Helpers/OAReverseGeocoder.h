//
//  OAGeocoder.h
//  OsmAnd
//
//  Created by Alexey Kulish on 18/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAReverseGeocoder : NSObject

+ (OAReverseGeocoder *)instance;

- (NSString *) lookupAddressAtLat:(double)lat lon:(double)lon;

@end
