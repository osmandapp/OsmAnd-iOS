//
//  NavigationController.h
//  OsmAnd
//
//  Created by egloff on 23/01/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "InterfaceController.h"

@interface NavigationController : WKInterfaceController {
    
    BOOL errorMessageShown;

}

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceTable *navigationTable;

@end
