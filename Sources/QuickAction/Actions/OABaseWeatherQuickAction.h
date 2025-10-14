//
//  OABaseWeatherQuickAction.h
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 14.10.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAQuickAction.h"
#import "OAWeatherBand.h"

@interface OABaseWeatherQuickAction : OAQuickAction

- (EOAWeatherBand)weatherBandIndex;

@end
