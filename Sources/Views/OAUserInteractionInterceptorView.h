//
//  OAUserInteractionInterceptorView.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/29/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OAUserInteractionInterceptorProtocol.h"

@interface OAUserInteractionInterceptorView : UIView

@property id<OAUserInteractionInterceptorProtocol> delegate;

@end
