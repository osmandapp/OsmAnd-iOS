//
//  OATrackMenuDescriptionViewController.h
//  OsmAnd
//
//  Created by Skalii on 22.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

@class OAGPX, OAGPXDocument;

@interface OATrackMenuDescriptionViewController : OACompoundViewController

- (instancetype)initWithGpxDoc:(OAGPXDocument *)doc gpx:(OAGPX *)gpx;

@end
