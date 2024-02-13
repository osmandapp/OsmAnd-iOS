//
//  OASunriseSunsetWidgetState.h
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 13.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAWidgetState.h"

@class OACommonInteger;

@interface OASunriseSunsetWidgetState : OAWidgetState

@property (nonatomic, strong, nullable) NSString *customId;

- (instancetype _Nonnull)initWithType:(BOOL)sunriseMode customId:(NSString *_Nullable)customId;
- (BOOL)isSunriseMode;
- (OACommonInteger *)getPreference;

@end
