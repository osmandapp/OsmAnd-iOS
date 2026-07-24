//
//  MCBinaryHeap.h
//  MCBinaryHeap
//
//  Created by Matthew Cheok on 8/5/15.
//  Copyright (c) 2015 matthewcheok. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol MCBinaryHeapObject <NSObject>
- (NSComparisonResult)compare:(id)otherObject;
@end

@interface MCBinaryHeap : NSObject <NSCopying>

@property (nonatomic, readonly) NSUInteger count;

+ (instancetype)heap;
+ (instancetype)heapWithArray:(NSArray *)array;
+ (instancetype)heapWithHeap:(MCBinaryHeap *)heap;

- (instancetype)initWithArray:(NSArray *)array;
- (instancetype)initWithHeap:(MCBinaryHeap *)heap;

- (NSUInteger)countOfObject:(id)object;
- (BOOL)containsObject:(id)object;

- (id)minimumObject;
- (id)popMinimumObject;
- (void)addObject:(id<MCBinaryHeapObject>)object;
- (void)removeMinimumObject;
- (void)removeAllObjects;

- (void)enumerateObjectsUsingBlock:(void (^)(id object))block;

@end
