//
//  OAUninstallSpeedCamerasViewController.h
//  OsmAnd
//
//  Created by Skalii on 22.01.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseButtonsViewController.h"
\
@protocol OAUninstallSpeedCamerasDelegate <NSObject>

- (void)onUninstallSpeedCameras;

@end
@interface OAUninstallSpeedCamerasViewController : OABaseButtonsViewController

@property (nonatomic, weak) id<OAUninstallSpeedCamerasDelegate> delegate;

@end
