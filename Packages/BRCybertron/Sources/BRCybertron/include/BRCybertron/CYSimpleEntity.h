//
//  CYSimpleEntity.h
//  BRCybertron
//
//  Created by Matt on 8/03/16.
//  Copyright © 2016 Blue Rocket, Inc. Distributable under the terms of the MIT License.
//

#import "CYEntity.h"

@interface CYSimpleEntity : NSObject <CYEntity>

/**
 Initialize with a name and content.
 
 @param name    The entity name.
 @param content The entity content.
 
 @return The initialized instance.
 */
- (instancetype)initWithName:(NSString *)name content:(NSString *)content NS_DESIGNATED_INITIALIZER;

@end
