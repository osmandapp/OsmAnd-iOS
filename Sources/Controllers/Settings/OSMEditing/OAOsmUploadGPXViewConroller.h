//
//  OAOsmUploadGPXViewConroller.h
//  OsmAnd
//
//  Created by nnngrach on 31.01.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseButtonsViewController.h"

@class OASTrackItem;

@interface OAOsmUploadGPXViewConroller : OABaseButtonsViewController

- (instancetype)initWithGPXItems:(NSArray<OASTrackItem *> *)gpxItemsToUpload;

@end
