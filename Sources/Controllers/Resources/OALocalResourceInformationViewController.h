//
//  OALocalResourceInformationViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/17/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OASuperViewController.h"
#import "OAWorldRegion.h"

@interface OALocalResourceInformationViewController : OASuperViewController

@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSString *regionTitle;

- (void)initWithLocalResourceId:(NSString*)resourceId;
- (void)initWithLocalResourceId:(NSString*)resourceId
                              forRegion:(OAWorldRegion*)region;

@end
