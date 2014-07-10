//
//  OAEditFavoriteViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/10/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <QuickDialogController.h>

#include <OsmAndCore/IFavoriteLocation.h>

@interface OAEditFavoriteViewController : QuickDialogController

- (instancetype)initWithFavorite:(const std::shared_ptr< OsmAnd::IFavoriteLocation >&)favorite;

@end
