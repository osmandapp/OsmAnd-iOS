//
//  OALoadGpxTask.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 31.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAGpxInfo.h"

@interface OALoadGpxTask : NSObject

- (void) execute:(void(^)(NSDictionary<NSString *, NSArray<OAGpxInfo *> *> *))onComplete;

@end
