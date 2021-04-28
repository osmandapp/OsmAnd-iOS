//
//  OAPOIFilterViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 04/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

@class OAPOIUIFilter;
@protocol OACustomPOIViewDelegate;

@protocol OAPOIFilterViewDelegate

@required

- (BOOL)updateFilter:(OAPOIUIFilter *)filter nameFilter:(NSString *)nameFilter;
- (BOOL)saveFilter:(OAPOIUIFilter *)filter;
- (BOOL)removeFilter:(OAPOIUIFilter *)filter;

@end

@interface OAPOIFilterViewController : OACompoundViewController

@property (weak, nonatomic) id<OAPOIFilterViewDelegate> _Nullable delegate;
@property (weak, nonatomic) id<OACustomPOIViewDelegate> _Nullable customPOIDelegate;

- (instancetype _Nullable)initWithFilter:( OAPOIUIFilter * _Nonnull)filter filterByName:(NSString * _Nullable)filterByName;

@end
