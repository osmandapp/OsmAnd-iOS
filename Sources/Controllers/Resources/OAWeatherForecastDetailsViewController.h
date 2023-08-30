//
//  OAWeatherForecastDetailsViewController.h
//  OsmAnd
//
//  Created by Skalii on 05.08.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

@class OAWorldRegion, OAResourceItem;

@protocol OAWeatherForecastDetails <NSObject>

@required

- (void)onRemoveForecast;
- (void)onUpdateForecast;
- (void)onClearForecastCache;

@end

@interface OAWeatherForecastDetailsViewController : OABaseNavbarViewController

- (instancetype)initWithRegion:(OAWorldRegion *)region localResourceItem:(OAResourceItem *)item;

@property (nonatomic, weak) id<OAWeatherForecastDetails> delegate;

@end
