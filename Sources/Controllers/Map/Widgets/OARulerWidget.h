//
//  OARulerWidget.h
//  OsmAnd
//
//  Created by Paul on 10/5/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OAWidgetListener;

@interface OARulerWidget : UIView <UIGestureRecognizerDelegate>

- (BOOL) updateInfo;
- (void) onMapSourceUpdated;

@end
