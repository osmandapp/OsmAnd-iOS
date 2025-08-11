//
//  EOAEntityType.h
//  OsmAnd
//
//  Created by Max Kojin on 20/07/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, EOAEntityType)
{
    EOAEntityTypeUndefined = -1,
    EOAEntityTypeNode,
    EOAEntityTypeWay,
    EOAEntityTypeRelation,
    EOAEntityTypeWayBoundary
};

static NSString *kEntityTypeUndefined = @"UNDEFINED";
static NSString *kEntityTypeNode = @"NODE";
static NSString *kEntityTypeWay = @"WAY";
static NSString *kEntityTypeRelation = @"RELATION";
