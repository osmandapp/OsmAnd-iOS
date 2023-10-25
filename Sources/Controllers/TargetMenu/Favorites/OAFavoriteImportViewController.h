//
//  OAFavoriteImportViewController.h
//  OsmAnd
//
//  Created by Alexey on 2/6/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

@interface OAFavoriteImportViewController : OABaseNavbarViewController

@property (nonatomic, readonly) BOOL handled;

- (instancetype)initFor:(NSURL*)url;

@end
