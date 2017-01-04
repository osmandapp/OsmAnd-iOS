//
//  OAPOIFilterViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 04/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"

@class OAPOIUIFilter;

@protocol OAPOIFilterViewDelegate

@required

- (BOOL) updateFilter;
- (BOOL) saveFilter;
- (BOOL) removeFilter;

@end

@interface OAPOIFilterViewController : OASuperViewController

@property (weak, nonatomic) id<OAPOIFilterViewDelegate> _Nullable delegate;

- (instancetype _Nullable)initWithFilter:( OAPOIUIFilter * _Nonnull)filter filterByName:(NSString * _Nullable)filterByName;

@end
