//
//  OAAtomicInteger.h
//  OsmAnd
//
//  Created by Alexey Kulish on 13/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAAtomicInteger : NSObject

+ (OAAtomicInteger *) atomicInteger:(int)value;
- (instancetype)initWithInteger:(int)value;

- (int) get;
- (void) set:(int)value;
- (int) getAndSet:(int)value;
- (void) compareAndSet:(int)value;
- (int) getAndAdd:(int)value;
- (int) addAndGet:(int)value;
- (int) getAndIncrement;
- (int) getAndDecrement;
- (int) incrementAndGet;
- (int) decrementAndGet;

@end
