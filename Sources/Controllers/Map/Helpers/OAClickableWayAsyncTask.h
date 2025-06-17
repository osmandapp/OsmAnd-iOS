//
//  OAClickableWayAsyncTask.h
//  OsmAnd
//
//  Created by Max Kojin on 13/06/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OABaseLoadAsyncTask.h"

@class OAClickableWay;

@interface OAClickableWayAsyncTask: OABaseLoadAsyncTask

- (instancetype)initWithClickableWay:(OAClickableWay *)clickableWay;

@end
