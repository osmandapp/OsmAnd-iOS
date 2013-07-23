//
//  OAMapRendererView.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/18/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#include <OsmAndCore.h>
#include <OsmAndCore/Map/IMapRenderer.h>

@interface OAMapRendererView : UIView

@property (readonly) OsmAnd::IMapRenderer* mapRenderer;

- (void)createContext;
- (void)releaseContext;

@property (readonly) BOOL isRenderingSuspended;
- (BOOL)suspendRendering;
- (BOOL)resumeRendering;

@end
