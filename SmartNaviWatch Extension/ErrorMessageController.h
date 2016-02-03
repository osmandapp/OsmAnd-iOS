//
//  ErrorMessageController.h
//  OsmAnd
//
//  Created by egloff on 31/01/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <WatchKit/WatchKit.h>

@interface ErrorMessageController : WKInterfaceController

@property (unsafe_unretained, nonatomic) IBOutlet WKInterfaceLabel *errorMessageLabel;

- (IBAction)dismissErrorMessageController;

@end
