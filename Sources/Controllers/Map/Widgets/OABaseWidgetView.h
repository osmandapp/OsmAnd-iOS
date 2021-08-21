//
//  OABaseWidgetView.h
//  OsmAnd Maps
//
//  Created by Paul on 20.08.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OABaseWidgetView;

@protocol OAWidgetListener <NSObject>

@required
- (void) widgetChanged:(OABaseWidgetView *)widget;
- (void) widgetVisibilityChanged:(OABaseWidgetView *)widget visible:(BOOL)visible;
- (void) widgetClicked:(OABaseWidgetView *)widget;

@end

@protocol OAWidgetListener;

@interface OABaseWidgetView : UIView

@property (nonatomic, weak) id<OAWidgetListener> delegate;

- (BOOL) updateInfo;
- (BOOL) isTopText;

@end

