//
//  OATableViewCellWithSwitch.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/29/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OATableViewCell.h"

@protocol OATableViewWithSwitchDelegate <NSObject>

- (void)tableView:(UITableView *)tableView accessorySwitchChangedStateForRowWithIndexPath:(NSIndexPath *)indexPath;

@end

@interface OATableViewCellWithSwitch : OATableViewCell

@property(readonly) UISwitch* switchView;

@end
