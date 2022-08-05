//
//  OACheckBackupSubscriptionTask.h
//  OsmAnd Maps
//
//  Created by Paul on 09.06.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OACheckBackupSubscriptionTask : NSObject

- (void) execute:(void(^)(BOOL))onComplete;

@end
