//
//  OAZoomLevelWidget.h
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 03.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OASimpleWidget.h"

@class ZoomLevelWidgetState;

@interface OAZoomLevelWidget : OASimpleWidget

- (instancetype _Nonnull)initWithСustomId:(NSString *_Nullable)customId
                                  appMode:(OAApplicationMode * _Nonnull)appMode
                     widgetState:(ZoomLevelWidgetState *_Nonnull)widgetState
                             widgetParams:(NSDictionary * _Nullable)widgetParams;

@end
