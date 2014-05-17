//
//  OALocalResourceInformationViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/17/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <QuickDialogController.h>

@interface OALocalResourceInformationViewController : QuickDialogController

- (instancetype)initWithLocalResourceId:(NSString*)resourceId;

@property(nonatomic) NSString* resourceId;

@end
