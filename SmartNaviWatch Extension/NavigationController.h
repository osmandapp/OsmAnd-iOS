//
//  NavigationController.h
//  OsmAnd
//
//  Created by egloff on 23/01/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//
/*!
 *  This controller class is responsible for the navigation representation.
 *  It shows a scrollable WKTableInterfaceTable. Each row’s size is as big as the watch screen.
 */
#import "InterfaceController.h"

@interface NavigationController : WKInterfaceController {
    
    BOOL errorMessageShown;
    BOOL tableViewInitialized;

}

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceTable *navigationTable;

@end
