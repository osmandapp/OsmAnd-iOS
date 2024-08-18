//
//  OASunriseSunsetWidgetState.h
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 13.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAWidgetState.h"

NS_ASSUME_NONNULL_BEGIN

@class OACommonInteger, OAWidgetType;

@interface OASunriseSunsetWidgetState : OAWidgetState

@property (nonatomic, strong, nullable) NSString *customId;
@property (nonatomic, assign) BOOL lastIsDayTime;

- (instancetype)initWithWidgetType:(OAWidgetType *)widgetType
                                   customId:(nullable NSString *)customId;

- (OAWidgetType *)getWidgetType;
- (NSString *)getWidgetIconName;
- (OACommonInteger *)getPreference;
- (OACommonInteger *)getSunPositionPreference;

@end

NS_ASSUME_NONNULL_END
