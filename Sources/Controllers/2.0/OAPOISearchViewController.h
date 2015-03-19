//
//  OAPOISearchViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 19/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"
#import "OAAutoObserverProxy.h"

@interface OAPOISearchViewController : OASuperViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) OAAutoObserverProxy* locationServicesUpdateObserver;
@property CGFloat azimuthDirection;

@property NSTimeInterval lastUpdate;

- (instancetype)initWithSearchString:(NSString *)searchString;
- (instancetype)initWithType:(NSString *)poiTypeName;
- (instancetype)initWithCategory:(NSString *)categoryName;

@end
