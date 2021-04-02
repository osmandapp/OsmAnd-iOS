//
//  OATopCoordinatesWidget.h
//  OsmAnd Maps
//
//  Created by nnngrach on 26.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OAWidgetListener;

@interface OATopCoordinatesWidget : UIView

@property (nonatomic, weak) id<OAWidgetListener> delegate;

- (BOOL) updateInfo;
- (BOOL) isVisible;

@end
