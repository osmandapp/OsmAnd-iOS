//
//  ErrorMessageController.m
//  OsmAnd
//
//  Created by egloff on 31/01/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "ErrorMessageController.h"

@implementation ErrorMessageController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    if (context != nil) {
        [self.errorMessageLabel setText:context];
    }
    
    
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    
}


- (IBAction)dismissErrorMessageController {
    
    [self dismissController];
}
@end
