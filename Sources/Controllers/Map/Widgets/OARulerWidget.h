//
//  OARulerWidget.h
//  OsmAnd
//
//  Created by Paul on 10/5/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OABaseWidgetView.h"

@interface OARulerWidget : OABaseWidgetView <UIGestureRecognizerDelegate>

- (void) onMapSourceUpdated;

@end
