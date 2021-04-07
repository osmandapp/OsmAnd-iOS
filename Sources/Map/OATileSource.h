//
//  OATileSource.h
//  OsmAnd
//
//  Created by Paul on 01.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#include <CommonCollections.h>
#include <commonOsmAndCore.h>
#include <OsmAndCore/Map/IOnlineTileSources.h>

NS_ASSUME_NONNULL_BEGIN


@interface OATileSource : NSObject

@property (nonatomic, readonly) BOOL isSql;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *title;
@property (nonatomic, readonly) int minZoom;
@property (nonatomic, readonly) int maxZoom;
@property (nonatomic, readonly) NSString *url;
@property (nonatomic, readonly) NSString *randoms;
@property (nonatomic, readonly) BOOL ellipsoid;
@property (nonatomic, readonly) BOOL invertedY;
@property (nonatomic, readonly) NSString *referer;
@property (nonatomic, readonly) BOOL timesupported;
@property (nonatomic, readonly) long expire;
@property (nonatomic, readonly) BOOL inversiveZoom;
@property (nonatomic, readonly) NSString *ext;
@property (nonatomic, readonly) int tileSize;
@property (nonatomic, readonly) int bitDensity;
@property (nonatomic, readonly) int avgSize;
@property (nonatomic, readonly) NSString *rule;

+ (instancetype) tileSourceWithParameters:(NSDictionary *)params;

- (instancetype) initFromTileSource:(OATileSource *)other newName:(NSString *)newName;

- (NSDictionary *) toSqlParams;
- (std::shared_ptr<OsmAnd::IOnlineTileSources::Source>) toOnlineTileSource;

@end

NS_ASSUME_NONNULL_END
