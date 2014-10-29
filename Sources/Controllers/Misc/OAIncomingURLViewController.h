//
//  OAIncomingURLViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/9/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <QuickDialogController.h>

@interface OAIncomingURLViewController : QuickDialogController<UIAlertViewDelegate>

@property NSMutableArray* ignoredNames;
@property NSString* conflictedName;

- (instancetype)initFor:(NSURL*)url;

@end
