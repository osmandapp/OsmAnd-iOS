//
//  OAMapUtils.h
//  OsmAnd
//
//  Created by Alexey Kulish on 21/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAPOI;

@interface OAMapUtils : NSObject

+ (NSArray<OAPOI *> *) sortPOI:(NSArray<OAPOI *> *)array lat:(double)lat lon:(double)lon;

@end
