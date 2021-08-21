//
//  OADestinationsLineWidget.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 21.04.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OADestination.h"

@interface OADestinationsLineWidget : UIView <UIGestureRecognizerDelegate>

- (void) drawDestinationLineLayer:(CALayer *)layer inContext:(CGContextRef)ctx;
- (void) drawLineArrowWidget:(OADestination *)destination;
- (void) removeLineToDestinationPin:(OADestination *)destination;
- (BOOL) updateLayer;
- (BOOL) drawLayer;
- (double) getStrokeWidth;
- (BOOL) areAttributesChanged;

- (void) moveMarker:(NSInteger)index;

@end
