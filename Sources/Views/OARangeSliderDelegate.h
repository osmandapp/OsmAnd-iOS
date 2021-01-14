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

@property (nullable, nonatomic,readonly) UIPresentationController *presentationController API_AVAILABLE(ios(8.0));

@end
