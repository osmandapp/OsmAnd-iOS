//
//  OARulerByTapControlLayer.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 25.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OASymbolMapLayer.h"

@protocol OAWidgetListener;

@interface OARulerByTapControlLayer : OASymbolMapLayer

@end

@interface OARulerByTapView : UIView <UIGestureRecognizerDelegate>

@property (nonatomic, readonly) NSString *rulerDistance;
@property (nonatomic, weak) id<OAWidgetListener> delegate;

- (void) drawFingerRulerLayer:(CALayer *)layer inContext:(CGContextRef)ctx;
- (BOOL) updateLayer;

@end
