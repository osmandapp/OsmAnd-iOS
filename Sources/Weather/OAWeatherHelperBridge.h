//
//  OAWeatherHelperBridge.h
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 15.10.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAWeatherBand.h"

@interface OAWeatherHelperBridge : NSObject

+ (OAWeatherBand * _Nullable)weatherBandForIndex:(EOAWeatherBand)bandIndex;
+ (BOOL)allLayersAreDisabled;

@end
