//
//  OAScrollView.h
//  OsmAnd
//
//  Created by Alexey Kulish on 23/02/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OAScrollViewDelegate

@required
- (void) onContentOffsetChanged:(CGPoint)contentOffset;
- (BOOL) isScrollAllowed;

@end

@interface OAScrollView : UIScrollView

@property (nonatomic, weak) id<OAScrollViewDelegate> oaDelegate;

- (BOOL) isSliding;

@end
