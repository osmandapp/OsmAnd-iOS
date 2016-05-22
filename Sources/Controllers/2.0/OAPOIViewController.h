//
//  OAPoiViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 19/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"

@class OAPOI;

@interface OAPOIViewController : OATargetMenuViewController<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (id)initWithPOI:(OAPOI *)poi;

@end
