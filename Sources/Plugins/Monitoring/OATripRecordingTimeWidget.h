//
//  OATripRecordingTimeWidget.h
//  OsmAnd
//
//  Created by nnngrach on 02.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OASimpleWidget.h"

@class OAMonitoringPlugin;

@interface OATripRecordingTimeWidget : OASimpleWidget

- (instancetype _Nonnull)initWithСustomId:(NSString *_Nullable)customId
                                  appMode:(OAApplicationMode * _Nonnull)appMode;

+ (NSString *)getName;

@end
