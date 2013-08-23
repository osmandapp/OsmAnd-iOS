//
//  OAMapRendererController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/18/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAMapRendererViewController : UIViewController <UIGestureRecognizerDelegate>

- (void)activateMapnik;
- (void)activateCyclemap;
- (void)activateOffline;

@end
