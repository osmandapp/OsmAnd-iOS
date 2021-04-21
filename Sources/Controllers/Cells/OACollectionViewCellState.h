//
//  OACollectionViewCellState.h
//  OsmAnd Maps
//
//  Created by nnngrach on 20.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OACollectionViewCellState : NSObject

- (BOOL) containsValueForKey:(NSString *)key;
- (CGPoint) getOffsetForKey:(NSString *)key;
- (void) setOffset:(CGPoint)offset forKey:(NSString *)key;

@end
