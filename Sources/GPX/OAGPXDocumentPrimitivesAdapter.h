//
//  OAGPXDocumentPrimitivesAdapter.h
//  OsmAnd
//
//  Created by nnngrach on 11.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//


@interface OAWptPtAdapter : NSObject

@property (nonatomic) id object;

- (CLLocationCoordinate2D) position;
- (void) setPosition:(CLLocationCoordinate2D)position;

- (NSString *) name;
- (void) setName:(NSString *)name;

@end
