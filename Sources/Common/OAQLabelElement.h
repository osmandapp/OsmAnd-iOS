//
//  OAQLabelElement.h
//  OsmAnd
//
//  Created by Feschenko Fedor on 7/29/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "QLabelElement.h"

@interface OAQLabelElement : QLabelElement

@property (nonatomic) UIView *accessoryView;
@property (nonatomic, getter = isAccessoryViewAllowed) BOOL accessoryViewAllowed;
@property (nonatomic) UIImage *accessoryViewImage;
@property (nonatomic) CGAffineTransform transform;

@end
