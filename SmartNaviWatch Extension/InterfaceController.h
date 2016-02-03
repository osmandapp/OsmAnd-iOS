//
//  InterfaceController.h
//  SmartNaviWatch Extension
//
//  Created by egloff on 16/12/15.
//  Copyright © 2015 OsmAnd. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface InterfaceController : WKInterfaceController {
    
    BOOL errorMessageShown;
    
}

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfacePicker *mapImages;

@end
