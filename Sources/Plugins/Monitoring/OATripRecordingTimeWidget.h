//
//  OATripRecordingTimeWidget.h
//  OsmAnd
//
//  Created by nnngrach on 02.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OATextInfoWidget.h"

@class OAMonitoringPlugin;

@interface OATripRecordingTimeWidget : OATextInfoWidget

- (instancetype _Nonnull)initWithСustomId:(NSString *_Nullable)customId
                                  appMode:(OAApplicationMode * _Nonnull)appMode;

+ (NSString *)getName;

@end
