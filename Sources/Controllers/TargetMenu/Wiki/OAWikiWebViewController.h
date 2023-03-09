//
//  OAWikiWebViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 04/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OABaseWebViewController.h"

@class OAPOI;

@interface OAWikiWebViewController : OABaseWebViewController

- (instancetype)initWithPoi:(OAPOI *)poi;

@end
