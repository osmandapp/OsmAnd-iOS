//
//  OATurnDrawable+cpp.h
//  OsmAnd
//
//  Created by Max Kojin on 28/05/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OATurnDrawable.h"
#import "OATurnPathHelper.h"
#import <Foundation/Foundation.h>

@interface OATurnDrawable(cpp)

- (std::shared_ptr<TurnType>) turnType;
- (BOOL) setTurnType:(std::shared_ptr<TurnType>)turnType;

@end
