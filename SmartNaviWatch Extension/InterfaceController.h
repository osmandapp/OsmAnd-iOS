//
//  InterfaceController.h
//  SmartNaviWatch Extension
//
//  Created by egloff on 16/12/15.
//  Copyright © 2015 OsmAnd. All rights reserved.
//
/*!
 *  This controller class represents the initial interface, that is
 *  the one with the map renderings on it. It shows a WKInterfacePicker
 *  object which represents a scrolling list of images to choose from.
 */
#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface InterfaceController : WKInterfaceController {
    
    BOOL errorMessageShown;
    
}

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfacePicker *mapImages;

/*!
 *  sends a location request
 */
-(void)sendLocationRequest;

@end
