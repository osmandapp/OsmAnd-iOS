//
//  OACustomPOIViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 27/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

@class OAPOIUIFilter;
@protocol OAPOIFilterViewDelegate;
@protocol OAPOIFilterRefreshDelegate;

@interface OACustomPOIViewController : OACompoundViewController

@property (weak, nonatomic) id<OAPOIFilterViewDelegate> delegate;
@property (weak, nonatomic) id<OAPOIFilterRefreshDelegate> _Nullable refreshDelegate;

- (instancetype)initWithFilter:(OAPOIUIFilter *)filter;

+ (void)updateSearchView:(BOOL)searchMode search:(UITextField * _Nonnull)search cancel:(UIButton * _Nonnull)cancel rightConstraint:(NSLayoutConstraint * _Nonnull)rightConstraint;

@end
