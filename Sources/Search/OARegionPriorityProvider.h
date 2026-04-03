//
//  OARegionPriorityProvider.h
//  OsmAnd
//
//  Created by Ivan Pyrohivskyi on 27.03.2026.
//  Copyright © 2026 OsmAnd. All rights reserved.
//


#import <Foundation/Foundation.h>

@class OASearchPhrase;

@interface OARegionPriorityProvider : NSObject

- (instancetype)initWithPhrase:(OASearchPhrase *)phrase;

- (NSArray<NSString *> *)getOfflineIndexes;
- (NSArray<NSString *> *)getOfflineIndexesWithMinRadius:(int)minRadius maxRadius:(int)maxRadius;
- (int)getRegionWeight:(NSString *)resourceId;

@end
