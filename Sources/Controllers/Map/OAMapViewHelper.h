//
//  OAMapViewHelper.h
//  OsmAnd Maps
//
//  Created by Paul on 12.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OAMapViewHelper : NSObject

+ (instancetype) sharedInstance;

- (CGFloat) getMapZoom;

- (void) goToLocation:(CLLocation *)position zoom:(CGFloat)zoom animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
