//
//  OAPOIAdapter.h
//  OsmAnd
//
//  Created by nnngrach on 11.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

@interface OAPOIAdapter : NSObject

@property (nonatomic) id object;

- (NSString *) name;
- (void) setName:(NSString *)name;

- (double) latitude;
- (void) setLatitude:(double)latitude;
- (double) longitude;
- (void) setLongitude:(double)longitude;

@end
