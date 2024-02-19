//
//  OAAutoZoomBySpeedHelper.h
//  OsmAnd
//
//  Created by Max Kojin on 14/02/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

const static float kZoomPerSecond = 0.1;
const static float kZoomPerMillis = kZoomPerSecond / 1000.0;
const static int kZoomDurationMillis = 1500;

@interface OAAutoZoomBySpeedHelper : NSObject

@end
