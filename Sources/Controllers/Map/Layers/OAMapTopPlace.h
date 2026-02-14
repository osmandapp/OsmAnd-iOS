//
//  OAMapTopPlace.h
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 17.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#include <OsmAndCore.h>
#include <OsmAndCore/PointsAndAreas.h>

NS_ASSUME_NONNULL_BEGIN

@interface OAMapTopPlace : NSObject

@property (nonatomic, readonly) int32_t placeId;
@property (nonatomic, assign) OsmAnd::PointI position;
@property (nonatomic, readonly, nullable) UIImage *image;
@property (nonatomic, readonly) BOOL alreadyExists;

- (instancetype)initWithPlaceId:(int32_t)placeId
                       position:(const OsmAnd::PointI &)position
                          image:(nullable UIImage *)image
                  alreadyExists:(BOOL)alreadyExists NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
