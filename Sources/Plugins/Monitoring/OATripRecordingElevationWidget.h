//
//  OATripRecordingElevationWidget.h
//  OsmAnd
//
//  Created by nnngrach on 04.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OATextInfoWidget.h"

@interface OATripRecordingElevationWidget : OATextInfoWidget

- (instancetype _Nonnull)initWithСustomId:(NSString *_Nullable)customId
                                  appMode:(OAApplicationMode * _Nonnull)appMode;


+ (NSString *) getName;
- (double) getElevationDiff;


@end


@interface OATripRecordingUphillWidget : OATripRecordingElevationWidget

@end


@interface OATripRecordingDownhillWidget : OATripRecordingElevationWidget

@end
