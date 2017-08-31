//
//  OADestinationsListDialogView.h
//  OsmAnd
//
//  Created by Alexey Kulish on 30/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OADestination;

@protocol OADestinationsListDialogDelegate <NSObject>

@required
- (void) onDestinationSelected:(OADestination *)destination;

@end

@interface OADestinationsListDialogView : UIView

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, weak) id<OADestinationsListDialogDelegate> delegate;

@end
