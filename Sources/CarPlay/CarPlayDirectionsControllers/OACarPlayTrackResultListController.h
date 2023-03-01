//
//  OACarPlayTrackResultListController.h
//  OsmAnd
//
//  Created by Skalii on 01.03.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseCarPlayListController.h"

@class OAGpxInfo;

@interface OACarPlayTrackResultListController : OABaseCarPlayListController

- (instancetype)initWithInterfaceController:(CPInterfaceController *)interfaceController
                                 folderName:(NSString *)folderName
                                    gpxList:(NSArray<OAGpxInfo *> *)gpxList;

@end
