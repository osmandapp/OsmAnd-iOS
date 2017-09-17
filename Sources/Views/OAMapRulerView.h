//
//  OAMapRulerView.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 19.10.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#define kMapRulerMinWidth 60
#define kMapRulerMaxWidth 120

@interface OAMapRulerView : UIView

- (BOOL) hasNoData;
- (void) updateColors;
- (void) setRulerData:(float) metersPerPixel;

@end
