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

+ (instancetype)sharedInstanceWithPhrase:(OASearchPhrase *)phrase;

- (NSArray<NSString *> *)getOfflineIndexes:(OASearchPhrase *)phrase;
- (NSArray<NSString *> *)getOfflineIndexesWithMinRadius:(int)minRadius maxRadius:(int)maxRadius phrase:(OASearchPhrase *)phrase;
- (int)getRegionWeight:(NSString *)resourceId;

@end
