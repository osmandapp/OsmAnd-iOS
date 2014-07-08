//
//  OAAddFavoriteViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/7/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#import <QuickDialogController.h>

@interface OAAddFavoriteViewController : QuickDialogController

- (instancetype)initWithLocation:(CLLocationCoordinate2D)location andTitle:(NSString*)title;

@end
