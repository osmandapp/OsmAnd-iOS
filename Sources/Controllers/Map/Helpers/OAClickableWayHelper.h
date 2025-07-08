//
//  OAClickableWayHelper.h
//  OsmAnd
//
//  Created by Max Kojin on 07/05/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@class ClickableWay, OARenderedObject, OAClickableWayMenuProvider;

@interface OAClickableWayHelper : NSObject

- (OAClickableWayMenuProvider *)getContextMenuProvider;

- (BOOL)isClickableWay:(OARenderedObject *)renderedObject;

@end


NS_ASSUME_NONNULL_END
