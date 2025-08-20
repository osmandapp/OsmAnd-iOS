//
//  OATripRecordingTimeWidget.h
//  OsmAnd
//
//  Created by nnngrach on 02.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OASimpleWidget.h"

NS_ASSUME_NONNULL_BEGIN

@class OAMonitoringPlugin;

@interface OATripRecordingTimeWidget : OASimpleWidget

- (instancetype _Nonnull)initWithСustomId:(NSString *_Nullable)customId
                                  appMode:(OAApplicationMode * _Nonnull)appMode
                             widgetParams:(NSDictionary * _Nullable)widgetParams;

+ (NSString *)getName;

@end

NS_ASSUME_NONNULL_END
