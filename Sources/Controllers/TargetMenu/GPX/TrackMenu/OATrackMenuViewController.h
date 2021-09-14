//
//  OATrackMenuViewController.h
//  OsmAnd
//
//  Created by Skalii on 10.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OATargetMenuViewController.h"

@class OAGPX;
@class OATabBar;

@interface OATrackMenuViewController : OATargetMenuViewController

@property (weak, nonatomic) IBOutlet UINavigationBar *navBarView;
@property (weak, nonatomic) IBOutlet OATabBar *tabBarView;

- (instancetype)initWithGpx:(OAGPX *)gpx;

- (CGFloat)getHeaderHeight;

@end
