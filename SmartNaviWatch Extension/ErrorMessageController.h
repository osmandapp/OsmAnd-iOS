//
//  ErrorMessageController.h
//  OsmAnd
//
//  Created by egloff on 31/01/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//
/*!
 *  This controller is presented modally allowing the user
 *  to inform about possible error messages.
 */
#import <WatchKit/WatchKit.h>

@interface ErrorMessageController : WKInterfaceController

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *errorMessageLabel;

/*!
 *  dismisses this controller
 */
- (IBAction)dismissErrorMessageController;

@end
