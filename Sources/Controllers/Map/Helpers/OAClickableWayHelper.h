//
//  OAClickableWayHelper.h
//  OsmAnd
//
//  Created by Max Kojin on 07/05/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

//static const NSSet<NSString *> *CLICKABLE_TAGS;
//static const NSDictionary<NSString *, NSString *> *FORBIDDEN_TAGS;
//static const NSSet<NSString *> *REQUIRED_TAGS_ANY;

@class OAClickableWay, OARenderedObject;

@interface OAClickableWayHelper : NSObject

- (id) getContextMenuProvider;

- (BOOL) isClickableWay:(OARenderedObject *)renderedObject;

//- (OAClickableWay *) loadClickableWay:(CLLocation *)selectedLatLon renderedObject:(OARenderedObject *)renderedObject;

@end
