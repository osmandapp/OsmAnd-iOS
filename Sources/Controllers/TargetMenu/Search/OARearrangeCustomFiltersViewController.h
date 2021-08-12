//
//  OARearrangeCustomFiltersViewController.h
//  OsmAnd
//
// Created by Skalii Dmitrii on 19.04.2021.
// Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

@class OAPOIUIFilter;

@interface OARearrangeCustomFiltersViewController : OACompoundViewController

- (instancetype)initWithFilters:(NSArray<OAPOIUIFilter *> *)filters;

@end