//
//  OAAsyncTask.mm
//  OsmAnd
//
//  Created by Max Kojin on 13/06/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OAAsyncTask.h"

@implementation OAAsyncTask

- (void) execute
{
    [self onPreExecute];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        id result = [self doInBackground];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self onPostExecute:result];
        });
    });
}

- (void) onPreExecute
{
    //override
}

- (id) doInBackground
{
    //override
    return nil;
}

- (void) onPostExecute:(id)result
{
    //override
}

@end
