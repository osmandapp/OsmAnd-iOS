//
//  UIMapRendererView.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/18/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIMapRendererView : UIView

@property (readonly) BOOL isRenderingSuspended;
- (BOOL)suspendRendering;
- (BOOL)resumeRendering;

@end
