//
//  OAWeatherWidget.h
//  OsmAnd Maps
//
//  Created by Paul on 08.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OATextInfoWidget.h"
#import "OAWeatherBand.h"

NS_ASSUME_NONNULL_BEGIN

@class OAWidgetType;

@interface OAWeatherWidget : OATextInfoWidget

- (instancetype) initWithType:(OAWidgetType *)type band:(EOAWeatherBand)band;

@end

NS_ASSUME_NONNULL_END
