//
//  OAOsmUploadGPXViewConroller.h
//  OsmAnd
//
//  Created by nnngrach on 31.01.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseButtonsViewController.h"

@class OASGpxDataItem;

@interface OAOsmUploadGPXViewConroller : OABaseButtonsViewController

- (instancetype)initWithGPXItems:(NSArray<OASGpxDataItem *> *)gpxItemsToUpload;

@end
