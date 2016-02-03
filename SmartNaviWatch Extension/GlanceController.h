//
//  GlanceController.h
//  SmartNaviWatch Extension
//
//  Created by egloff on 16/12/15.
//  Copyright © 2015 OsmAnd. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface GlanceController : WKInterfaceController
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceImage *mapImage;
@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *locationTitle;

@end
