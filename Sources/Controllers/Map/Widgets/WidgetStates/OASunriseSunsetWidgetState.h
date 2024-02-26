//
//  OASunriseSunsetWidgetState.h
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 13.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAWidgetState.h"


@class OACommonInteger, OAWidgetType;

@interface OASunriseSunsetWidgetState : OAWidgetState

@property (nonatomic, strong, nullable) NSString *customId;

- (instancetype _Nonnull)initWithWidgetType:(OAWidgetType *_Nonnull)widgetType
                                   customId:(NSString *_Nullable)customId;

- (OAWidgetType *_Nonnull)getWidgetType;

- (BOOL)isSunriseMode;
- (OACommonInteger *)getPreference;
- (OACommonInteger *_Nonnull)getSunPositionPreference;

@end
