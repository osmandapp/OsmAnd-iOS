//
//  OACollectionViewCellState.h
//  OsmAnd Maps
//
//  Created by nnngrach on 20.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OACollectionViewCellState : NSObject

- (BOOL) containsValueForIndex:(NSIndexPath *)index;
- (CGPoint) getOffsetForIndex:(NSIndexPath *)index;
- (void) setOffset:(CGPoint)offset forIndex:(NSIndexPath *)index;

@end
