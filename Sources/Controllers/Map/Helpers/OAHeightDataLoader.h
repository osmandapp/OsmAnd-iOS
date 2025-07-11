//
//  OAHeightDataLoader.h
//  OsmAnd
//
//  Created by Max Kojin on 15/06/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN


@class OASKQuadRect, OASWptPt;

@interface OAHeightDataLoader: NSObject

- (NSMutableArray<OASWptPt *> * _Nullable) loadHeightDataAsWaypoints:(int64_t)osmId bbox31:(OASKQuadRect *)bbox31;

@end


NS_ASSUME_NONNULL_END
