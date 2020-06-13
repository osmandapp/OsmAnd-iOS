//
//  OAMapOpacitySliderToggler.h
//  OsmAnd
//
//  Created by nnngrach on 12.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

@interface OAMapOpacitySliderToggler : NSObject

+ (OAMapOpacitySliderToggler *) sharedInstance;
- (BOOL)isOpacitySliderEnabled;
- (void)setIsOpacitySliderEnabled: (BOOL)isEnabled;
- (void)showOpacitySlider;

@end
