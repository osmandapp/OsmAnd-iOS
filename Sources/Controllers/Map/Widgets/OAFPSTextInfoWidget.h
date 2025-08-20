//
//  OAFPSTextInfoWidget.h
//  OsmAnd
//
//  Created by nnngrach on 19.10.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OASimpleWidget.h"

NS_ASSUME_NONNULL_BEGIN

@interface OAFPSTextInfoWidget : OASimpleWidget

- (instancetype)initWithСustomId:(NSString * _Nullable)customId
                          appMode:(OAApplicationMode *)appMode
                     widgetParams:(NSDictionary * _Nullable)widgetParams;

@end

NS_ASSUME_NONNULL_END

