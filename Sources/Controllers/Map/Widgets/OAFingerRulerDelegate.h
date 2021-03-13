//
//  OAFingerRulerDelegate.h
//  OsmAnd
//
//  Created by Paul on 11/16/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OARulerByTapControlLayer.h"

NS_ASSUME_NONNULL_BEGIN

@interface OAFingerRulerDelegate : NSObject<CALayerDelegate>

@property (nonatomic, strong) OARulerByTapView *rulerByTapControl;

- (id)initWithRulerLayer:(OARulerByTapView *)rulerLayer;

@end

NS_ASSUME_NONNULL_END
