//
//  OASunriseSunsetWidget.h
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 09.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OASimpleWidget.h"

@class OACommonInteger, OAApplicationMode, OASunriseSunsetWidgetState;

@interface OASunriseSunsetWidget : OASimpleWidget

- (instancetype _Nonnull)initWithState:(OASunriseSunsetWidgetState *_Nonnull)state
                      appMode:(OAApplicationMode * _Nonnull)appMode
                 widgetParams:(NSDictionary * _Nullable)widgetParams;

- (OACommonInteger *)getPreference;

@end
