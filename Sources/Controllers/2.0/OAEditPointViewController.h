//
//  OAEditPointViewController.h
//  OsmAnd
//
//  Created by nnngrach on 05.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseTableViewController.h"
#import <CoreLocation/CoreLocation.h>

@class OAFavoriteItem;

@interface OAEditPointViewController : OABaseTableViewController

@property (weak, nonatomic) IBOutlet UIImageView *headerIconPoi;
@property (weak, nonatomic) IBOutlet UIImageView *headerIconBackground;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *navBarHeightConstraint;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic, copy) NSString *address;
@property (nonatomic, assign) NSInteger savedColorIndex;
@property (nonatomic, copy) NSString *savedGroupName;
@property (nonatomic, copy) NSString *groupTitle;
@property (nonatomic, copy) UIColor *groupColor;

- (id) initWithItem:(OAFavoriteItem *)favorite;
- (id) initWithLocation:(CLLocationCoordinate2D)location title:(NSString*)title address:(NSString*)address;

@end
