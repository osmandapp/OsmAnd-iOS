//
//  OARangeSlider.h
//  OsmAnd
//
//  Created by nnngrach on 13.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "TTRangeSlider.h"
#import "OARangeSliderDelegate.h"


@interface OARangeSlider : TTRangeSlider

@property (nonatomic, weak) IBOutlet id<OARangeSliderDelegate> delegate;

@end
