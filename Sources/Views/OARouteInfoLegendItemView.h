//
//  OARouteInfoLegendView.h
//  OsmAnd
//
//  Created by Paul on 24.12.2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OARouteInfoLegendItemView : UIView

@property (nonatomic, getter=isSelected) BOOL selected;

- (instancetype) initWithTitle:(NSString *)title color:(UIColor *)color distance:(NSString *)distance;

@end

NS_ASSUME_NONNULL_END
