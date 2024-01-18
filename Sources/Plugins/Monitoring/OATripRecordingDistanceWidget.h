//
//  OATripRecordingDistanceWidget.h
//  OsmAnd
//
//  Created by nnngrach on 30.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OASimpleWidget.h"

@class OAMonitoringPlugin;

@interface OATripRecordingDistanceWidget : OASimpleWidget

- (instancetype) initWithPlugin:(OAMonitoringPlugin *)plugin;

+ (NSString *) getName;

@end
