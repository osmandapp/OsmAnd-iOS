//
//  OADownloadMapProgressViewController.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 15.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

@interface OADownloadMapProgressViewController : OACompoundViewController

- (instancetype) initWithGeneralData:(NSInteger)numberOfTiles size:(CGFloat)downloadSize minZoom:(NSInteger)minZoom maxZoom:(NSInteger)maxZoom;

@end
