//
//  OATripRecordingElevationWidget.h
//  OsmAnd
//
//  Created by nnngrach on 04.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OASimpleWidget.h"

@interface OATripRecordingElevationWidget : OASimpleWidget

- (instancetype _Nonnull)initWithСustomId:(NSString *_Nullable)customId
                                  appMode:(OAApplicationMode * _Nonnull)appMode
                             widgetParams:(NSDictionary * _Nullable)widgetParams;

+ (NSString *) getName;
- (double) getElevationDiff;


@end


@interface OATripRecordingUphillWidget : OATripRecordingElevationWidget

@end


@interface OATripRecordingDownhillWidget : OATripRecordingElevationWidget

@end
