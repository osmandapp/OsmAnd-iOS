//
//  OrderedDictionary.h
//
//  Version 1.3
//
//  Created by Nick Lockwood on 21/09/2010.
//  Copyright 2010 Charcoal Design
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/OrderedDictionary
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Ordered subclass of NSDictionary.
 * Supports all the same methods as NSDictionary, plus a few
 * new methods for operating on entities by index rather than key.
 */
@interface OrderedDictionary<__covariant KeyType, __covariant ObjectType> : NSDictionary<KeyType, ObjectType>

/** Returns the nth key in the dictionary. */
- (KeyType)keyAtIndex:(NSUInteger)index;
/** Returns the nth object in the dictionary. */
- (ObjectType)objectAtIndex:(NSUInteger)index;
- (ObjectType)objectAtIndexedSubscript:(NSUInteger)index;
/** Returns the index of the specified key, or NSNotFound if key is not found. */
- (NSUInteger)indexOfKey:(KeyType)key;
/** Returns an enumerator for backwards traversal of the dictionary keys. */
- (NSEnumerator<KeyType> *)reverseKeyEnumerator;
/** Returns an enumerator for backwards traversal of the dictionary objects. */
- (NSEnumerator<ObjectType> *)reverseObjectEnumerator;
/** Enumerates keys ands objects with index using block. */
- (void)enumerateKeysAndObjectsWithIndexUsingBlock:(void (^)(KeyType key, ObjectType obj, NSUInteger idx, BOOL *stop))block;

@end


/**
 * Mutable subclass of OrderedDictionary.
 * Supports all the same methods as NSMutableDictionary, plus a few
 * new methods for operating on entities by index rather than key.
 * Note that although it has the same interface, MutableOrderedDictionary
 * is not a subclass of NSMutableDictionary, and cannot be used as one
 * without generating compiler warnings (unless you cast it).
 */
@interface MutableOrderedDictionary<KeyType, ObjectType> : OrderedDictionary<KeyType, ObjectType>

+ (instancetype)dictionaryWithCapacity:(NSUInteger)count;
- (instancetype)initWithCapacity:(NSUInteger)count;

- (void)addEntriesFromDictionary:(NSDictionary<KeyType, ObjectType> *)otherDictionary;
- (void)removeAllObjects;
- (void)removeObjectForKey:(KeyType)key;
- (void)removeObjectsForKeys:(NSArray<KeyType> *)keyArray;
- (void)setDictionary:(NSDictionary<KeyType, ObjectType> *)otherDictionary;
- (void)setObject:(ObjectType)object forKey:(KeyType)key;
- (void)setObject:(ObjectType)object forKeyedSubscript:(KeyType)key;

/** Inserts an object at a specific index in the dictionary. */
- (void)insertObject:(ObjectType)object forKey:(KeyType)key atIndex:(NSUInteger)index;
/** Replace an object at a specific index in the dictionary. */
- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(ObjectType)object;
- (void)setObject:(ObjectType)object atIndexedSubscript:(NSUInteger)index;
/** Swap the indexes of two key/value pairs in the dictionary. */
- (void)exchangeObjectAtIndex:(NSUInteger)idx1 withObjectAtIndex:(NSUInteger)idx2;
/** Removes the nth object in the dictionary. */
- (void)removeObjectAtIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END

