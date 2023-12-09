//
//  OAFavoriteImportViewController.h
//  OsmAnd
//
//  Created by Alexey on 2/6/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

FOUNDATION_EXPORT NSNotificationName _Nonnull const OAFavoriteImportViewControllerDidDismissNotification;

@interface OAFavoriteImportViewController : OABaseNavbarViewController

@property (nonatomic, readonly) BOOL handled;

- (instancetype)initFor:(NSURL*)url;

@end
