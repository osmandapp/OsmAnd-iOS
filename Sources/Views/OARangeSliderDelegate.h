//
//  OARangeSliderDelegate.h
//  OsmAnd
//
//  Created by nnngrach on 14.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
@class OARangeSlider, UIPresentationController;

@protocol OARangeSliderDelegate <TTRangeSliderDelegate>

- (NSArray<__kindof UIGestureRecognizer *> *) getAllGestureRecognizers;

@end
