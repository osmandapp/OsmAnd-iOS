//
//  CYEntityResolver.h
//  Pods
//
//  Created by Matt on 8/03/16.
//
//

#import <Foundation/Foundation.h>

#import "CYEntity.h"

@class CYParsingContext;

NS_ASSUME_NONNULL_BEGIN

/**
 API for an entity resolver.
 */
@protocol CYEntityResolver <NSObject>

/**
 Resolve an entity based on the name referenced in the input XML.
 
 @param name    The name of the referenced entity to resolve.
 @param context The parsing context the entity was found in.
 
 @return The resolved entity, or @c nil if not found.
 */
- (nullable id<CYEntity>)resolveEntity:(NSString *)name context:(CYParsingContext *)context;

@end

NS_ASSUME_NONNULL_END
