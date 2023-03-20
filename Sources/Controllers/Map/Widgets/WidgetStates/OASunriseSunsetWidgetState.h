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

- (instancetype) initWithType:(BOOL)sunriseMode customId:(NSString *)customId;
- (BOOL) isSunriseMode;
- (OACommonInteger *) getPreference;

@end
