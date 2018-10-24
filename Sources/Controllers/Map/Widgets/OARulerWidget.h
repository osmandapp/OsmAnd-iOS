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

@property (nonatomic, weak) id<OAWidgetListener> delegate;

@property (nonatomic) BOOL twoFingersDist;
@property (nonatomic) BOOL oneFingerDist;

@property (nonatomic, readonly) NSString *rulerDistance;

- (BOOL) updateInfo;

@end
