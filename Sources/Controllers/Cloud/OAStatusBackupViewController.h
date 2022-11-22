//
//  OACloudRecentChangesViewController.h
//  OsmAnd
//
//  Created by Skalii on 16.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"
#import "OAStatusBackupTableViewController.h"

@interface OAStatusBackupViewController : OACompoundViewController

- (instancetype) initWithType:(EOARecentChangesType)type;

@end
