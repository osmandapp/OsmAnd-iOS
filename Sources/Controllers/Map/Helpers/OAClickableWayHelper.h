//
//  OAClickableWayHelper.h
//  OsmAnd
//
//  Created by Max Kojin on 07/05/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAClickableWay, OARenderedObject;

@interface OAClickableWayHelper : NSObject

- (id) getContextMenuProvider;

- (BOOL) isClickableWay:(OARenderedObject *)renderedObject;

@end
