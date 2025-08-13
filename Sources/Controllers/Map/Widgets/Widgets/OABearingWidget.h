//
//  OABearingWidget.h
//  OsmAnd Maps
//
//  Created by Paul on 12.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OASimpleWidget.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, EOABearingType) {
    EOABearingTypeRelative = 0,
    EOABearingTypeMagnetic,
    EOABearingTypeTrue
};

@class OAGeomagneticField;

@interface OABearingWidget : OASimpleWidget

- (instancetype _Nonnull)initWithBearingType:(EOABearingType)bearingType
                           customId:(nullable NSString *)customId
                            appMode:(OAApplicationMode *)appMode
                       widgetParams:(nullable NSDictionary *)widgetParams;
- (int)getBearing;
- (nullable CLLocation *)getDestinationLocation;
- (int)getRelativeBearing:(CLLocation *)myLocation magneticBearingToDest:(float)magneticBearingToDest;
- (OAGeomagneticField *)getGeomagneticField:(CLLocation *)location;
- (BOOL)isAngularUnitsDepended;

@end

NS_ASSUME_NONNULL_END
