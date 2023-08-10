//
//  OATravelObfHelperBridge.h
//  OsmAnd
//
//  Created by nnngrach on 08.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

@class OAWptPt, OAPOI;


@interface OATravelObfHelperBridge : NSObject

+ (void) foo:(double)lat lon:(double)lon;

+ (OAWptPt *) createWptPt:(OAPOI *)amenity lang:(NSString *)lang;

@end
