//
//  OAHeightDataLoader.h
//  OsmAnd
//
//  Created by Max Kojin on 15/06/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@class OASKQuadRect, OASWptPt;

@interface OAHeightDataLoader: NSObject

- (NSMutableArray<OASWptPt *> *) loadHeightDataAsWaypoints:(int64_t)osmId bbox31:(OASKQuadRect *)bbox31;

@end
