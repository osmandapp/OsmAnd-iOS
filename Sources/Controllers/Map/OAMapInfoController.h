//
//  OAMapInfoController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 08/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAMapHudViewController;

@interface OAMapInfoController : NSObject

- (instancetype) initWithHudViewController:(OAMapHudViewController *)mapHudViewController;

- (void) recreateControls;
- (void) expandClicked:(id)sender;

@end
