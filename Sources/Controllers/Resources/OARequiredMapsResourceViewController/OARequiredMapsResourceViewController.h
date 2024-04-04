//
//  OARequiredMapsResourceViewController.h
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 02.04.2024.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABaseButtonsViewController.h"

@class OAWorldRegion;

NS_ASSUME_NONNULL_BEGIN

@interface OARequiredMapsResourceViewController : OABaseButtonsViewController

- (instancetype)initWithWorldRegion:(NSArray<OAWorldRegion *> *)missingMaps
                       mapsToUpdate:(NSArray<OAWorldRegion *> *)mapsToUpdate
                potentiallyUsedMaps:(NSArray<OAWorldRegion *> *)potentiallyUsedMaps;
@end
NS_ASSUME_NONNULL_END
