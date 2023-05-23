//
//  OARearrangeCustomFiltersViewController.h
//  OsmAnd
//
// Created by Skalii Dmitrii on 19.04.2021.
// Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

@class OAPOIUIFilter;

@interface OARearrangeCustomFiltersViewController : OABaseNavbarViewController

- (instancetype)initWithFilters:(NSArray<OAPOIUIFilter *> *)filters;

@end