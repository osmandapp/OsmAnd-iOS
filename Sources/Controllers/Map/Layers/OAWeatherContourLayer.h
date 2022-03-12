//
//  OAWeatherContourLayer.h
//  OsmAnd Maps
//
//  Created by Alexey on 11.03.2022.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OARasterMapLayer.h"

@interface OAWeatherContourLayer : OARasterMapLayer

@property (nonatomic, readonly) NSDate *date;

- (instancetype) initWithMapViewController:(OAMapViewController *)mapViewController layerIndex:(int)layerIndex date:(NSDate *)date;

- (void) updateDate:(NSDate *)date;

@end
