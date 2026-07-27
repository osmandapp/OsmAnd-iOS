//
//  CYEntity.h
//  BRCybertron
//
//  Created by Matt on 8/03/16.
//  Copyright © 2016 Blue Rocket, Inc. Distributable under the terms of the MIT License.
//

#import <Foundation/Foundation.h>
#import <libxml/tree.h>

NS_ASSUME_NONNULL_BEGIN

/**
 API for an entity declaration.
 */
@protocol CYEntity <NSObject>

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly, nullable) NSString *externalID;
@property (nonatomic, readonly, nullable) NSString *systemID;
@property (nonatomic, readonly) NSString *content;

/**
 Get a detached xmlEntityPtr based on the receiver.
 
 @param error If a problem occurs creating the entity, this will be set to an error. Pass @c nil if you don't need the error.
 
 @return The entity, or @c NULL if an error occurs.
 */
- (nullable xmlEntityPtr)getEntity:(NSError **)error NS_RETURNS_INNER_POINTER;

@end

NS_ASSUME_NONNULL_END
