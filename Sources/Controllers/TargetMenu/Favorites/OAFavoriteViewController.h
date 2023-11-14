//
//  OAFavoriteViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 01/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OATargetInfoViewController.h"
#import "OAFavoriteItem.h"
#import <CoreLocation/CoreLocation.h>

@interface OAFavoriteViewController : OATargetInfoViewController

@property (nonatomic) OAFavoriteItem *favorite;

- (instancetype) initWithItem:(OAFavoriteItem *)favorite headerOnly:(BOOL)headerOnly;

- (NSString *) getItemName;
- (NSString *) getItemGroup;
- (NSString *) getItemDesc;
- (UIImage *) getIcon;
- (NSDate *) getTimestamp;

@end
