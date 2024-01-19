//
//  OATripRecordingDistanceWidget.h
//  OsmAnd
//
//  Created by nnngrach on 30.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OATextInfoWidget.h"

@class OAMonitoringPlugin;

@interface OATripRecordingDistanceWidget : OATextInfoWidget

- (instancetype _Nonnull)initWithPlugin:(OAMonitoringPlugin *)plugin
                               customId:(NSString *_Nullable)customId
                                appMode:(OAApplicationMode * _Nonnull)appMode;

+ (NSString *) getName;

@end
