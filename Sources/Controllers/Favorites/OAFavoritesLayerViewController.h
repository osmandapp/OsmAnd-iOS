//
//  OAFavoritesLayerViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/14/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuickDialogController.h>
#import "TTTLocationFormatter.h"

/** Degrees to Radian **/
#define DegreesToRadians( degrees ) ( ( degrees ) / 180.0 * M_PI )
/** Radians to Degrees **/
#define RadiansToDegrees( radians ) ( ( radians ) * ( 180.0 / M_PI ) )

@interface OAFavoritesLayerViewController : QuickDialogController

- (instancetype)init;

@end
