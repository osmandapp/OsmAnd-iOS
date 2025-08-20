//
//  OAZoomLevelWidget.h
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 03.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OASimpleWidget.h"

@class ZoomLevelWidgetState;

NS_ASSUME_NONNULL_BEGIN

@interface OAZoomLevelWidget : OASimpleWidget

- (instancetype)initWithСustomId:(NSString * _Nullable)customId
                         appMode:(OAApplicationMode *)appMode
                     widgetState:(ZoomLevelWidgetState *)widgetState
                    widgetParams:(NSDictionary * _Nullable)widgetParams;

@end

NS_ASSUME_NONNULL_END

