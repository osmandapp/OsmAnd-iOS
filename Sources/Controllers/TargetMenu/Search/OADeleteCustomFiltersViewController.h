//
//  OADeleteCustomFiltersViewController.h
//  OsmAnd
//
// Created by Skalii Dmitrii on 15.04.2021.
// Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABaseButtonsViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class OAPOIUIFilter;

@protocol OAPOIFiltersRemoveDelegate

@required

- (BOOL)removeFilters:(NSArray<OAPOIUIFilter *> *)filters;

@end

@interface OADeleteCustomFiltersViewController : OABaseButtonsViewController

@property(weak, nonatomic) id <OAPOIFiltersRemoveDelegate> delegate;

- (instancetype)initWithFilters:(NSArray<OAPOIUIFilter *> *)filters;

@end

NS_ASSUME_NONNULL_END
