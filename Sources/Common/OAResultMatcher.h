//
//  OAResultMatcher.h
//  OsmAnd
//
//  Created by Alexey Kulish on 21/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Easy matcher to be able to publish results immediately
 *
 */
@interface OAResultMatcher<__covariant ObjectType> : NSObject

typedef BOOL(^OAResultMatcherPublish)(ObjectType * object);
@property (nonatomic) OAResultMatcherPublish publishFunction;

typedef BOOL(^OAResultMatcherIsCancelled)();
@property (nonatomic) OAResultMatcherIsCancelled cancelledFunction;

/**
 * @param name
 * @return true if result should be added to final list
 */
- (BOOL) publish:(ObjectType)object;

/**
 * @returns true to stop processing
 */
- (BOOL) isCancelled;

- (instancetype)initWithPublishFunc:(OAResultMatcherPublish)pFunction cancelledFunc:(OAResultMatcherIsCancelled)cFunction;

@end
