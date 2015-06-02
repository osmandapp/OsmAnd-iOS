//
//  OAFavoriteViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 01/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"
#import "OAFavoriteItem.h"
#import <CoreLocation/CoreLocation.h>

typedef enum
{
    kFavoriteActionNone = 0,
    kFavoriteActionChangeColor = 1,
    kFavoriteActionChangeGroup = 2,
} EFavoriteAction;

@interface OAFavoriteViewController : OATargetMenuViewController<UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) OAFavoriteItem* favorite;
@property (assign, nonatomic) CLLocationCoordinate2D location;
@property (assign, nonatomic) BOOL newFavorite;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@property (nonatomic, readonly) BOOL editing;

- (id)initWithFavoriteItem:(OAFavoriteItem *)favorite;
- (id)initWithLocation:(CLLocationCoordinate2D)location andTitle:(NSString *)formattedLocation;

@end
