//
//  OAMapLayers.h
//  OsmAnd
//
//  Created by Alexey Kulish on 08/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAMapViewController;
@class OAFavoritesLayer, OADestinationsLayer;

@interface OAMapLayers : NSObject

@property (nonatomic, readonly) OAFavoritesLayer *favoritesLayer;
@property (nonatomic, readonly) OADestinationsLayer *destinationsLayer;

- (instancetype)initWithMapViewController:(OAMapViewController *)mapViewController;
- (void) createLayers;
- (void) destroyLayers;

- (void) showLayer:(NSString *)layerId;
- (void) hideLayer:(NSString *)layerId;

@end
