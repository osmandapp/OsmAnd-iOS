//
//  OAUserInteractionPassThroughView.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/21/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OAObservable;

@interface OAUserInteractionPassThroughView : UIView

@property (readonly) OAObservable* didLayoutObservable;

@end
