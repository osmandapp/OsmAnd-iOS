//
//  OADownloadMapProgressViewController.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 15.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

@class OAResourceItem;

@interface OADownloadMapProgressViewController : OACompoundViewController

- (instancetype) initWithResource:(OAResourceItem *)item minZoom:(NSInteger)minZoom maxZoom:(NSInteger)maxZoom;

@end
