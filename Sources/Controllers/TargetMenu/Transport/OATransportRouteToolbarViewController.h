//
//  OATransportRouteToolbarViewController.h
//  OsmAnd
//
//  Created by Alexey on 29/07/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAToolbarViewController.h"

@class OATransportStopRoute, OATransportStop;

@interface OATransportRouteToolbarViewController : OAToolbarViewController

@property (nonatomic) OATransportStopRoute *transportRoute;
@property (nonatomic) OATransportStop *transportStop;

@property (weak, nonatomic) IBOutlet UIButton *titleButton;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;

@property (nonatomic) NSString *toolbarTitle;

@end
