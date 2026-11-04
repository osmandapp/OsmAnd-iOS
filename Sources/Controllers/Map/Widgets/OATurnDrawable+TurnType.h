//
//  OATurnDrawable+TurnType.h
//  OsmAnd
//
//  Created by Max Kojin on 28/05/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OATurnDrawable.h"
#import "OATurnPathHelper.h"
#import <Foundation/Foundation.h>

@class OASTurnType;

@interface OATurnDrawable(TurnType)

- (OASTurnType *) turnType;
- (BOOL) setTurnType:(OASTurnType *)turnType;

@end
