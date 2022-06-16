//
//  OATrackMenuAppearanceHudViewController.h
//  OsmAnd
//
//  Created by Skalii on 25.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OABaseTrackMenuHudViewController.h"

@class OATrackMenuViewControllerState;

@interface OATrackMenuAppearanceHudViewController : OABaseTrackMenuHudViewController

- (instancetype)initWithGpx:(OAGPX *)gpx state:(OATrackMenuViewControllerState *)state;

@end
