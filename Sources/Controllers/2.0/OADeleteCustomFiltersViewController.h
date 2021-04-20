//
//  OADeleteCustomFiltersViewController.h
//  OsmAnd
//
// Created by Skalii Dmitrii on 15.04.2021.
// Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class OAPOIUIFilter;

@protocol OAPOIFiltersRemoveDelegate

@required

- (BOOL)removeFilters:(NSArray<OAPOIUIFilter *> *)filters;

@end

@interface OADeleteCustomFiltersViewController : OACompoundViewController

@property(weak, nonatomic) id <OAPOIFiltersRemoveDelegate> delegate;

- (instancetype)initWithFilters:(NSArray<OAPOIUIFilter *> *)filters;

@end

NS_ASSUME_NONNULL_END
