//
//  OACloudRecentChangesTableViewController.m
//  OsmAnd Maps
//
//  Created by Skalii on 16.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAStatusBackupTableViewController.h"

@implementation OAStatusBackupTableViewController
{
    EOARecentChangesTable _tableType;
}

- (instancetype)initWithTableType:(EOARecentChangesTable)type
{
    self = [super init];
    if (self)
    {
        _tableType = type;
    }
    return self;
}

- (void)viewDidLoad
{
    [self generateData];
}

- (void)generateData
{
    
}

@end
