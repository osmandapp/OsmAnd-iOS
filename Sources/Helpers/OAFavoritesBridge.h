//
//  OAFavoritesBridge.h
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 15.12.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAFavoritesBridge : NSObject

+ (BOOL)openFavouriteOrMoveMapWithLat:(double)lat lon:(double)lon zoom:(int)zoom name:(nullable NSString *)name;

@end
