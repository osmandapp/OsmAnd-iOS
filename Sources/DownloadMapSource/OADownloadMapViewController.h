//
//  OADownloadMapViewController.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 18.05.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"
#import "OADownloadMapLayerHelper.h"

@interface OADownloadMapViewController : OATargetMenuViewController<UITableViewDataSource, UITableViewDelegate>

- (instancetype)initWithLayer:(EOADownloadMapLayer)layer;

@end
