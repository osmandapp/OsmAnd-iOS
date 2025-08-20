//
//  OAPOIFilterViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 04/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

@class OAPOIUIFilter;

NS_ASSUME_NONNULL_BEGIN

@protocol OAPOIFilterViewDelegate

@required
- (BOOL)updateFilter:(OAPOIUIFilter *)filter nameFilter:(NSString *)nameFilter;
- (BOOL)removeFilter:(OAPOIUIFilter *)filter;
- (UIAlertController *)createSaveFilterDialog:(OAPOIUIFilter *)filter customSaveAction:(BOOL)customSaveAction;
- (void)searchByUIFilter:(OAPOIUIFilter *)filter newName:(NSString *)newName willSaved:(BOOL)willSave;

@end

@protocol OAPOIFilterRefreshDelegate

@required
- (void)refreshList;

@end

@interface OAPOIFilterViewController : OACompoundViewController

@property (weak, nonatomic, nullable) id<OAPOIFilterViewDelegate> delegate;

- (instancetype _Nullable)initWithFilter:(OAPOIUIFilter *)filter filterByName:(NSString * _Nullable)filterByName;

@end

NS_ASSUME_NONNULL_END
