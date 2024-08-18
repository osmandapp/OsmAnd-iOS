//
//  OAConcurrentCollectionsExtensions.h
//  OsmAnd Maps
//
//  Created by Paul on 11.07.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAConcurrentArray<ObjectType> : NSObject

- (void)addObjectSync:(id)anObject;
- (void)addObjectsSync:(NSArray *)anArray;
- (void)insertObjectSync:(id)anObject atIndex:(NSUInteger)index;
- (void)replaceObjectAtIndexSync:(NSUInteger)index withObject:(id)anObject;
- (void)replaceAllWithObjectsSync:(NSArray *)anArray;
- (void)removeObjectSync:(id)anObject;
- (void)removeObjectAtIndexSync:(NSUInteger)index;
- (void)removeAllObjectsSync;
- (id)objectAtIndexSync:(NSUInteger)index;
- (NSUInteger)indexOfObjectSync:(id)anObject;
- (NSUInteger)countSync;
- (id)firstObjectSync;
- (id)lastObjectSync;
- (BOOL)containsObjectSync:(id)anObject;

- (NSArray *) asArray;

@end

@interface OAConcurrentDictionary<KeyType, ObjectType> : NSObject

- (void)setObjectSync:(id)anObject forKey:(id<NSCopying>)aKey;
- (void)removeObjectForKeySync:(id)aKey;
- (void)removeAllObjectsSync;
- (id)objectForKeySync:(id)aKey;

- (NSUInteger)countSync;

- (NSDictionary *) asDictionary;

@end

@interface OAConcurrentSet<ObjectType> : NSObject

- (void)addObjectSync:(id)anObject;
- (void)removeObjectSync:(id)anObject;
- (void)removeAllObjectsSync;
- (NSUInteger)countSync;
- (BOOL)containsObjectSync:(id)anObject;

@end

