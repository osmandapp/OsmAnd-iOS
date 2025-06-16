//
//  OABaseLoadAsyncTask.mm
//  OsmAnd
//
//  Created by Max Kojin on 13/06/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OABaseLoadAsyncTask.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"

@implementation OABaseLoadAsyncTask

- (instancetype)init
{
    self = [super init];
    if (self) {
        _shouldShowProgress = YES;
    }
    return self;
}

// override
- (void)onPreExecute
{
    if (_shouldShowProgress)
        [[OARootViewController instance].view addSpinnerInCenterOfCurrentView:YES];
    [super onPreExecute];
}

// override
- (void)onPostExecute:(id)result
{
    if (_shouldShowProgress)
        [[OARootViewController instance].view removeSpinner];
    [super onPostExecute:result];
}

@end
