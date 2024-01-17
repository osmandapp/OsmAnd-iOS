//
//  OAWeatherWidget.h
//  OsmAnd Maps
//
//  Created by Paul on 08.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OASimpleWidget.h"
#import "OAWeatherBand.h"

NS_ASSUME_NONNULL_BEGIN

@class OAWidgetType;

@interface OAWeatherWidget : OASimpleWidget

- (instancetype) initWithType:(OAWidgetType *)type band:(EOAWeatherBand)band;

@end

NS_ASSUME_NONNULL_END
